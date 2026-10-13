extends Node
## Автопрогон забега без игрока: бегает по кругу и берёт случайные улучшения.
## godot --headless --fixed-fps 60 --path . res://tests/autoplay.tscn -- --seconds=180
## Ключ --screenshot=путь.png сохраняет кадр в конце (нужен экран, не headless),
## с --levelup-shot кадр снимается при первом окне выбора улучшения.

var _run: Node2D
var _seconds := 120.0
var _screenshot := ""
var _levelup_shot := false
var _picks := 0
var _frame_ms_max := 0.0
var _frame_ms_sum := 0.0
var _frames := 0
var _last_usec := 0
var _peak_enemies := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			_seconds = float(arg.get_slice("=", 1))
		elif arg.begins_with("--screenshot="):
			_screenshot = arg.get_slice("=", 1)
		elif arg == "--levelup-shot":
			_levelup_shot = true
	_run = load("res://scenes/main/run.tscn").instantiate()
	add_child(_run)


func _process(_delta: float) -> void:
	var panel: LevelUpPanel = _run.level_up_panel
	if panel.is_open() and _levelup_shot:
		_finish()
		return
	if panel.is_open():
		panel.choose(randi() % panel.option_count())
		_picks += 1
		return
	_steer()
	_peak_enemies = maxi(_peak_enemies, get_tree().get_node_count_in_group(&"enemies"))
	var now := Time.get_ticks_usec()
	if _last_usec > 0 and GameState.elapsed > 5.0:
		var ms := (now - _last_usec) / 1000.0
		_frame_ms_max = maxf(_frame_ms_max, ms)
		_frame_ms_sum += ms
		_frames += 1
	_last_usec = now
	if GameState.elapsed >= _seconds or not GameState.running:
		_finish()


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
	print("AUTOPLAY время=%s жив=%s уровень=%d убито=%d hp=%.0f/%.0f врагов_пик=%d выборов=%d кадр_мс_ср=%.2f кадр_мс_макс=%.1f" % [
		GameState.format_time(), not player.dead, GameState.level, GameState.kills,
		player.hp, player.max_hp, _peak_enemies, _picks, _frame_ms_sum / maxi(_frames, 1), _frame_ms_max])
	print("AUTOPLAY улучшения=", _run.upgrade_system.levels)
	if _screenshot != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_screenshot)
		print("AUTOPLAY скриншот=", _screenshot)
	get_tree().quit()
