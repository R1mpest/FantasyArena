class_name Experience
extends Node
## Опыт: роняет кристаллы с убитых врагов, считает уровень по XP(L).

## Куда класть кристаллы.
var pickups_root: Node2D
## Нужен для множителя опыта (Проклятый идол); без героя опыт не меняется.
var player: Player

var level := 1
var xp := 0
var to_next := Formulas.xp_to_next(1)


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.xp_collected.connect(add_xp)


func add_xp(amount: int) -> void:
	# После победы или поражения опыт не начисляется (иначе окно выбора карт откроется поверх итогов).
	if not GameState.running:
		return
	xp += amount
	while xp >= to_next:
		xp -= to_next
		level += 1
		to_next = Formulas.xp_to_next(level)
		EventBus.level_up.emit(level)


func _on_enemy_died(at: Vector2, value: int) -> void:
	var gem := XpGem.new()
	gem.value = roundi(value * player.mods[&"xp_mult"]) if player != null else value
	gem.position = at + Vector2(0, -4)
	pickups_root.add_child.call_deferred(gem)
