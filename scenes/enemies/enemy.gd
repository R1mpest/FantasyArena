class_name Enemy
extends CharacterBody2D
## Враг: идёт к игроку, наносит урон касанием, при смерти шлёт enemy_died.

const KNOCKBACK := 70.0

var data: EnemyData
## Множитель сложности k(t) на момент появления.
var k := 1.0
var target: Node2D
## Если враг отстал дальше этого расстояния, он переносится ближе к игроку.
var respawn_radius := 400.0

var hp := 1.0
var contact_dps := 0.0
var dead := false

var _sprite: AnimatedSprite2D
var _knockback := Vector2.ZERO
var _flash_time := 0.0


func _ready() -> void:
	add_to_group(&"enemies")
	collision_layer = 2
	collision_mask = 2
	motion_mode = MOTION_MODE_FLOATING
	hp = data.max_hp * k
	contact_dps = data.contact_dps * k

	_sprite = SpriteLib.make_sprite({&"run": data.anim_run})
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = data.radius
	shape.shape = circle
	shape.position = Vector2(0, -data.radius)
	add_child(shape)


func _physics_process(delta: float) -> void:
	var to_target := target.global_position - global_position
	if to_target.length_squared() > respawn_radius * respawn_radius * 2.25:
		global_position = target.global_position + Vector2.from_angle(randf() * TAU) * respawn_radius
		return
	var direction := to_target.normalized()
	velocity = direction * data.speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 400.0 * delta)
	move_and_slide()
	_sprite.flip_h = direction.x < 0.0

	if _flash_time > 0.0:
		_flash_time -= delta
		if _flash_time <= 0.0:
			_sprite.modulate = Color.WHITE


func take_damage(amount: float, from_direction: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	hp -= amount
	_knockback = from_direction * KNOCKBACK
	_flash_time = 0.08
	_sprite.modulate = Color(1, 0.35, 0.35)
	if hp <= 0.0:
		dead = true
		EventBus.enemy_died.emit(global_position, data.xp)
		queue_free()
