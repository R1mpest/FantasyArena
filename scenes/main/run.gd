extends Node2D
## Сцена забега: создаёт игрока, игровые системы и интерфейс.

const FLOOR_TILE := 16
const FLOOR_TILES := 32
const FLOOR_PERIOD := float(FLOOR_TILE * FLOOR_TILES)

var player: Player
var experience: Experience
var upgrade_system: UpgradeSystem
var level_up_panel: LevelUpPanel

var _floor: Sprite2D


func _ready() -> void:
	InputSetup.ensure()
	RenderingServer.set_default_clear_color(Color("1b1520"))
	GameState.reset()
	_build_floor()

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
	_floor.position = (player.global_position / FLOOR_PERIOD).floor() * FLOOR_PERIOD


func _add_layer(layer_name: String) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	add_child(layer)
	return layer


## Склеивает случайные плитки пола 0x72 в одну текстуру и повторяет её.
func _build_floor() -> void:
	_floor = Sprite2D.new()
	_floor.z_index = -10
	_floor.modulate = Color(0.7, 0.7, 0.75)
	_floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_floor.region_enabled = true
	_floor.region_rect = Rect2(0, 0, FLOOR_PERIOD * 4, FLOOR_PERIOD * 4)
	add_child(_floor)

	var tiles: Array[Image] = []
	for i in range(1, 9):
		var image := SpriteLib.texture("floor_%d" % i).get_image()
		if image == null or image.is_empty():
			break
		image.convert(Image.FORMAT_RGBA8)
		tiles.append(image)
	if tiles.size() < 8:
		# Без рендера (headless) картинку текстуры не достать — хватит одной плитки.
		_floor.texture = SpriteLib.texture("floor_1")
		return

	var atlas := Image.create(FLOOR_TILE * FLOOR_TILES, FLOOR_TILE * FLOOR_TILES, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 72
	for y in FLOOR_TILES:
		for x in FLOOR_TILES:
			var index := 0 if rng.randf() < 0.75 else rng.randi_range(1, 7)
			atlas.blit_rect(tiles[index], Rect2i(0, 0, FLOOR_TILE, FLOOR_TILE), Vector2i(x, y) * FLOOR_TILE)
	_floor.texture = ImageTexture.create_from_image(atlas)
