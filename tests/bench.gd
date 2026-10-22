extends Node
## Замер производительности (требование Н1): на арене всё время держится N врагов,
## у героя всё оружие, герой бессмертен и бегает по кругу.
## godot --headless --fixed-fps 60 --path . res://tests/bench.tscn -- --enemies=300 --seconds=20

var _run: Node2D
var _target := 300
var _seconds := 20.0
var _screenshot := ""
var _spawner: EnemySpawner
var _frame_ms: PackedFloat32Array = []
var _process_ms: PackedFloat32Array = []
var _physics_ms: PackedFloat32Array = []
var _last_usec := 0
var _time := 0.0
var _spawned_last := 0
var _levelups := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed(7)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--enemies="):
			_target = int(arg.get_slice("=", 1))
		elif arg.begins_with("--screenshot="):
			_screenshot = arg.get_slice("=", 1)
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.get_slice("=", 1))
	SaveManager.aim_mode = SaveManager.AimMode.AUTO
	_run = load("res://scenes/main/run.tscn").instantiate()
	add_child(_run)
	_spawner = _run.find_children("*", "EnemySpawner", true, false)[0]
	_spawner.set_process(false)
	for id in ["orbs", "meteor", "aura", "magic_bolt", "magic_bolt", "quiver"]:
		_run.upgrade_system.give(StringName(id))


func _process(delta: float) -> void:
	var panel: LevelUpPanel = _run.level_up_panel
	if panel.is_open():
		if panel.choose(0):
			_levelups += 1
		_last_usec = 0
		return
	var player: Player = _run.player
	player.hp = player.max_hp
	var direction := Vector2.from_angle(_time * 0.5)
	Input.action_press(&"move_right", maxf(direction.x, 0.0))
	Input.action_press(&"move_left", maxf(-direction.x, 0.0))
	Input.action_press(&"move_down", maxf(direction.y, 0.0))
	Input.action_press(&"move_up", maxf(-direction.y, 0.0))

	var missing := _target - get_tree().get_node_count_in_group(&"enemies")
	var spawned := 0
	for i in mini(missing, 40):
		_spawner._spawn(_spawner._pick_type(6.0), 6.0)
		spawned += 1

	_time += delta
	var now := Time.get_ticks_usec()
	if _time > 3.0 and _last_usec > 0:
		var ms := (now - _last_usec) / 1000.0
		if ms > 30.0:
			print("BENCH медленный кадр %.0f мс на %.2f с: заспавнено в прошлом кадре=%d, выборов карт=%d, кристаллов=%d" % [
				ms, _time, _spawned_last, _levelups, _run.find_children("*", "XpGem", true, false).size()])
		_frame_ms.append(ms)
		_process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		_physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	_last_usec = now
	_spawned_last = spawned
	if _time >= _seconds:
		_report()


func _report() -> void:
	set_process(false)
	var gems := _run.find_children("*", "XpGem", true, false).size()
	print("BENCH врагов=%d кристаллов=%d кадров=%d" % [get_tree().get_node_count_in_group(&"enemies"), gems, _frame_ms.size()])
	print("BENCH кадр мс: %s" % _stats(_frame_ms))
	print("BENCH process мс: %s" % _stats(_process_ms))
	print("BENCH physics мс: %s" % _stats(_physics_ms))
	if _screenshot != "":
		get_tree().paused = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_screenshot)
	get_tree().quit()


static func _stats(values: PackedFloat32Array) -> String:
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for v in sorted:
		total += v
	var p95 := sorted[int(sorted.size() * 0.95)]
	var p99 := sorted[int(sorted.size() * 0.99)]
	return "ср=%.2f p95=%.2f p99=%.2f макс=%.1f" % [total / sorted.size(), p95, p99, sorted[-1]]
