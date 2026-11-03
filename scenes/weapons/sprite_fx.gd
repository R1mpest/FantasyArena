class_name SpriteFx
extends AnimatedSprite2D
## Одноразовая анимация из пака (взрыв, искра, кольцо мороза): проигрывается и удаляется.

## Сильнее пиксель-арт не растягиваем, иначе пиксели становятся кубами.
const MAX_SCALE := 2.5


static func spawn(parent: Node, at: Vector2, name: String, fps: float, size: float = 0.0) -> SpriteFx:
	var fx := SpriteFx.new()
	fx.sprite_frames = SpriteLib.pack_frames(name, fps, false)
	fx.position = at
	fx.z_index = 2
	if size > 0.0:
		var frame_size := fx.sprite_frames.get_frame_texture(&"default", 0).get_size().x
		fx.scale = Vector2.ONE * minf(size / frame_size, MAX_SCALE)
	parent.add_child(fx)
	return fx


func _ready() -> void:
	animation_finished.connect(queue_free)
	play(&"default")
