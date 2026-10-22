class_name LightningFx
extends Node2D
## Короткая вспышка молнии ломаной линией между двумя точками.

const DURATION := 0.15

var from := Vector2.ZERO
var to := Vector2.ZERO

var _time := 0.0
var _points := PackedVector2Array()


func _ready() -> void:
	z_index = 2
	var segments := 6
	for i in segments + 1:
		var point := from.lerp(to, float(i) / segments)
		if i > 0 and i < segments:
			point += (to - from).orthogonal().normalized() * randf_range(-5.0, 5.0)
		_points.append(point)


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 - _time / DURATION
	draw_polyline(_points, Color(0.6, 0.85, 1.0, alpha * 0.5), 3.0)
	draw_polyline(_points, Color(0.95, 1.0, 1.0, alpha), 1.0)
