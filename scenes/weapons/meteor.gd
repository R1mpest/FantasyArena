class_name Meteor
extends Node2D
## Огненный шар: метка на земле, падение по диагонали, взрыв по площади.

const FALL_TIME := 0.55
const BLAST_TIME := 0.35
## Откуда шар начинает падение относительно точки удара.
const START := Vector2(-50.0, -140.0)

var damage := 20.0
var radius := 30.0

var _time := 0.0
var _exploded := false


func _process(delta: float) -> void:
	_time += delta
	if not _exploded and _time >= FALL_TIME:
		_explode()
	if _exploded and _time >= FALL_TIME + BLAST_TIME:
		queue_free()
	queue_redraw()


func _explode() -> void:
	_exploded = true
	for enemy in Enemy.in_radius(get_tree(), global_position, radius):
		enemy.take_damage(damage, global_position.direction_to(enemy.center()))


func _draw() -> void:
	if not _exploded:
		var progress := _time / FALL_TIME
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.3, 0.1, 0.08 + 0.15 * progress))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.45, 0.15, 0.7), 1.0)
		var ball := START * (1.0 - progress)
		draw_line(ball, ball + START.normalized() * 16.0, Color(1.0, 0.55, 0.15, 0.5), 4.0)
		draw_circle(ball, 6.0, Color(1.0, 0.4, 0.1))
		draw_circle(ball, 3.5, Color(1.0, 0.9, 0.5))
	else:
		var progress := (_time - FALL_TIME) / BLAST_TIME
		draw_circle(Vector2.ZERO, radius * (0.6 + 0.4 * progress), Color(1.0, 0.5, 0.15, 0.6 * (1.0 - progress)))
		draw_arc(Vector2.ZERO, radius * (0.8 + 0.3 * progress), 0.0, TAU, 40, Color(1.0, 0.85, 0.4, 1.0 - progress), 2.0)
