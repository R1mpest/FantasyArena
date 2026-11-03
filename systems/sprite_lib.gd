class_name SpriteLib
extends RefCounted
## Сборка анимаций из покадровых PNG пака 0x72 (имя_f0.png, имя_f1.png, ...).

const FRAMES_DIR := "res://assets/sprites/0x72/frames/"

static var _cache: Dictionary = {}


## anims: {&"idle": "wizzard_m_idle_anim", &"run": "wizzard_m_run_anim"}
static func frames(anims: Dictionary, fps: float = 8.0) -> SpriteFrames:
	var key := "%s@%s" % [anims, fps]
	if _cache.has(key):
		return _cache[key]
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation(&"default")
	for anim_name: StringName in anims:
		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, fps)
		var i := 0
		while ResourceLoader.exists(_frame_path(anims[anim_name], i)):
			sprite_frames.add_frame(anim_name, load(_frame_path(anims[anim_name], i)))
			i += 1
		if i == 0:
			push_error("Нет кадров для анимации %s" % anims[anim_name])
	_cache[key] = sprite_frames
	return sprite_frames


## Спрайт, у которого точка (0, 0) приходится на ноги персонажа.
static func make_sprite(anims: Dictionary, fps: float = 8.0) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames(anims, fps)
	var first: StringName = anims.keys()[0]
	var size := sprite.sprite_frames.get_frame_texture(first, 0).get_size()
	sprite.offset = Vector2(0, -size.y / 2.0)
	sprite.play(first)
	return sprite


## Анимация из горизонтальной полосы кадров (пак заклинаний: кадры квадратные, по высоте полосы).
static func strip(path: String, fps: float = 12.0) -> SpriteFrames:
	var key := "strip:" + path
	if _cache.has(key):
		return _cache[key]
	var sheet: Texture2D = load(path)
	var size := int(sheet.get_height())
	var sprite_frames := SpriteFrames.new()
	sprite_frames.set_animation_speed(&"default", fps)
	for i in int(sheet.get_width() / size):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(i * size, 0, size, size)
		sprite_frames.add_frame(&"default", frame)
	_cache[key] = sprite_frames
	return sprite_frames


static func strip_sprite(path: String, fps: float = 12.0) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = strip(path, fps)
	sprite.play(&"default")
	return sprite


const PACK_DIR := "res://assets/sprites/fantasy_arena/"


## Спрайт из пака Fantasy Arena по пути внутри пака (например, "pickups/heal_plus").
## Текстура держится в кэше: если её рисуют через draw_texture и нигде не хранят,
## Godot освобождает её сразу после отрисовки, и вместо картинки остаётся белый квадрат.
static func pack(name: String) -> Texture2D:
	var key := "tex:" + name
	if not _cache.has(key):
		_cache[key] = load(PACK_DIR + name + ".png")
	return _cache[key]


## Анимация из кадров пака Fantasy Arena: name_f0.png, name_f1.png, ...
static func pack_frames(name: String, fps: float, loop: bool = true) -> SpriteFrames:
	var key := "pack:%s@%s" % [name, fps]
	if _cache.has(key):
		return _cache[key]
	var sprite_frames := SpriteFrames.new()
	sprite_frames.set_animation_speed(&"default", fps)
	sprite_frames.set_animation_loop(&"default", loop)
	var i := 0
	while ResourceLoader.exists("%s%s_f%d.png" % [PACK_DIR, name, i]):
		sprite_frames.add_frame(&"default", load("%s%s_f%d.png" % [PACK_DIR, name, i]))
		i += 1
	_cache[key] = sprite_frames
	return sprite_frames


static func pack_sprite(name: String, fps: float, loop: bool = true) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = pack_frames(name, fps, loop)
	sprite.play(&"default")
	return sprite


static func texture(name: String) -> Texture2D:
	return load(FRAMES_DIR + name + ".png")


static func _frame_path(base: String, index: int) -> String:
	return "%s%s_f%d.png" % [FRAMES_DIR, base, index]
