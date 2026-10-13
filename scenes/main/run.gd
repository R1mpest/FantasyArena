extends Node2D
## Сцена забега: создаёт игрока, игровые системы и интерфейс.

var player: Player
var experience: Experience
var upgrade_system: UpgradeSystem
var level_up_panel: LevelUpPanel

var _floor: Sprite2D


func _ready() -> void:
	InputSetup.ensure()
	RenderingServer.set_default_clear_color(Color("1b1520"))
	GameState.reset()
	_floor = FloorBuilder.build()
	add_child(_floor)

	var pickups := _add_layer("Pickups")
	var entities := _add_layer("Entities")
	entities.y_sort_enabled = true
	var projectiles := _add_layer("Projectiles")

	player = Player.new()
	player.projectile_root = projectiles
	entities.add_child(player)

	experience = Experience.new()
	experience.pickups_root = pickups
	add_child(experience)

	var spawner := EnemySpawner.new()
	spawner.player = player
	spawner.enemies_root = entities
	add_child(spawner)

	upgrade_system = UpgradeSystem.new()
	upgrade_system.player = player
	add_child(upgrade_system)

	var hud := Hud.new()
	hud.player = player
	hud.experience = experience
	hud.upgrade_system = upgrade_system
	add_child(hud)

	level_up_panel = LevelUpPanel.new()
	level_up_panel.upgrade_system = upgrade_system
	add_child(level_up_panel)

	add_child(Overlay.new())


func _process(_delta: float) -> void:
	# Пол — бесконечная плитка: прыгает за игроком на целый период узора.
	_floor.position = (player.global_position / FloorBuilder.PERIOD).floor() * FloorBuilder.PERIOD


func _add_layer(layer_name: String) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	add_child(layer)
	return layer
