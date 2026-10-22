class_name BurnPatch
extends Node2D
## Горящая лужа на месте падения огненного шара: жжёт врагов внутри, пока не погаснет.

const TICK := 0.5

var radius := 30.0
var dps := 12.0
var duration := 3.0
var source: StringName

var _time := 0.0
var _timer := 0.0


func _ready() -> void:
	z_index = -1


func _process(delta: float) -> void:
	_time += delta
	_timer -= delta
	if _timer <= 0.0:
		_timer = TICK
		for enemy in Enemy.in_radius(get_tree(), global_position, radius):
			enemy.take_damage(dps * TICK, Vector2.ZERO, source)
	if _time >= duration:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - _time / duration
	var flicker := 0.85 + 0.15 * sin(_time * 18.0)
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.4, 0.1, 0.18 * fade * flicker))
	draw_circle(Vector2.ZERO, radius * 0.6, Color(1.0, 0.7, 0.2, 0.15 * fade))
