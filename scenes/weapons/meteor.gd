class_name Meteor
extends Node2D
## Огненный шар: метка на земле, падение по диагонали, взрыв по площади.

const FALL_TIME := 0.55
const BLAST_TIME := 0.35
## Откуда шар начинает падение относительно точки удара.
const START := Vector2(-50.0, -140.0)

var damage := 20.0
var radius := 30.0
var source: StringName
## Больше нуля — после взрыва остаётся горящая лужа.
var burn_dps := 0.0
var burn_time := 0.0

var _time := 0.0
var _exploded := false
var _ball: AnimatedSprite2D


func _ready() -> void:
	_ball = AnimatedSprite2D.new()
	_ball.sprite_frames = SpriteFrames.new()
	_ball.sprite_frames.add_frame(&"default", SpriteLib.pack("projectiles/meteor"))
	# Шар метеора нарисован летящим влево-вниз (хвост вправо-вверх) — доворачиваем до направления падения.
	_ball.rotation = (-START).angle() - 3.0 * PI / 4.0
	_ball.scale = Vector2.ONE * 1.3
	_ball.position = START
	add_child(_ball)


func _process(delta: float) -> void:
	_time += delta
	if not _exploded:
		_ball.position = START * (1.0 - minf(_time / FALL_TIME, 1.0))
	if not _exploded and _time >= FALL_TIME:
		_explode()
	if _exploded and _time >= FALL_TIME + BLAST_TIME:
		queue_free()
	queue_redraw()


func _explode() -> void:
	_exploded = true
	_ball.hide()
	Sfx.play(&"meteor")
	SpriteFx.spawn(get_parent(), global_position, "effects/explosion", 15.0, radius * 2.0)
	for enemy in Enemy.in_radius(get_tree(), global_position, radius):
		enemy.take_damage(damage, global_position.direction_to(enemy.center()), source)
	if burn_dps > 0.0:
		var patch := BurnPatch.new()
		patch.position = position
		patch.radius = radius
		patch.dps = burn_dps
		patch.duration = burn_time
		patch.source = source
		get_parent().add_child(patch)


func _draw() -> void:
	if not _exploded:
		var progress := _time / FALL_TIME
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.3, 0.1, 0.08 + 0.15 * progress))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.45, 0.15, 0.7), 1.0)
