class_name Blast
extends Node2D
## Короткий взрыв по площади: бьёт всех врагов в радиусе в момент появления.

const DURATION := 0.3

var damage := 10.0
var radius := 24.0
var color := Color(0.75, 0.55, 1.0)
var source: StringName

var _time := 0.0


func _ready() -> void:
	z_index = 1
	if damage <= 0.0:
		return
	for enemy in Enemy.in_radius(get_tree(), global_position, radius):
		enemy.take_damage(damage, global_position.direction_to(enemy.center()), source)


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var progress := _time / DURATION
	draw_circle(Vector2.ZERO, radius * (0.5 + 0.5 * progress), Color(color, 0.45 * (1.0 - progress)))
	draw_arc(Vector2.ZERO, radius * (0.7 + 0.3 * progress), 0.0, TAU, 32, Color(color.lightened(0.4), 1.0 - progress), 1.5)
