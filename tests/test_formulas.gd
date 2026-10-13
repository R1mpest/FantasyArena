extends Node
## Модульные тесты формул баланса и выбора улучшений (до подключения GUT).
## godot --headless --path . res://tests/test_formulas.tscn

var _failed := 0
var _passed := 0


func _ready() -> void:
	_test_xp()
	_test_difficulty()
	_test_spawn()
	_test_upgrade_roll()
	print("ТЕСТЫ: пройдено %d, провалено %d" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _test_xp() -> void:
	_check(Formulas.xp_to_next(1) == 15, "XP(1) = 15")
	_check(Formulas.xp_to_next(3) == 35, "XP(3) = 35")
	_check(Formulas.xp_to_next(10) == 168, "XP(10) = 168")
	var growing := true
	for level in range(1, 100):
		growing = growing and Formulas.xp_to_next(level + 1) > Formulas.xp_to_next(level)
	_check(growing, "XP(L) строго растёт")


func _test_difficulty() -> void:
	_check(is_equal_approx(Formulas.difficulty(0.0), 1.0), "k(0) = 1")
	_check(is_equal_approx(Formulas.difficulty(10.0), 2.2), "k(10) = 2.2")
	_check(is_equal_approx(Formulas.difficulty(15.0), 3.1), "k(15) = 3.1")


func _test_spawn() -> void:
	var ok := true
	for minute in range(0, 31):
		ok = ok and Formulas.spawn_interval(minute) >= 0.35 and Formulas.spawn_batch(minute) >= 1
	_check(ok, "интервал спавна не меньше 0.35 с, волна не пустая")


func _test_upgrade_roll() -> void:
	var system := UpgradeSystem.new()
	system._ready()
	_check(system.upgrades.size() == 9, "загружено 9 улучшений")

	var ids := {}
	for upgrade in system.roll(3):
		ids[upgrade.id] = true
	_check(ids.size() == 3, "3 разных варианта")

	# Все, кроме двух, на максимуме: предлагаются только два оставшихся.
	for upgrade in system.upgrades.slice(2):
		system.levels[upgrade.id] = upgrade.max_level
	var rolled := system.roll(3)
	var no_maxed := rolled.all(func(u: UpgradeData) -> bool: return system.level_of(u) < u.max_level)
	_check(rolled.size() == 2 and no_maxed, "максимальные уровни не предлагаются")

	for upgrade in system.upgrades:
		system.levels[upgrade.id] = upgrade.max_level
	rolled = system.roll(3)
	_check(rolled.size() == 1 and rolled[0].id == &"heal", "когда всё взято — лечение")
	system.free()


func _check(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("ПРОВАЛ: ", name)
