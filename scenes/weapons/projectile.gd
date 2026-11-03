class_name Projectile
extends Area2D
## Снаряд: летит по прямой, бьёт врагов, пока не кончится пробитие.

var velocity := Vector2.ZERO
var damage := 10.0
## Сколько ещё врагов снаряд пробьёт насквозь.
var pierce := 0
var lifetime := 1.0
## Больше нуля — снаряд «Резонанса»: при первом попадании взрывается с этим радиусом.
var blast_radius := 0.0
## id оружия, выпустившего снаряд.
var source: StringName

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
	add_child(SpriteLib.pack_sprite("projectiles/magic_bolt", 8.0))
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	# Снаряд, который взорвётся (5-й уровень), подсвечен.
	if blast_radius > 0.0:
		draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.6, 1.0, 0.45))


func _on_body_entered(body: Node2D) -> void:
	var enemy := body as Enemy
	if _spent or enemy == null or enemy.dead:
		return
	enemy.take_damage(damage, velocity.normalized(), source)
	SpriteFx.spawn.call_deferred(get_parent(), global_position, "effects/hit_spark", 20.0)
	if blast_radius > 0.0:
		var blast := Blast.new()
		blast.damage = damage
		blast.source = source
		blast.radius = blast_radius
		blast.position = enemy.center()
		get_parent().add_child.call_deferred(blast)
		blast_radius = 0.0
		queue_redraw()
	pierce -= 1
	if pierce < 0:
		_spent = true
		queue_free()
