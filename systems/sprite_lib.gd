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


static func texture(name: String) -> Texture2D:
	return load(FRAMES_DIR + name + ".png")


static func _frame_path(base: String, index: int) -> String:
	return "%s%s_f%d.png" % [FRAMES_DIR, base, index]
