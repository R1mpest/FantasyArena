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
var _victory := false
var _victory_wait := 0.0
var _bosses_killed: PackedStringArray = []


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
		player.hp = player.max_hp
	_last_hp = player.hp
	_peak_enemies = maxi(_peak_enemies, get_tree().get_node_count_in_group(&"enemies"))
	_peak_ranged = maxi(_peak_ranged, get_tree().get_node_count_in_group(&"ranged"))
	for id in [&"goblin", &"skelet", &"ogre", &"orc_shaman"]:
		_peak_by_type[id] = maxi(_peak_by_type.get(id, 0), get_tree().get_node_count_in_group(StringName("enemy_" + id)))
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


func _pick(options: Array[CardOffer]) -> int:
	if _prefer_weapons:
		for i in options.size():
			if options[i].kind == CardOffer.Kind.WEAPON:
				return i
	return randi() % options.size()


func _steer() -> void:
	var direction := Vector2.from_angle(GameState.elapsed * 0.5)
	for pair in [[&"move_right", direction.x], [&"move_left", -direction.x], [&"move_down", direction.y], [&"move_up", -direction.y]]:
		if pair[1] > 0.0:
			Input.action_press(pair[0], pair[1])
		else:
			Input.action_release(pair[0])


func _finish() -> void:
	set_process(false)
	var player: Player = _run.player
	print("AUTOPLAY время=%s жив=%s уровень=%d убито=%d hp=%.0f/%.0f врагов_пик=%d стрелков_пик=%d выборов=%d кадр_мс_ср=%.2f кадр_мс_макс=%.1f" % [
		GameState.format_time(), not player.dead, GameState.level, GameState.kills,
		player.hp, player.max_hp, _peak_enemies, _peak_ranged, _picks, _frame_ms_sum / maxi(_frames, 1), _frame_ms_max])
	print("AUTOPLAY получено_урона=%.0f" % _damage_taken)
	print("AUTOPLAY победа=%s боссы=%s" % [_victory, ", ".join(_bosses_killed)])
	var alive := {}
	for id in _peak_by_type:
		alive[id] = get_tree().get_node_count_in_group(StringName("enemy_" + id))
	print("AUTOPLAY пик_по_типам=", _peak_by_type, " живы_в_конце=", alive)
	var build := PackedStringArray()
	for weapon: Weapon in player.weapons.values():
		build.append("%s %d" % [weapon.data.id, weapon.level])
	for id in player.items:
		build.append("%s %d" % [id, player.items[id]])
	for id in player.perks:
		build.append("%s %d" % [id, player.perks[id].level])
	print("AUTOPLAY билд=", ", ".join(build))
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
