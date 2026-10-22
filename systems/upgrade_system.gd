class_name UpgradeSystem
extends Node
## Карты на повышении уровня по правилам из ТЗ:
## - карта 1 — навык, оружие или предмет (веса 7 / 7 / 6), карты 2 и 3 — только оружие или предмет;
## - новое оружие или предмет — только при свободном слоте нужного типа;
## - взятый предмет убирает из выдачи несовместимые с ним (ItemData.excludes);
## - на 10, 20 и 30 уровне — выбор из 3 предметов, меняющих стиль игры;
## - меньше 25% здоровья — одна карта заменяется на «Восполнить 50% ОЗ»;
## - всё занято и прокачано — лечение (с Кровавым кристаллом — опыт).

const WEAPONS_DIR := "res://data/weapons/"
const ITEMS_DIR := "res://data/items/"
const CLASS_SLOTS := 3
const GENERAL_SLOTS := 3
const ITEM_SLOTS := 6
const SPECIAL_LEVELS := [10, 20, 30]
const FIRST_CARD_WEIGHTS := {CardOffer.Kind.SKILL: 7.0, CardOffer.Kind.WEAPON: 7.0, CardOffer.Kind.ITEM: 6.0}
const OTHER_CARD_WEIGHTS := {CardOffer.Kind.WEAPON: 7.0, CardOffer.Kind.ITEM: 6.0}
## Бонус к весу уже взятых веток, чтобы билд складывался.
const OWNED_WEIGHT_BONUS := 1.3
## Предметы, меняющие стиль, в обычной выдаче выпадают реже.
const STYLE_ITEM_WEIGHT := 0.3
const LOW_HP := 0.25

var player: Player
var experience: Experience
var weapons: Array[WeaponData] = []
var items: Array[ItemData] = []
var skills: Array[SkillData] = []


func _ready() -> void:
	weapons.append_array(player.character.class_weapons)
	for file in ResourceLoader.list_directory(WEAPONS_DIR):
		var weapon: WeaponData = load(WEAPONS_DIR + file) if file.ends_with(".tres") else null
		if weapon != null and weapon.pool == WeaponData.Pool.GENERAL:
			weapons.append(weapon)
	for file in ResourceLoader.list_directory(ITEMS_DIR):
		if file.ends_with(".tres"):
			items.append(load(ITEMS_DIR + file))
	skills.append_array(player.character.skills)


## Карты для повышения на уровень level.
func roll(level: int) -> Array[CardOffer]:
	var result: Array[CardOffer] = []
	if level in SPECIAL_LEVELS:
		result = _style_offers()
	if result.is_empty():
		var used := {}
		var first := _pick(FIRST_CARD_WEIGHTS, used)
		if first != null:
			result.append(first)
		while result.size() < 3:
			var offer := _pick(OTHER_CARD_WEIGHTS, used)
			if offer == null:
				break
			result.append(offer)
	if result.is_empty():
		result.append(_fallback())
	if player.hp < player.max_hp * LOW_HP and not blocks_healing():
		var heal := _heal_offer(0.5, "Восполнить 50% ОЗ")
		if result.size() < 3:
			result.append(heal)
		else:
			result[2] = heal
	return result


func apply(offer: CardOffer) -> void:
	match offer.kind:
		CardOffer.Kind.SKILL:
			player.set_perk(offer.data, offer.level)
		CardOffer.Kind.WEAPON:
			player.level_up_weapon(offer.data)
		CardOffer.Kind.ITEM:
			player.level_up_item(offer.data)
		CardOffer.Kind.HEAL:
			player.heal(player.max_hp * offer.amount)
		CardOffer.Kind.XP:
			experience.add_xp(int(offer.amount))


## Поднимает уровень оружия, предмета или навыка по id (для тестов и автопрогона).
func give(id: StringName) -> bool:
	for kind in [CardOffer.Kind.SKILL, CardOffer.Kind.WEAPON, CardOffer.Kind.ITEM]:
		for data: Resource in _all(kind):
			if data.id == id and level_of(kind, data) < _max_level(kind, data):
				apply(_offer(kind, data))
				return true
	return false


func level_of(kind: CardOffer.Kind, data: Resource) -> int:
	match kind:
		CardOffer.Kind.SKILL:
			return player.skill_level(data)
		CardOffer.Kind.WEAPON:
			return player.weapon_level(data.id)
		CardOffer.Kind.ITEM:
			return player.item_level(data.id)
	return 0


## Лечение отключено (Кровавый кристалл; появится вместе с предметами, меняющими стиль).
func blocks_healing() -> bool:
	return player.item_level(&"blood_crystal") > 0


## Кандидаты на карту этого типа: прокачка взятого или новое при свободном слоте.
func candidates(kind: CardOffer.Kind) -> Array:
	return _all(kind).filter(func(data: Resource) -> bool: return _is_available(kind, data))


func _all(kind: CardOffer.Kind) -> Array:
	match kind:
		CardOffer.Kind.SKILL:
			return skills
		CardOffer.Kind.WEAPON:
			return weapons
	return items


func _is_available(kind: CardOffer.Kind, data: Resource) -> bool:
	if kind == CardOffer.Kind.ITEM and player.spent_items.has(data.id):
		return false
	var level := level_of(kind, data)
	if level >= _max_level(kind, data):
		return false
	if level > 0:
		return true
	match kind:
		CardOffer.Kind.WEAPON:
			var weapon := data as WeaponData
			var slots := CLASS_SLOTS if weapon.pool == WeaponData.Pool.CLASS else GENERAL_SLOTS
			return player.weapon_count(weapon.pool) < slots
		CardOffer.Kind.ITEM:
			return player.items.size() < ITEM_SLOTS and not _excluded(data.id)
	return true


func _excluded(id: StringName) -> bool:
	for owned in player.item_data.values():
		if id in (owned as ItemData).excludes:
			return true
	return false


func _max_level(kind: CardOffer.Kind, data: Resource) -> int:
	match kind:
		CardOffer.Kind.SKILL:
			return (data as SkillData).max_level
		CardOffer.Kind.WEAPON:
			return (data as WeaponData).max_level()
	return (data as ItemData).max_level()


func _weight(kind: CardOffer.Kind, data: Resource) -> float:
	var weight: float = data.weight
	if kind == CardOffer.Kind.ITEM and (data as ItemData).kind == ItemData.Kind.STYLE:
		weight *= STYLE_ITEM_WEIGHT
	return weight * (OWNED_WEIGHT_BONUS if level_of(kind, data) > 0 else 1.0)


## Тип карты по весам среди типов, где есть кандидаты, затем сам кандидат по весам.
func _pick(type_weights: Dictionary, used: Dictionary) -> CardOffer:
	var pools := {}
	for kind in type_weights:
		var pool := candidates(kind).filter(func(data: Resource) -> bool: return not used.has(data))
		if not pool.is_empty():
			pools[kind] = pool
	if pools.is_empty():
		return null
	var kind: CardOffer.Kind = _weighted(pools.keys(), func(k: CardOffer.Kind) -> float: return type_weights[k])
	var data: Resource = _weighted(pools[kind], func(d: Resource) -> float: return _weight(kind, d))
	used[data] = true
	return _offer(kind, data)


## Особое повышение: новые предметы, меняющие стиль (если есть слот), иначе прокачка взятых.
func _style_offers() -> Array[CardOffer]:
	var style := items.filter(func(item: ItemData) -> bool:
		return item.kind == ItemData.Kind.STYLE and _is_available(CardOffer.Kind.ITEM, item))
	var fresh := style.filter(func(item: ItemData) -> bool: return player.item_level(item.id) == 0)
	var pool := fresh if not fresh.is_empty() and player.items.size() < ITEM_SLOTS else style
	pool.shuffle()
	var result: Array[CardOffer] = []
	for item: ItemData in pool.slice(0, 3):
		result.append(_offer(CardOffer.Kind.ITEM, item))
	return result


func _fallback() -> CardOffer:
	if blocks_healing():
		var offer := CardOffer.new()
		offer.kind = CardOffer.Kind.XP
		offer.amount = ceilf(experience.to_next * 0.4)
		offer.title = "Опыт"
		offer.description = "+%d опыта" % offer.amount
		offer.icon = SpriteLib.texture("coin_anim_f0")
		return offer
	return _heal_offer(0.3, "Восстановить 30% ОЗ")


func _heal_offer(fraction: float, text: String) -> CardOffer:
	var offer := CardOffer.new()
	offer.kind = CardOffer.Kind.HEAL
	offer.amount = fraction
	offer.title = "Лечение"
	offer.description = text
	offer.icon = SpriteLib.texture("flask_big_red")
	return offer


func _offer(kind: CardOffer.Kind, data: Resource) -> CardOffer:
	var offer := CardOffer.new()
	offer.kind = kind
	offer.data = data
	offer.level = level_of(kind, data) + 1
	offer.max_level = _max_level(kind, data)
	offer.title = data.title
	offer.icon = data.icon
	match kind:
		CardOffer.Kind.SKILL:
			offer.description = (data as SkillData).text_for(offer.level)
		CardOffer.Kind.WEAPON:
			var weapon := data as WeaponData
			offer.description = weapon.description + "\n" + weapon.text_for(1) if offer.level == 1 else weapon.text_for(offer.level)
		CardOffer.Kind.ITEM:
			offer.description = (data as ItemData).text_for(offer.level)
			offer.warning = _conflict_warning(data.id) if offer.level == 1 else ""
	return offer


## Предупреждение на карте предмета, который ослабит уже взятый.
func _conflict_warning(id: StringName) -> String:
	for victim in Player.DISABLED_BY:
		if Player.DISABLED_BY[victim] == id and player.item_level(victim) > 0:
			return "%s перестанет работать" % player.item_data[victim].title
	for victim in Player.HALVED_BY:
		if Player.HALVED_BY[victim] == id and player.item_level(victim) > 0:
			return "%s будет работать вполсилы" % player.item_data[victim].title
	return ""


static func _weighted(options: Array, weight_of: Callable) -> Variant:
	var total := 0.0
	for option in options:
		total += weight_of.call(option)
	var roll_value := randf() * total
	for option in options:
		roll_value -= weight_of.call(option)
		if roll_value <= 0.0:
			return option
	return options.back()
