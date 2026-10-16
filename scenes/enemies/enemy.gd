class_name Enemy
extends CharacterBody2D
## Враг: идёт к игроку, наносит урон касанием, при смерти шлёт enemy_died.
## Стрелок (data.attack_range > 0) держит дистанцию и кидает медленные снаряды.

const KNOCKBACK := 70.0
## Скорость, с которой соседи расталкивают врагов.
const SEPARATION_SPEED := 70.0
## Расталкивание пересчитывается раз в столько физических кадров (у врагов вразнобой).
const SEPARATION_EVERY := 5

var data: EnemyData
## Множитель сложности k(t) на момент появления.
var k := 1.0
var target: Node2D
## Если враг отстал дальше этого расстояния, он переносится ближе к игроку.
var respawn_radius := 400.0
## Сетка для расталкивания; без неё враги проходят друг сквозь друга.
var grid: EnemyGrid

var hp := 1.0
var contact_dps := 0.0
var dead := false

var _sprite: AnimatedSprite2D
var _knockback := Vector2.ZERO
var _flash_time := 0.0
var _shot_cooldown := 0.0
var _strafe_sign := 1.0
var _separation := Vector2.ZERO
var _frame := 0


func _ready() -> void:
	add_to_group(&"enemies")
	add_to_group(StringName("enemy_" + data.id))
	if is_ranged():
		add_to_group(&"ranged")
		_shot_cooldown = randf_range(1.0, data.shot_interval)
		_strafe_sign = 1.0 if randf() < 0.5 else -1.0
	# Слой нужен, чтобы враг попадал в снаряды и хитбокс игрока. Друг с другом враги
	# физически не сталкиваются — их расталкивает EnemyGrid.
	collision_layer = 2
	collision_mask = 0
	_frame = randi() % SEPARATION_EVERY
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
	var move := direction
	if is_ranged():
		move = _ranged_move(direction, to_target.length())
		_try_shoot(delta, to_target.length())
	_frame += 1
	if grid != null and _frame % SEPARATION_EVERY == 0:
		_separation = grid.separation(self)
	velocity = move * data.speed + _separation * SEPARATION_SPEED + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 400.0 * delta)
	global_position += velocity * delta
	_sprite.flip_h = direction.x < 0.0

	if _flash_time > 0.0:
		_flash_time -= delta
		if _flash_time <= 0.0:
			_sprite.modulate = Color.WHITE


func is_ranged() -> bool:
	return data.attack_range > 0.0


## Подходит до дистанции стрельбы, отступает, если игрок слишком близко, иначе обходит его по кругу.
func _ranged_move(direction: Vector2, distance: float) -> Vector2:
	if distance > data.attack_range:
		return direction
	if distance < data.attack_range * 0.65:
		return -direction
	return direction.orthogonal() * _strafe_sign * 0.5


func _try_shoot(delta: float, distance: float) -> void:
	_shot_cooldown -= delta
	if _shot_cooldown > 0.0 or distance > data.attack_range * 1.15:
		return
	_shot_cooldown = data.shot_interval
	var shot := EnemyProjectile.new()
	shot.position = center()
	shot.velocity = center().direction_to(target.global_position + Vector2(0, -10)) * data.shot_speed
	shot.damage = data.shot_damage * k
	get_parent().add_child(shot)


## Толчок (например, от разрушенного мана-щита).
func push(impulse: Vector2) -> void:
	_knockback = impulse


## Центр тела врага (позиция узла — это его ноги).
func center() -> Vector2:
	return global_position + Vector2(0, -data.radius)


## Живые враги, чьё тело задевает круг center/radius.
static func in_radius(tree: SceneTree, at: Vector2, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node in tree.get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		var reach := radius + enemy.data.radius
		if not enemy.dead and enemy.center().distance_squared_to(at) <= reach * reach:
			result.append(enemy)
	return result


func take_damage(amount: float, from_direction: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	hp -= amount
	_knockback = from_direction * KNOCKBACK
	_flash_time = 0.08
	_sprite.modulate = Color(1, 0.35, 0.35)
	if hp <= 0.0:
		dead = true
		EventBus.enemy_died.emit(global_position, Formulas.xp_drop(data.xp, GameState.minutes()))
		queue_free()
