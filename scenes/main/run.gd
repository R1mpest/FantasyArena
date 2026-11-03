extends Node2D
## Сцена забега: создаёт игрока, игровые системы и интерфейс.

var player: Player
var experience: Experience
var upgrade_system: UpgradeSystem
var level_up_panel: LevelUpPanel

var arena: ArenaBuilder
## Сколько ещё ликует публика после убитого босса.
var _cheer_left := 0.0


func _ready() -> void:
	InputSetup.ensure()
	RenderingServer.set_default_clear_color(Color("1b1520"))
	GameState.reset()
	Stats.begin_run()
	Music.play(&"battle")
	arena = ArenaBuilder.new()
	add_child(arena)

	var pickups := _add_layer("Pickups")
	var entities := _add_layer("Entities")
	entities.y_sort_enabled = true
	var projectiles := _add_layer("Projectiles")

	player = Player.new()
	player.projectile_root = projectiles
	player.arena = arena
	entities.add_child(player)
	var limits := arena.camera_limits()
	player.camera.limit_left = limits.position.x
	player.camera.limit_top = limits.position.y
	player.camera.limit_right = limits.end.x
	player.camera.limit_bottom = limits.end.y

	experience = Experience.new()
	experience.pickups_root = pickups
	experience.player = player
	add_child(experience)

	var spawner := EnemySpawner.new()
	spawner.player = player
	spawner.enemies_root = entities
	spawner.arena = arena
	add_child(spawner)

	var events := ArenaEvents.new()
	events.spawner = spawner
	events.arena = arena
	events.player = player
	add_child(events)

	upgrade_system = UpgradeSystem.new()
	upgrade_system.player = player
	upgrade_system.experience = experience
	add_child(upgrade_system)

	var hud := Hud.new()
	hud.player = player
	hud.experience = experience
	add_child(hud)

	level_up_panel = LevelUpPanel.new()
	level_up_panel.upgrade_system = upgrade_system
	add_child(level_up_panel)

	var overlay := Overlay.new()
	overlay.upgrade_system = upgrade_system
	add_child(overlay)
	if TouchControls.wanted():
		add_child(TouchControls.new())
	SaveManager.settings_changed.connect(_update_cursor)
	_update_cursor()
	_warm_up_shaders(entities)
	_connect_arena_events()


func _process(delta: float) -> void:
	if _cheer_left > 0.0:
		_cheer_left -= delta
		if _cheer_left <= 0.0:
			arena.set_cheering(false)
			arena.emperor_gesture(&"idle")


## Арена реагирует на боссов: главные ворота открываются заранее, император
## показывает жест, после победы над боссом публика ликует.
func _connect_arena_events() -> void:
	EventBus.boss_incoming.connect(func(_title: String) -> void:
		arena.gates[0].open()
		arena.emperor_gesture(&"down"))
	EventBus.boss_defeated.connect(func(_boss: Node2D, _final: bool) -> void:
		arena.set_cheering(true)
		arena.emperor_gesture(&"up")
		arena.herald_salute()
		_cheer_left = 5.0)
	EventBus.victory.connect(func() -> void:
		arena.set_cheering(true)
		arena.emperor_gesture(&"up")
		# На победу легат снимает шлем.
		arena.herald_salute(false)
		_cheer_left = 0.0)


## Шейдер контура элиты компилируется при первой отрисовке — это давало рывок кадра
## на сотни миллисекунд. Рисуем его один раз в начале забега почти прозрачным спрайтом.
func _warm_up_shaders(parent: Node2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = SpriteLib.texture("skull")
	sprite.material = Enemy.outline_material()
	sprite.self_modulate.a = 0.01
	sprite.position = player.position
	parent.add_child(sprite)
	get_tree().create_timer(0.5).timeout.connect(sprite.queue_free)


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	# Забег брошен (меню, «Заново» на паузе) — время и убийства всё равно идут в статистику.
	Stats.abandon_run()


## В режиме прицеливания мышью курсор — перекрестие.
func _update_cursor() -> void:
	var mouse := SaveManager.aim_mode == SaveManager.AimMode.MOUSE
	Input.set_default_cursor_shape(Input.CURSOR_CROSS if mouse else Input.CURSOR_ARROW)


func _add_layer(layer_name: String) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	add_child(layer)
	return layer
