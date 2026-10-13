class_name Player
extends CharacterBody2D
## Игрок: движение, здоровье и статы, которые качаются улучшениями.

# Все статы float, чтобы любое улучшение применялось одной формулой.
var max_hp := 100.0
var hp := 100.0
var move_speed := 85.0
var regen := 0.0
var pickup_radius := 48.0
## Общий множитель урона всего оружия.
var might := 1.0
var damage := 14.0
var fire_interval := 0.7
var projectile_speed := 260.0
var projectile_count := 1.0
var pierce := 0.0
var attack_range := 200.0

## Куда оружие добавляет снаряды.
var projectile_root: Node
## id оружия -> узел Weapon (стартовый снаряд сюда не входит).
var weapons: Dictionary = {}
var dead := false

var _sprite: AnimatedSprite2D
var _hurtbox: Area2D
var _hit_flash := 0.0


func _ready() -> void:
	add_to_group(&"player")
	collision_layer = 1
	collision_mask = 0
	motion_mode = MOTION_MODE_FLOATING

	_sprite = SpriteLib.make_sprite({&"idle": "wizzard_m_idle_anim", &"run": "wizzard_m_run_anim"})
	add_child(_sprite)
	add_child(_circle_shape(CollisionShape2D.new(), 4.0, Vector2(0, -4)))

	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = 2
	_hurtbox.monitorable = false
	_hurtbox.add_child(_circle_shape(CollisionShape2D.new(), 7.0, Vector2(0, -9)))
	add_child(_hurtbox)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	add_child(camera)

	var weapon := AutoWeapon.new()
	weapon.player = self
	weapon.position = Vector2(0, -12)
	add_child(weapon)


func _physics_process(delta: float) -> void:
	if dead:
		return
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = direction * move_speed
	move_and_slide()
	if direction.x != 0.0:
		_sprite.flip_h = direction.x < 0.0
	_sprite.play(&"run" if direction != Vector2.ZERO else &"idle")

	hp = minf(hp + regen * delta, max_hp)
	_take_contact_damage(delta)


## Разовый урон (снаряд врага).
func take_damage(amount: float) -> void:
	if dead:
		return
	hp -= amount
	_hit_flash = 0.15
	if hp <= 0.0:
		_die()


func heal(amount: float) -> void:
	hp = minf(hp + amount, max_hp)


func has_weapon(id: StringName) -> bool:
	return weapons.has(id)


func add_weapon(id: StringName) -> void:
	if has_weapon(id):
		return
	var weapon: Weapon
	match id:
		&"orbs":
			weapon = OrbitWeapon.new()
		&"meteor":
			weapon = MeteorWeapon.new()
		&"aura":
			weapon = AuraWeapon.new()
		_:
			push_error("Неизвестное оружие: %s" % id)
			return
	weapon.player = self
	weapon.position = Vector2(0, -10)
	weapons[id] = weapon
	add_child(weapon)


func apply_upgrade(upgrade: UpgradeData) -> void:
	upgrade.apply_to(self)
	if upgrade.stat == &"max_hp":
		hp += upgrade.amount


func _take_contact_damage(delta: float) -> void:
	var dps := 0.0
	for body in _hurtbox.get_overlapping_bodies():
		var enemy := body as Enemy
		if enemy != null and not enemy.dead:
			dps += enemy.contact_dps
	_hit_flash = maxf(0.0, _hit_flash - delta)
	_sprite.modulate = Color(1, 0.45, 0.45) if dps > 0.0 or _hit_flash > 0.0 else Color.WHITE
	if dps <= 0.0:
		return
	hp -= dps * delta
	if hp <= 0.0:
		_die()


func _die() -> void:
	hp = 0.0
	dead = true
	_sprite.stop()
	_sprite.modulate = Color(0.45, 0.45, 0.45)
	_sprite.rotation_degrees = 90.0
	EventBus.player_died.emit()


static func _circle_shape(node: CollisionShape2D, radius: float, at: Vector2) -> CollisionShape2D:
	var circle := CircleShape2D.new()
	circle.radius = radius
	node.shape = circle
	node.position = at
	return node
