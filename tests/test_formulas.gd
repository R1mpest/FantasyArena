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
	_test_weapon_levels()
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


## Игрок и система прокачки в дереве сцены, как в забеге.
func _new_build() -> Array:
	var player := Player.new()
	player.projectile_root = self
	add_child(player)
	var experience := Experience.new()
	var system := UpgradeSystem.new()
	system.player = player
	system.experience = experience
	add_child(system)
	return [player, system, experience]


func _free_build(build: Array) -> void:
	for node: Node in build:
		node.free()


func _test_upgrade_roll() -> void:
	var build := _new_build()
	var player: Player = build[0]
	var system: UpgradeSystem = build[1]
	_check(player.weapon_level(&"magic_bolt") == 1, "стартовое оружие на 1-м уровне")
	_check(system.weapons.size() == 4 and system.items.size() == 9 and system.skills.size() == 2, "4 оружия, 9 предметов, 2 навыка")

	var skill_later := false
	var distinct := true
	for i in 200:
		var offers := system.roll(2)
		var seen := {}
		for j in offers.size():
			seen[offers[j].data] = true
			skill_later = skill_later or (j > 0 and offers[j].kind == CardOffer.Kind.SKILL)
		distinct = distinct and seen.size() == offers.size() and offers.size() == 3
	_check(distinct, "3 разные карты")
	_check(not skill_later, "навыки только на первой карте")

	for id in [&"boots", &"heart", &"magnet", &"power", &"lens", &"plate"]:
		system.give(id)
	var new_item := false
	for i in 100:
		for offer in system.roll(2):
			new_item = new_item or (offer.kind == CardOffer.Kind.ITEM and offer.is_new())
	_check(not new_item, "при 6 занятых слотах новые предметы не предлагаются")

	_check(is_equal_approx(player.damage_mult(), 1.15) and is_equal_approx(player.area(), 1.1), "Сила и Линза ур. 1: +15% урона, +10% размера")
	_check(player.max_hp == 120.0 and player.hp == 120.0, "Сердце ур. 1 поднимает и лечит здоровье")
	_check(is_equal_approx(player.mods[&"damage_taken_mult"], 0.92), "Латная пластина ур. 1: −8% урона")

	player.hp = 20.0
	var heal_offered := system.roll(2).any(func(o: CardOffer) -> bool: return o.kind == CardOffer.Kind.HEAL and o.amount == 0.5)
	_check(heal_offered, "при <25% ОЗ предлагается «Восполнить 50% ОЗ»")
	player.hp = player.max_hp

	for i in 200:
		for kind in [CardOffer.Kind.SKILL, CardOffer.Kind.WEAPON, CardOffer.Kind.ITEM]:
			for data: Resource in system.candidates(kind):
				system.give(data.id)
	var rolled := system.roll(2)
	_check(rolled.size() == 1 and rolled[0].kind == CardOffer.Kind.HEAL, "всё взято и прокачано — лечение")
	_check(system.roll(10).size() == 1, "на 10-м уровне без предметов стиля — обычная выдача")
	_free_build(build)


func _test_weapon_levels() -> void:
	var build := _new_build()
	var player: Player = build[0]
	var system: UpgradeSystem = build[1]
	system.give(&"orbs")
	var orbs: OrbitWeapon = player.weapons[&"orbs"]
	_check(orbs.level == 1 and orbs.orb_count == 2.0 and orbs.damage == 12.0, "сферы ур. 1: 2 сферы, 12 урона")
	for i in 4:
		system.give(&"orbs")
	_check(orbs.level == 5 and orbs.orb_count == 4.0 and orbs.knockback and orbs.orb_size == 1.25, "сферы ур. 5: 4 сферы, отталкивание, размер с 3-го")
	_check(not system.give(&"orbs"), "выше 5-го уровня оружие не качается")
	for i in 4:
		system.give(&"magic_bolt")
	var bolt: MagicBoltWeapon = player.weapons[&"magic_bolt"]
	_check(bolt.resonance_every == 4.0 and bolt.projectile_count == 3.0, "снаряд ур. 5: 3 снаряда, каждый 4-й взрывается")
	system.give(&"quiver")
	_check(orbs._orb_offsets().size() == 5, "Колчан добавляет сферу")
	_check(bolt.extra_projectiles() == 0, "Колчан не действует на стартовый снаряд")
	_free_build(build)


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
	var build := _new_build()
	var player: Player = build[0]
	var system: UpgradeSystem = build[1]
	system.give(&"mana_shield")
	_check(player.shield == 15.0, "щит ур. 1 держит 15 урона")
	player.take_damage(10.0)
	_check(player.hp == 100.0 and player.shield == 5.0, "щит поглощает урон раньше здоровья")
	player.take_damage(10.0)
	_check(player.hp == 95.0 and player.shield == 0.0, "остаток урона после щита идёт в здоровье")

	system.give(&"flow")
	for i in 15:
		EventBus.enemy_died.emit(Vector2.ZERO, 1)
	_check(is_equal_approx(player.attack_speed_bonus, 0.12), "«Поток» ур. 1 упирается в +12%")
	_check(player.cooldown_factor() < 0.9, "«Поток» ускоряет перезарядку оружия")
	player.take_damage(1.0)
	_check(player.attack_speed_bonus == 0.0, "урон по здоровью сбрасывает «Поток»")
	system.give(&"flow")
	system.give(&"flow")
	_check(not system.give(&"flow"), "навык выше 3-го уровня не качается")
	_free_build(build)


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
