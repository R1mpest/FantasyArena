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


func _draw() -> void:
	var color := Color(0.35, 0.65, 1.0)
	if value >= 5:
		color = Color(1.0, 0.35, 0.4)
	elif value >= 2:
		color = Color(0.4, 0.95, 0.5)
	var points := PackedVector2Array([Vector2(0, -4), Vector2(3, 0), Vector2(0, 4), Vector2(-3, 0)])
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, color.darkened(0.5), 1.0)
