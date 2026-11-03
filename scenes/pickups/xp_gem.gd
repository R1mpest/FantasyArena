class_name XpGem
extends Node2D
## Кристалл опыта: лежит, пока игрок не окажется в радиусе сбора, затем летит к нему.

var value := 1

var _player: Player
var _attracted := false
var _speed := 0.0


func _ready() -> void:
	add_to_group(&"xp_gems")
	_player = get_tree().get_first_node_in_group(&"player") as Player


## Летит к герою, где бы ни лежал (кристалл-магнит).
func attract() -> void:
	_attracted = true
	_speed = maxf(_speed, 250.0)


func _process(delta: float) -> void:
	if _player == null or _player.dead:
		return
	var target := _player.global_position + Vector2(0, -8)
	if not _attracted and global_position.distance_to(target) <= _player.pickup_radius:
		_attracted = true
	if not _attracted:
		return
	_speed = minf(_speed + 500.0 * delta, 450.0)
	global_position = global_position.move_toward(target, _speed * delta)
	if global_position.distance_to(target) < 4.0:
		EventBus.xp_collected.emit(value)
		queue_free()


## Номиналы по README пака: 1–4 синий, 5–19 зелёный, 20–99 золотой, 100+ красный.
static func texture_for(amount: int) -> Texture2D:
	if amount >= 100:
		return SpriteLib.pack("pickups/xp_gem_4_red")
	if amount >= 20:
		return SpriteLib.pack("pickups/xp_gem_3_gold")
	if amount >= 5:
		return SpriteLib.pack("pickups/xp_gem_2_green")
	return SpriteLib.pack("pickups/xp_gem_1_blue")


func _draw() -> void:
	draw_texture(texture_for(value), Vector2(-4, -4))

