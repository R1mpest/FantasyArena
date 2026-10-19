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
	_test_spawn_types()
	_test_personal_perks()
	_test_settings()
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
	_check(Formulas.xp_drop(1, 0.0) == 1 and Formulas.xp_drop(6, 10.0) == 13, "опыт с врага растёт по k(t)")


func _test_upgrade_roll() -> void:
	var player := Player.new()
	var system := UpgradeSystem.new()
	system.player = player
	system._ready()
	_check(system.upgrades.size() == 21, "загружена 21 карта")

	var ids := {}
	for upgrade in system.roll(3):
		ids[upgrade.id] = true
	_check(ids.size() == 3, "3 разных варианта")

	var weapon_stats := system.upgrades.filter(func(u: UpgradeData) -> bool: return u.kind == UpgradeData.Kind.WEAPON_STAT)
	_check(not weapon_stats.any(system.is_available), "прокачка оружия скрыта, пока оружия нет")

	player.weapons[&"orbs"] = Node.new()
	var orbs_new: UpgradeData = system.upgrades.filter(func(u: UpgradeData) -> bool: return u.id == &"orbs")[0]
	var orbs_size: UpgradeData = system.upgrades.filter(func(u: UpgradeData) -> bool: return u.id == &"orbs_size")[0]
	_check(system.is_available(orbs_size) and not system.is_available(orbs_new), "с оружием: есть прокачка, нет повторной выдачи")
	player.weapons[&"orbs"].free()
	player.weapons.clear()

	# Всё доступное, кроме двух карт, на максимуме: предлагаются только эти две.
	var available := system.upgrades.filter(system.is_available)
	for upgrade in available.slice(2):
		system.levels[upgrade.id] = upgrade.max_level
	var rolled := system.roll(3)
	_check(rolled.size() == 2 and rolled.all(system.is_available), "максимальные уровни не предлагаются")

	for upgrade in system.upgrades:
		system.levels[upgrade.id] = upgrade.max_level
	rolled = system.roll(3)
	_check(rolled.size() == 1 and rolled[0].id == &"heal", "когда всё взято — лечение")
	system.free()
	player.free()


func _test_spawn_types() -> void:
	var spawner := EnemySpawner.new()
	add_child(spawner)
	var early := {}
	var late := {}
	for i in 300:
		early[spawner._pick_type(2.0).id] = true
		late[spawner._pick_type(4.0).id] = true
	_check(not early.has(&"orc_shaman"), "шаман не появляется до 3-й минуты")
	_check(late.has(&"orc_shaman"), "шаман появляется после 3-й минуты")
	var wave := {}
	var ogres := 0
	for i in 60:
		var type := spawner._pick_type(6.0, wave)
		wave[type.id] = wave.get(type.id, 0) + 1
		ogres += 1 if type.id == &"ogre" else 0
	_check(ogres <= 2, "не больше 2 огров за волну")
	spawner.free()


func _test_personal_perks() -> void:
	var player := Player.new()
	player.projectile_root = self
	add_child(player)
	_check(player.character != null and player.character.personal_upgrades.size() == 3, "у волшебника 3 личных навыка")
	var system := UpgradeSystem.new()
	system.player = player
	add_child(system)
	_check(system.upgrades.size() == 24, "21 общая карта + 3 личных")
	var by_id := {}
	for upgrade in system.upgrades:
		by_id[upgrade.id] = upgrade

	system.apply(by_id[&"mana_shield"])
	_check(player.shield == 15.0, "щит ур. 1 держит 15 урона")
	player.take_damage(10.0)
	_check(player.hp == 100.0 and player.shield == 5.0, "щит поглощает урон раньше здоровья")
	player.take_damage(10.0)
	_check(player.hp == 95.0 and player.shield == 0.0, "остаток урона после щита идёт в здоровье")

	system.apply(by_id[&"flow"])
	for i in 15:
		EventBus.enemy_died.emit(Vector2.ZERO, 1)
	_check(is_equal_approx(player.attack_speed_bonus, 0.12), "«Поток» ур. 1 упирается в +12%")
	player.take_damage(1.0)
	_check(player.attack_speed_bonus == 0.0, "урон по здоровью сбрасывает «Поток»")

	system.apply(by_id[&"resonance"])
	_check(player.resonance_every == 6 and player.resonance_radius == 24.0, "«Резонанс» ур. 1: каждый 6-й, радиус 24")
	system.apply(by_id[&"resonance"])
	system.apply(by_id[&"resonance"])
	_check(player.resonance_every == 4 and player.resonance_radius == 32.0, "«Резонанс» ур. 3: каждый 4-й, радиус 32")
	_check(not system.is_available(by_id[&"resonance"]), "навык выше 3-го уровня не предлагается")
	system.free()
	player.free()


func _test_settings() -> void:
	var path := "user://test_settings.cfg"
	var saved := [SaveManager.resolution, SaveManager.window_mode, SaveManager.volumes.duplicate(), SaveManager.aim_mode]
	SaveManager.resolution = Vector2i(1600, 900)
	SaveManager.window_mode = SaveManager.WindowMode.BORDERLESS
	SaveManager.volumes[&"Music"] = 0.25
	SaveManager.aim_mode = SaveManager.AimMode.MOUSE
	SaveManager.save_to(path)
	SaveManager.resolution = Vector2i(1280, 720)
	SaveManager.window_mode = SaveManager.WindowMode.WINDOWED
	SaveManager.volumes[&"Music"] = 1.0
	SaveManager.aim_mode = SaveManager.AimMode.AUTO
	SaveManager.load_from(path)
	_check(SaveManager.resolution == Vector2i(1600, 900) and SaveManager.window_mode == SaveManager.WindowMode.BORDERLESS, "настройки экрана сохраняются и читаются")
	_check(is_equal_approx(SaveManager.volumes[&"Music"], 0.25) and SaveManager.aim_mode == SaveManager.AimMode.MOUSE, "громкость и прицеливание сохраняются")
	_check(AudioServer.get_bus_index(&"Music") != -1 and AudioServer.get_bus_index(&"SFX") != -1, "шины Music и SFX созданы")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	SaveManager.resolution = saved[0]
	SaveManager.window_mode = saved[1]
	SaveManager.volumes = saved[2]
	SaveManager.aim_mode = saved[3]


func _check(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("ПРОВАЛ: ", name)
