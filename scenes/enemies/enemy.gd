class_name Enemy
extends CharacterBody2D
## Враг: идёт к игроку, наносит урон касанием, при смерти шлёт enemy_died.
## Элитный — крупнее, сильнее, с золотым контуром. Взрывной подбегает и взрывается.
## Стрелок (data.attack_range > 0) держит дистанцию и кидает медленные снаряды.

const KNOCKBACK := 70.0
## Скорость, с которой соседи расталкивают врагов.
const SEPARATION_SPEED := 70.0
## Расталкивание пересчитывается раз в столько физических кадров (у врагов вразнобой).
const SEPARATION_EVERY := 5
## «Арканная метка»: сколько разных видов оружия за какое время её вешают и сколько она держится.
const MARK_SOURCES := 3
const MARK_WINDOW := 2.0
const MARK_TIME := 4.0
const MARK_SPREAD_RADIUS := 40.0
const ELITE_HP := 3.0
const ELITE_DAMAGE := 1.25
const ELITE_SPEED := 1.1
const ELITE_SCALE := 1.3
const ELITE_XP := 5
const FUSE_TIME := 0.6
const OUTLINE := preload("res://assets/shaders/outline.gdshader")

static var _outline_material: ShaderMaterial

var data: EnemyData
## Множитель сложности k(t) на момент появления.
var k := 1.0
var target: Node2D
## Элитная версия: задаёт спавнер до добавления в сцену.
var elite := false
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
## Замедление: доля снижения скорости и сколько оно ещё длится.
var _slow := 0.0
var _slow_time := 0.0
## id оружия -> время последнего попадания им (для метки).
var _hits: Dictionary = {}
var _marked_until := 0.0
var _head_y := -16.0
var _frozen_time := 0.0
## Проклятие (Проклятый череп): прибавка к получаемому урону, до какого времени и урон взрыва при смерти.
var _curse_bonus := 0.0
var _curse_until := 0.0
var _curse_blast := 0.0
var _curse_blast_radius := 0.0
var _speed_mult := 1.0
## Взрывной враг: сколько осталось до взрыва (меньше нуля — фитиль не горит).
var _fuse := -1.0


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
	contact_dps = data.contact_dps

	_sprite = SpriteLib.make_sprite({&"run": data.anim_run})
	add_child(_sprite)
	_head_y = -_sprite.sprite_frames.get_frame_texture(&"run", 0).get_size().y - 4.0
	if elite:
		_make_elite()
	set_process(elite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = data.radius
	shape.shape = circle
	shape.position = Vector2(0, -data.radius)
	add_child(shape)


func _physics_process(delta: float) -> void:
	_tick_flash(delta)
	if _frozen_time > 0.0:
		_frozen_time -= delta
		if _frozen_time <= 0.0:
			_sprite.play()
		return
	if _fuse >= 0.0:
		_burn_fuse(delta)
		return
	var to_target := target.global_position - global_position
	if data.explode_damage > 0.0 and to_target.length() < data.radius + 14.0:
		_fuse = FUSE_TIME
		return
	if not data.is_boss and to_target.length_squared() > respawn_radius * respawn_radius * 2.25:
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
	if _marked_until > 0.0 and GameState.elapsed >= _marked_until:
		_marked_until = 0.0
		queue_redraw()
	if _slow_time > 0.0:
		_slow_time -= delta
		if _slow_time <= 0.0:
			_slow = 0.0
	velocity = move * data.speed * _speed_mult * (1.0 - _slow) + _separation * SEPARATION_SPEED + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 400.0 * delta)
	global_position += velocity * delta
	_sprite.flip_h = direction.x < 0.0


func _tick_flash(delta: float) -> void:
	if _flash_time > 0.0:
		_flash_time -= delta
		if _flash_time > 0.0:
			return
	_sprite.modulate = _state_color()


## Цвет врага по состоянию: замёрз, замедлен, проклят или обычный.
func _state_color() -> Color:
	if _frozen_time > 0.0:
		return Color(0.55, 0.8, 1.0)
	if _slow_time > 0.0:
		return Color(0.75, 0.9, 1.0)
	if GameState.elapsed < _curse_until:
		return Color(0.8, 0.55, 0.95)
	return Color.WHITE


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
	shot.damage = data.shot_damage * (ELITE_DAMAGE if elite else 1.0)
	get_parent().add_child(shot)


## Замедляет на долю amount (0.25 = −25% скорости) на duration секунд; сильное замедление важнее.
func apply_slow(amount: float, duration: float) -> void:
	if amount >= _slow:
		_slow = amount
	_slow_time = maxf(_slow_time, duration)


## Заморозка: враг стоит на месте duration секунд. Боссов только замедляет.
func freeze(duration: float) -> void:
	if data.is_boss:
		apply_slow(0.5, duration)
		return
	_frozen_time = maxf(_frozen_time, duration)
	_sprite.pause()


func is_frozen() -> bool:
	return _frozen_time > 0.0


## Проклятие: враг получает на bonus больше урона; blast > 0 — при смерти взрывается.
func curse(bonus: float, duration: float, blast: float = 0.0, blast_radius: float = 0.0) -> void:
	_curse_bonus = maxf(_curse_bonus if is_cursed() else 0.0, bonus)
	_curse_until = GameState.elapsed + duration
	_curse_blast = maxf(_curse_blast, blast)
	_curse_blast_radius = maxf(_curse_blast_radius, blast_radius)


func is_cursed() -> bool:
	return GameState.elapsed < _curse_until


## Толчок (например, от разрушенного мана-щита).
func push(impulse: Vector2) -> void:
	_knockback = impulse


func is_marked() -> bool:
	return GameState.elapsed < _marked_until


func mark() -> void:
	_marked_until = GameState.elapsed + MARK_TIME
	queue_redraw()


## Учитывает попадание для «Арканной метки» и возвращает множитель урона.
func _arcane_multiplier(source: StringName) -> float:
	var player := target as Player
	if player == null or player.arcane_bonus <= 0.0:
		return 1.0
	var now := GameState.elapsed
	if source != &"":
		_hits[source] = now
	if not is_marked():
		var recent := 0
		for id in _hits:
			if now - _hits[id] <= MARK_WINDOW:
				recent += 1
		if recent >= MARK_SOURCES:
			mark()
	return 1.0 + player.arcane_bonus if is_marked() else 1.0


func _curse_explode() -> void:
	if not is_cursed() or _curse_blast <= 0.0:
		return
	var blast := Blast.new()
	blast.damage = _curse_blast
	blast.radius = _curse_blast_radius
	blast.color = Color(0.7, 0.35, 0.9)
	blast.source = &"cursed_skull"
	blast.position = center()
	get_parent().add_child.call_deferred(blast)


func _spread_mark() -> void:
	var player := target as Player
	if player == null or not player.arcane_spread or not is_marked():
		return
	for enemy in Enemy.in_radius(get_tree(), center(), MARK_SPREAD_RADIUS):
		enemy.mark()


## Общий материал контура для всех элитных врагов.
static func outline_material() -> ShaderMaterial:
	if _outline_material == null:
		_outline_material = ShaderMaterial.new()
		_outline_material.shader = OUTLINE
	return _outline_material


func _make_elite() -> void:
	hp *= ELITE_HP
	contact_dps *= ELITE_DAMAGE
	_speed_mult = ELITE_SPEED
	scale = Vector2.ONE * ELITE_SCALE
	_sprite.material = outline_material()
	add_to_group(&"elites")


## Фитиль взрывного врага: мигает, стоит на месте, потом взрывается и исчезает без опыта.
func _burn_fuse(delta: float) -> void:
	_fuse -= delta
	_sprite.modulate = Color(1, 0.4, 0.3) if int(_fuse * 20.0) % 2 == 0 else Color.WHITE
	queue_redraw()
	if _fuse > 0.0 or dead:
		return
	dead = true
	var player := target as Player
	var radius := data.explode_radius * scale.x
	if player != null and player.global_position.distance_to(center()) <= radius + 6.0:
		player.take_damage(data.explode_damage * (ELITE_DAMAGE if elite else 1.0))
	var blast := Blast.new()
	blast.damage = 0.0
	blast.radius = radius
	blast.color = Color(1.0, 0.55, 0.2)
	blast.position = center()
	get_parent().add_child.call_deferred(blast)
	queue_free()


func _process(_delta: float) -> void:
	if elite:
		queue_redraw()


func _draw() -> void:
	if elite:
		var pulse := 0.5 + 0.5 * sin(GameState.elapsed * 6.0)
		draw_arc(Vector2.ZERO, data.radius + 3.0, 0.0, TAU, 24, Color(1.0, 0.8, 0.3, 0.4 + 0.4 * pulse), 1.0)
	if _fuse >= 0.0:
		draw_arc(center() - global_position, data.explode_radius, 0.0, TAU, 32, Color(1.0, 0.4, 0.2, 0.7), 1.0)
	if not is_marked():
		return
	var top := Vector2(0, _head_y)
	var rune := PackedVector2Array([top + Vector2(0, -4), top + Vector2(3, 0), top + Vector2(0, 4), top + Vector2(-3, 0), top + Vector2(0, -4)])
	draw_polyline(rune, Color(0.8, 0.5, 1.0), 1.5)
	draw_circle(top, 1.2, Color(0.95, 0.85, 1.0))


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


## source — id оружия, нанёсшего урон (нужен «Арканной метке»).
func take_damage(amount: float, from_direction: Vector2 = Vector2.ZERO, source: StringName = &"") -> void:
	if dead:
		return
	amount *= _arcane_multiplier(source)
	if is_cursed():
		amount *= 1.0 + _curse_bonus
	hp -= amount
	_knockback = from_direction * KNOCKBACK
	_flash_time = 0.08
	_sprite.modulate = Color(1, 0.35, 0.35)
	if hp <= 0.0:
		dead = true
		_spread_mark()
		_curse_explode()
		EventBus.enemy_died.emit(global_position, Formulas.xp_drop(data.xp * (ELITE_XP if elite else 1), GameState.minutes()))
		queue_free()
