class_name EnemyProjectile
extends Area2D
## Снаряд врага: медленно летит по прямой, бьёт игрока один раз.

const LIFETIME := 3.5

var velocity := Vector2.ZERO
var damage := 8.0

var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	z_index = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.5
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_time += delta
	if _time >= LIFETIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + 0.15 * sin(_time * 14.0)
	draw_circle(Vector2.ZERO, 6.0 * pulse, Color(0.5, 1.0, 0.3, 0.25))
	draw_circle(Vector2.ZERO, 3.5, Color(0.45, 0.95, 0.3))
	draw_circle(Vector2.ZERO, 1.8, Color(0.9, 1.0, 0.8))


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or player.dead:
		return
	player.take_damage(damage)
	queue_free()
