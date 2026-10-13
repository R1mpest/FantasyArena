class_name FloorBuilder
extends RefCounted
## Бесконечный пол: случайные плитки 0x72 склеиваются в одну текстуру, она повторяется.

const TILE := 16
const TILES := 32
const PERIOD := float(TILE * TILES)


static func build() -> Sprite2D:
	var floor_sprite := Sprite2D.new()
	floor_sprite.z_index = -10
	floor_sprite.modulate = Color(0.7, 0.7, 0.75)
	floor_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_sprite.region_enabled = true
	floor_sprite.region_rect = Rect2(0, 0, PERIOD * 4, PERIOD * 4)

	var tiles: Array[Image] = []
	for i in range(1, 9):
		var image := SpriteLib.texture("floor_%d" % i).get_image()
		if image == null or image.is_empty():
			break
		image.convert(Image.FORMAT_RGBA8)
		tiles.append(image)
	if tiles.size() < 8:
		# Без рендера (headless) картинку текстуры не достать — хватит одной плитки.
		floor_sprite.texture = SpriteLib.texture("floor_1")
		return floor_sprite

	var atlas := Image.create(TILE * TILES, TILE * TILES, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 72
	for y in TILES:
		for x in TILES:
			var index := 0 if rng.randf() < 0.75 else rng.randi_range(1, 7)
			atlas.blit_rect(tiles[index], Rect2i(0, 0, TILE, TILE), Vector2i(x, y) * TILE)
	floor_sprite.texture = ImageTexture.create_from_image(atlas)
	return floor_sprite
