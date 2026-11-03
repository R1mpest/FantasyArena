extends Node
## Автопрогон забега без игрока: бегает по кругу и берёт случайные улучшения.
## godot --headless --fixed-fps 60 --path . res://tests/autoplay.tscn -- --seconds=180
## Ключ --screenshot=путь.png сохраняет кадр в конце (нужен экран, не headless),
## с --levelup-shot кадр снимается при первом окне выбора карт.
## Ключ --give=orbs,meteor,power,power выдаёт оружие, предметы и навыки на старте (повтор id — ещё уровень).
## Ключ --seed=N — фиксированный сид случайностей для сравнения прогонов.
## Ключ --pause-shot — в конце открыть паузу (для скриншота), --upgrades-shot — паузу → «Улучшения».
## Ключ --mouse-aim — прицеливание «по мыши» (курсор стоит на месте).
## Ключ --god — герой не умирает (для проверки поздней игры).
## Ключ --small-window — окно 640×360 в углу экрана вместо сохранённого режима (для снимков).
## Ключ --touch — включить сенсорное управление (джойстик и кнопку паузы) на компьютере.
## Ключ --overlay=victory|dead — в конце показать экран победы или поражения, --touch-demo — оба
## сенсорных джойстика (вместе с --touch). Окно для снимков: --small-window=1280x720.
## Ключ --weapons — всегда брать оружие и его прокачку, если они есть среди карт.

var _run: Node2D
var _seconds := 120.0
var _screenshot := ""
var _levelup_shot := false
var _prefer_weapons := false
var _shot_wait := 0.0
var _give: PackedStringArray = []
var _god := false
var _pause_shot := false
var _damage_taken := 0.0
var _last_hp := -1.0
var _picks := 0
var _frame_ms_max := 0.0
var _frame_ms_sum := 0.0
var _frames := 0
var _last_usec := 0
var _peak_enemies := 0
var _peak_ranged := 0
var _peak_by_type: Dictionary = {}
var _violations: Dictionary = {}
## Насколько сильнее всего превышался лимит минуты (враги, оставшиеся с прошлой минуты, — норма).
var _over_minute_limit := 0
var _victory := false
var _victory_wait := 0.0
var _bosses_killed: PackedStringArray = []
## Время жизни врага под огнём: от первого попадания до смерти (без боссов).
## id экземпляра -> [здоровье при появлении, время первого попадания или -1].
var _tracked: Dictionary = {}
## Минута забега -> [сумма секунд, убито, убито с одного кадра].
var _ttk: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			_seconds = float(arg.get_slice("=", 1))
		elif arg.begins_with("--screenshot="):
			_screenshot = arg.get_slice("=", 1)
		elif arg.begins_with("--give="):
			_give = arg.get_slice("=", 1).split(",")
		elif arg.begins_with("--seed="):
			seed(int(arg.get_slice("=", 1)))
		elif arg == "--pause-shot" or arg == "--upgrades-shot":
			_pause_shot = true
		elif arg == "--god":
			_god = true
		elif arg == "--weapons":
			_prefer_weapons = true
		elif arg == "--levelup-shot":
			_levelup_shot = true
	SaveManager.aim_mode = SaveManager.AimMode.MOUSE if "--mouse-aim" in OS.get_cmdline_user_args() else SaveManager.AimMode.AUTO
	EventBus.victory.connect(func() -> void: _victory = true)
	EventBus.boss_defeated.connect(func(boss: Node2D, _final: bool) -> void:
		_bosses_killed.append("%s на %s" % [(boss as Enemy).data.id, GameState.format_time()]))
	_run = load("res://scenes/main/run.tscn").instantiate()
	add_child(_run)
	for id in _give:
		if not _run.upgrade_system.give(StringName(id)):
			push_error("Нечего выдать по --give: %s" % id)


func _process(delta: float) -> void:
	var panel: LevelUpPanel = _run.level_up_panel
	if panel.is_open() and _levelup_shot:
		_shot_wait += delta
		var frame := int(_shot_wait * 60.0)
		if frame in [1, 10, 30, 50]:
			get_viewport().get_texture().get_image().save_png(_screenshot.replace(".png", "_%d.png" % frame))
			print("DBG frame ", frame, " dim_alpha=", panel._dim.modulate.a, " cards_scale=", panel._cards[0].scale)
		if _shot_wait > 0.9:
			_finish()
		return
	if panel.is_open():
		if panel.choose(_pick(panel.options())):
			_picks += 1
		_last_usec = 0
		return
	_steer()
	var player: Player = _run.player
	if _last_hp >= 0.0 and player.hp < _last_hp:
		_damage_taken += _last_hp - player.hp
	if _god:
		# Неуязвимость, а не только лечение: за один кадр урон может превысить всё здоровье.
		player.invulnerable_until = INF
		player.hp = player.max_hp
	_last_hp = player.hp
	_peak_enemies = maxi(_peak_enemies, get_tree().get_node_count_in_group(&"enemies"))
	_peak_ranged = maxi(_peak_ranged, get_tree().get_node_count_in_group(&"ranged"))
	_check_limits()
	_track_ttk()
	var now := Time.get_ticks_usec()
	if _last_usec > 0 and GameState.elapsed > 5.0:
		var ms := (now - _last_usec) / 1000.0
		if ms > 100.0:
			print("AUTOPLAY медленный кадр %.0f мс на %s: врагов=%d боссов=%d снарядов=%d" % [ms, GameState.format_time(),
				get_tree().get_node_count_in_group(&"enemies"), get_tree().get_node_count_in_group(&"bosses"), _run.player.projectile_root.get_child_count()])
		_frame_ms_max = maxf(_frame_ms_max, ms)
		_frame_ms_sum += ms
		_frames += 1
	_last_usec = now
	if _victory:
		# Даём экрану победы появиться (он открывается с задержкой).
		_victory_wait += delta
		if _victory_wait > 2.0:
			_finish()
		return
	if GameState.elapsed >= _seconds or not GameState.running:
		_finish()


## Пики по всем типам врагов и нарушения лимитов: тип сверх max_alive, всего больше 300,
## всего больше лимита минуты (без учёта призыва боссов — он под лимит минуты не попадает).
func _check_limits() -> void:
	var spawner: EnemySpawner = _run.find_children("*", "EnemySpawner", true, false)[0]
	for id in spawner._types:
		var type: EnemyData = spawner._types[id]
		var alive := get_tree().get_node_count_in_group(StringName("enemy_" + id))
		_peak_by_type[id] = maxi(_peak_by_type.get(id, 0), alive)
		if type.max_alive > 0 and alive > type.max_alive:
			_violations["%s > %d" % [id, type.max_alive]] = true
	var total := get_tree().get_node_count_in_group(&"enemies")
	if total > EnemySpawner.MAX_ENEMIES:
		_violations["всего %d > %d" % [total, EnemySpawner.MAX_ENEMIES]] = true
	var limit := int(spawner.table.segment_at(GameState.minutes())["limit"])
	if get_tree().get_node_count_in_group(&"bosses") == 0 and total > limit:
		_over_minute_limit = maxi(_over_minute_limit, total - limit)


func _track_ttk() -> void:
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.data.is_boss:
			continue
		var id := enemy.get_instance_id()
		if not _tracked.has(id):
			_tracked[id] = [enemy.hp, -1.0]
			enemy.tree_exiting.connect(_on_enemy_gone.bind(enemy, id))
		elif _tracked[id][1] < 0.0 and enemy.hp < _tracked[id][0]:
			_tracked[id][1] = GameState.elapsed


func _on_enemy_gone(enemy: Enemy, id: int) -> void:
	var entry: Array = _tracked[id]
	_tracked.erase(id)
	if enemy.hp > 0.0:
		return
	var minute := int(GameState.minutes())
	var bucket: Array = _ttk.get(minute, [0.0, 0, 0])
	if entry[1] < 0.0:
		bucket[2] += 1
	else:
		bucket[0] += GameState.elapsed - entry[1]
	bucket[1] += 1
	_ttk[minute] = bucket


func _pick(options: Array[CardOffer]) -> int:
	if _prefer_weapons:
		for i in options.size():
			if options[i].kind == CardOffer.Kind.WEAPON:
				return i
	return randi() % options.size()


## Бег по кругу радиусом 170 вокруг центра поля: направление — к точке на окружности.
## Раньше задавалось только вращающееся направление, и из-за мёртвой зоны кнопок (0,2)
## путь дрейфовал; на арене автопилот уползал в угол.
func _steer() -> void:
	var player: Player = _run.player
	var goal := Vector2.from_angle(GameState.elapsed * 0.5) * 170.0
	var direction := player.global_position.direction_to(goal)
	# Нужное направление раскладываем так, чтобы обе оси были выше мёртвой зоны.
	direction = direction / maxf(absf(direction.x), absf(direction.y))
	for pair in [[&"move_right", direction.x], [&"move_left", -direction.x], [&"move_down", direction.y], [&"move_up", -direction.y]]:
		if pair[1] > 0.0:
			Input.action_press(pair[0], pair[1])
		else:
			Input.action_release(pair[0])


## Оба сенсорных джойстика на снимке: палец слева сдвинут вправо-вверх, справа — прицел вниз-влево.
func _touch_demo() -> void:
	var controls: TouchControls = _run.find_children("*", "TouchControls", true, false)[0]
	SaveManager.aim_mode = SaveManager.AimMode.MOUSE
	var size := get_viewport().get_visible_rect().size
	for finger in [[0, Vector2(0.18, 0.72), Vector2(16, -12)], [1, Vector2(0.8, 0.62), Vector2(-14, 14)]]:
		var touch := InputEventScreenTouch.new()
		touch.index = finger[0]
		touch.pressed = true
		touch.position = size * finger[1]
		controls._input(touch)
		var drag := InputEventScreenDrag.new()
		drag.index = finger[0]
		drag.position = touch.position + finger[2]
		controls._input(drag)


func _finish() -> void:
	set_process(false)
	var player: Player = _run.player
	print("AUTOPLAY время=%s жив=%s уровень=%d убито=%d hp=%.0f/%.0f врагов_пик=%d стрелков_пик=%d выборов=%d кадр_мс_ср=%.2f кадр_мс_макс=%.1f" % [
		GameState.format_time(), not player.dead, GameState.level, GameState.kills,
		player.hp, player.max_hp, _peak_enemies, _peak_ranged, _picks, _frame_ms_sum / maxi(_frames, 1), _frame_ms_max])
	print("AUTOPLAY получено_урона=%.0f" % _damage_taken)
	print("AUTOPLAY победа=%s боссы=%s" % [_victory, ", ".join(_bosses_killed)])
	print("AUTOPLAY пик_по_типам=", _peak_by_type)
	var ttk := PackedStringArray()
	for minute in _ttk.keys():
		var b: Array = _ttk[minute]
		ttk.append("%d: %.2fс (%d%% с одного кадра)" % [minute, b[0] / maxi(b[1], 1), 100 * b[2] / maxi(b[1], 1)])
	print("AUTOPLAY время_убийства по минутам: ", "; ".join(ttk))
	print("AUTOPLAY лимиты: %s; превышение лимита минуты до %d" % ["нарушений нет" if _violations.is_empty() else ", ".join(_violations.keys()), _over_minute_limit])
	var build := PackedStringArray()
	for weapon: Weapon in player.weapons.values():
		build.append("%s %d" % [weapon.data.id, weapon.level])
	for id in player.items:
		build.append("%s %d" % [id, player.items[id]])
	for id in player.perks:
		build.append("%s %d" % [id, player.perks[id].level])
	print("AUTOPLAY билд=", ", ".join(build))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--overlay="):
			# Экран итогов без самого финала: --overlay=victory или --overlay=dead.
			var shown: Overlay = _run.find_children("*", "Overlay", true, false)[0]
			shown._show(Overlay.Mode.VICTORY if arg.ends_with("victory") else Overlay.Mode.DEAD)
			await get_tree().process_frame
	if "--touch-demo" in OS.get_cmdline_user_args():
		_touch_demo()
		await get_tree().process_frame
	if _pause_shot:
		var overlay: Overlay = _run.find_children("*", "Overlay", true, false)[0]
		overlay._show(Overlay.Mode.PAUSE)
		if "--upgrades-shot" in OS.get_cmdline_user_args():
			overlay._show_upgrades()
		await get_tree().process_frame
	if _screenshot != "":
		get_tree().paused = true
		_run.level_up_panel.hide()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_screenshot)
		print("AUTOPLAY скриншот=", _screenshot)
	get_tree().quit()
