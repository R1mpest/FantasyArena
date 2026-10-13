class_name Projectile
extends Area2D
## Снаряд: летит по прямой, бьёт врагов, пока не кончится пробитие.

var velocity := Vector2.ZERO
var damage := 10.0
## Сколько ещё врагов снаряд пробьёт насквозь.
var pierce := 0
var lifetime := 1.0

var _spent := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)
	rotation = velocity.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2(-3, 0), 2.0, Color(0.45, 0.7, 1.0, 0.35))
	draw_circle(Vector2.ZERO, 3.5, Color(0.45, 0.75, 1.0, 0.55))
	draw_circle(Vector2.ZERO, 2.0, Color(0.9, 0.97, 1.0))


func _on_body_entered(body: Node2D) -> void:
	var enemy := body as Enemy
	if _spent or enemy == null or enemy.dead:
		return
	enemy.take_damage(damage, velocity.normalized())
	pierce -= 1
	if pierce < 0:
		_spent = true
		queue_free()
