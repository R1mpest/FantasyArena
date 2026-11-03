class_name ArenaGate
extends Node2D
## Ворота арены: решётка поднимается и опускается, при открытии на песок падает свет.
## Спавнер берёт spawn_point и direction и выпускает монстров отсюда.

signal opened
signal closed

## Точка появления монстров (глобальные координаты, уже на песке).
var spawn_point := Vector2.ZERO
## Куда монстры идут из ворот.
var direction := Vector2.DOWN
## Главные ворота — для боссов.
var is_main := false

var _sprite: AnimatedSprite2D
var _glow: Sprite2D
var _frames := 0
var _open := false


func setup(strip: Texture2D, frame_size: Vector2i, frames: int, glow: Texture2D, flip_h: bool = false) -> void:
	_frames = frames
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation(&"lift")
	sprite_frames.set_animation_loop(&"lift", false)
	sprite_frames.set_animation_speed(&"lift", 10.0)
	for i in frames:
		var frame := AtlasTexture.new()
		frame.atlas = strip
		frame.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		sprite_frames.add_frame(&"lift", frame)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = sprite_frames
	_sprite.animation = &"lift"
	_sprite.centered = false
	_sprite.flip_h = flip_h
	_sprite.frame = 0
	_sprite.animation_finished.connect(_on_animation_finished)
	add_child(_sprite)

	_glow = Sprite2D.new()
	_glow.texture = glow
	_glow.visible = false
	_glow.z_index = 1
	add_child(_glow)


func place_glow() -> void:
	_glow.global_position = spawn_point - direction * 6.0
	# свет под воротами, но над песком
	_glow.z_as_relative = false
	_glow.z_index = -9


func is_open() -> bool:
	return _open


func open() -> void:
	if _open:
		return
	_open = true
	_sprite.play(&"lift")


func close() -> void:
	if not _open:
		return
	_open = false
	_glow.visible = false
	_sprite.play_backwards(&"lift")


## Сразу открыть без анимации (для мокапов и загрузки сохранения).
func open_instant() -> void:
	_open = true
	_sprite.frame = _frames - 1
	_glow.visible = true


func _on_animation_finished() -> void:
	if _open:
		_glow.visible = true
		opened.emit()
	else:
		closed.emit()
