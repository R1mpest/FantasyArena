class_name Player
extends CharacterBody2D
## Игрок: движение, здоровье, слоты оружия и предметов, личные навыки.
## Внешний вид, стартовые статы, стартовое оружие и навыки берутся из CharacterData;
## модификаторы (урон, перезарядка, размер атак...) пересчитываются из предметов.

## Урон дошёл до здоровья (после щита).
signal hp_lost(amount: float)
## Щит опустел от урона.
signal shield_broken

const DEFAULT_CHARACTER := "res://data/characters/wizard/wizard.tres"
const BASE_PICKUP_RADIUS := 48.0
## Модификаторы предметов: эти перемножаются...
const MULT_MODS := [&"might", &"cooldown_mult", &"area_mult", &"move_speed_mult", &"pickup_mult", &"damage_taken_mult"]
## ...а эти складываются.
const ADD_MODS := [&"max_hp_bonus", &"regen", &"extra_projectiles"]

var character: CharacterData

var max_hp := 100.0
var hp := 100.0
var move_speed := 85.0
var regen := 0.0
var pickup_radius := BASE_PICKUP_RADIUS
## Итоговые модификаторы от предметов (см. MULT_MODS и ADD_MODS).
var mods: Dictionary = {}
## Прибавка к скорости атаки всего оружия (0.2 = +20%), её даёт «Поток».
var attack_speed_bonus := 0.0
## «Мана-щит»: поглощает урон раньше здоровья.
var shield := 0.0
var shield_max := 0.0
## Время забега последнего попадания по герою (для восстановления щита).
var last_hit_time := 0.0

## Куда оружие добавляет снаряды.
var projectile_root: Node
## id оружия -> узел Weapon (включая стартовое).
var weapons: Dictionary = {}
## id предмета -> уровень; данные предметов — в item_data.
var items: Dictionary = {}
var item_data: Dictionary = {}
## id навыка -> узел Perk.
var perks: Dictionary = {}
var dead := false

var _sprite: AnimatedSprite2D
var _hurtbox: Area2D
var _hit_flash := 0.0


func _ready() -> void:
	add_to_group(&"player")
	collision_layer = 1
	collision_mask = 0
	motion_mode = MOTION_MODE_FLOATING
	if character == null:
		character = load(DEFAULT_CHARACTER)
	recalc_mods()
	hp = max_hp

	_sprite = SpriteLib.make_sprite({&"idle": character.anim_idle, &"run": character.anim_run})
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

	if character.starting_weapon != null:
		add_weapon(character.starting_weapon)


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
	_hit_flash = 0.15
	_apply_damage(amount)


func heal(amount: float) -> void:
	hp = minf(hp + amount, max_hp)


# --- Модификаторы для оружия ---------------------------------------------------

## Множитель скорости атаки от навыков («Поток»).
func attack_speed() -> float:
	return 1.0 + attack_speed_bonus


func damage_mult() -> float:
	return mods[&"might"]


## Множитель перезарядки: интервалы оружия умножаются на него.
func cooldown_factor() -> float:
	return mods[&"cooldown_mult"] / attack_speed()


## Множитель размера и дальности атак (Линза).
func area() -> float:
	return mods[&"area_mult"]


func extra_projectiles() -> int:
	return int(mods[&"extra_projectiles"])


# --- Слоты ---------------------------------------------------------------------

func has_weapon(id: StringName) -> bool:
	return weapons.has(id)


func weapon_level(id: StringName) -> int:
	return (weapons[id] as Weapon).level if weapons.has(id) else 0


## Сколько занято слотов оружия этого пула (классовые или общие).
func weapon_count(pool: WeaponData.Pool) -> int:
	return weapons.values().filter(func(w: Weapon) -> bool: return w.data.pool == pool).size()


## Даёт оружие (уровень 1) или поднимает уровень уже взятого.
func level_up_weapon(data: WeaponData) -> void:
	if not has_weapon(data.id):
		add_weapon(data)
	else:
		(weapons[data.id] as Weapon).set_level(weapon_level(data.id) + 1)


func add_weapon(data: WeaponData) -> void:
	var weapon: Weapon = data.weapon_script.new()
	weapon.player = self
	weapon.data = data
	weapon.position = Vector2(0, -10)
	weapons[data.id] = weapon
	add_child(weapon)
	weapon.set_level(1)


func item_level(id: StringName) -> int:
	return items.get(id, 0)


func level_up_item(data: ItemData) -> void:
	items[data.id] = item_level(data.id) + 1
	item_data[data.id] = data
	recalc_mods()


func set_perk(skill: SkillData, level: int) -> void:
	var perk: Perk = perks.get(skill.perk)
	if perk == null:
		match skill.perk:
			&"mana_shield":
				perk = ManaShieldPerk.new()
			&"flow":
				perk = FlowPerk.new()
			_:
				push_error("Неизвестный навык: %s" % skill.perk)
				return
		perk.player = self
		perks[skill.perk] = perk
		add_child(perk)
	perk.set_level(level, skill.params_for(level))


func skill_level(skill: SkillData) -> int:
	var perk: Perk = perks.get(skill.perk)
	return perk.level if perk != null else 0


## Пересчитывает модификаторы из предметов; прибавка к макс. здоровью сразу лечит на неё.
func recalc_mods() -> void:
	var old_max := max_hp
	mods = {}
	for key in MULT_MODS:
		mods[key] = 1.0
	for key in ADD_MODS:
		mods[key] = 0.0
	for id in items:
		var params := (item_data[id] as ItemData).params_for(items[id])
		for key: String in params:
			var mod := StringName(key)
			if mod in MULT_MODS:
				mods[mod] *= float(params[key])
			elif mod in ADD_MODS:
				mods[mod] += float(params[key])
	max_hp = character.max_hp + mods[&"max_hp_bonus"]
	if max_hp > old_max:
		hp += max_hp - old_max
	hp = minf(hp, max_hp)
	move_speed = character.move_speed * mods[&"move_speed_mult"]
	pickup_radius = BASE_PICKUP_RADIUS * mods[&"pickup_mult"]
	regen = mods[&"regen"]


# --- Урон ----------------------------------------------------------------------

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
	_apply_damage(dps * delta)


## Весь урон по герою проходит здесь: модификатор получаемого урона, щит, здоровье.
func _apply_damage(amount: float) -> void:
	last_hit_time = GameState.elapsed
	amount *= mods[&"damage_taken_mult"]
	if shield > 0.0:
		var absorbed := minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
		if shield <= 0.0:
			shield = 0.0
			shield_broken.emit()
	if amount <= 0.0:
		return
	hp -= amount
	hp_lost.emit(amount)
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
