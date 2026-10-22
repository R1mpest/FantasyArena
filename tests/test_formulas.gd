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
	_test_style_items()
	_test_arcane_mark()
	_test_new_weapons()
	_test_elites()
	_test_bosses()
	_test_magnet()
	_test_spawn_types()
	_test_personal_perks()
	_test_settings()
	print("ТЕСТЫ: пройдено %d, провалено %d" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _test_xp() -> void:
	_check(Formulas.xp_to_next(1) == 16, "XP(1) = 16")
	_check(Formulas.xp_to_next(3) == 41, "XP(3) = 41")
	_check(Formulas.xp_to_next(10) == 199, "XP(10) = 199")
	var growing := true
	for level in range(1, 100):
		growing = growing and Formulas.xp_to_next(level + 1) > Formulas.xp_to_next(level)
	_check(growing, "XP(L) строго растёт")


func _test_difficulty() -> void:
	_check(is_equal_approx(Formulas.difficulty(0.0), 1.0), "k(0) = 1")
	_check(is_equal_approx(Formulas.difficulty(10.0), 1.4), "k(10) = 1,4")
	_check(is_equal_approx(Formulas.difficulty(15.0), 1.6), "k(15) = 1,6")
	_check(is_equal_approx(Formulas.xp_multiplier(15.0), 1.0) and Formulas.xp_drop(6, 10.0) == 6, "опыт с врага не растёт со временем: темп задаёт XP(L)")


func _test_spawn() -> void:
	var table: WaveTable = load("res://data/waves/wave_table.tres")
	_check(table.minutes.size() == 15, "в таблице волн 15 минут")
	var ok := true
	var ids := {}
	for file in ResourceLoader.list_directory("res://data/enemies/"):
		if file.ends_with(".tres"):
			ids[String((load("res://data/enemies/" + file) as EnemyData).id)] = true
	for segment in table.minutes:
		ok = ok and float(segment["interval"]) >= 0.35 and int(segment["batch"]) >= 1 and int(segment["limit"]) <= 300
		for id in segment["enemies"]:
			ok = ok and ids.has(id)
	_check(ok, "таблица волн: разумные интервалы и лимиты, все враги существуют")


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
	_check(system.weapons.size() == 7 and system.items.size() == 15 and system.skills.size() == 3, "7 видов оружия (3 классовых), 15 предметов, 3 навыка")
	var special := system.roll(10)
	_check(special.size() == 3 and special.all(func(o: CardOffer) -> bool: return o.is_style_item()), "на 10-м уровне — 3 предмета, меняющих стиль")

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


func _test_style_items() -> void:
	var build := _new_build()
	var player: Player = build[0]
	var system: UpgradeSystem = build[1]
	system.give(&"life_ring")
	var crystal_offer := system._offer(CardOffer.Kind.ITEM, system.items.filter(func(i: ItemData) -> bool: return i.id == &"blood_crystal")[0])
	_check(crystal_offer.warning != "", "на карте Кровавого кристалла предупреждение про Кольцо жизни")
	system.give(&"blood_crystal")
	_check(player.item_disabled(&"life_ring") and player.regen == 0.0, "Кровавый кристалл отключает Кольцо жизни")
	player.hp = 50.0
	player.heal(30.0)
	_check(player.hp == 50.0, "Кровавый кристалл отключает лечение")
	EventBus.enemy_died.emit(Vector2.ZERO, 1)
	_check(is_equal_approx(player.hp, 50.5), "убийство лечит на 0,5")
	player.hp = 10.0
	var heal := system.roll(2).any(func(o: CardOffer) -> bool: return o.kind == CardOffer.Kind.HEAL)
	_check(not heal, "с кристаллом карта лечения не предлагается")

	system.give(&"plate")
	system.give(&"glass_cannon")
	_check(is_equal_approx(player.damage_mult(), 1.4), "Стеклянная пушка ур. 1: урон ×1,4")
	_check(is_equal_approx(player.mods[&"damage_taken_mult"], 1.5 * 0.96), "получаемый урон ×1,5, пластина вполсилы (−4%)")
	var plate_offered := false
	for i in 50:
		for offer in system.roll(2):
			plate_offered = plate_offered or (offer.data is ItemData and offer.data.id == &"plate" and offer.is_new())
	_check(not plate_offered, "при пушке пластина не предлагается новой")

	system.give(&"phoenix_feather")
	system.give(&"phoenix_feather")
	system.give(&"phoenix_feather")
	player.hp = 1.0
	player.take_damage(500.0)
	_check(not player.dead and is_equal_approx(player.hp, player.max_hp * 0.5), "Перо феникса воскрешает с 50% ОЗ")
	player.take_damage(500.0)
	_check(not player.dead, "после воскрешения неуязвимость")
	_check(not system.candidates(CardOffer.Kind.ITEM).any(func(i: ItemData) -> bool: return i.id == &"phoenix_feather"), "сработавшее перо больше не предлагается")
	_free_build(build)

	build = _new_build()
	player = build[0]
	system = build[1]
	system.give(&"anchor")
	var anchor: AnchorEffect = player.item_effects[&"anchor"]
	_check(is_equal_approx(player.move_speed, 85.0 * 0.9), "Якорь: скорость бега −10%")
	player.velocity = Vector2.ZERO
	anchor._physics_process(2.5)
	_check(is_equal_approx(player.damage_mult(), 1.25), "Якорь: на месте 2 с — урон +25%")
	player.velocity = Vector2(50, 0)
	anchor._physics_process(0.1)
	_check(player.damage_mult() == 1.0, "Якорь: движение сбрасывает бонус")

	system.give(&"cursed_idol")
	_check(is_equal_approx(player.mods[&"xp_mult"], 1.3) and not system.give(&"cursed_idol"), "Идол: опыт +30%, без уровней")
	var spawner := EnemySpawner.new()
	spawner.player = player
	add_child(spawner)
	player.mods[&"tier_upgrade_chance"] = 1.0
	var goblin: EnemyData = spawner.type_of(&"goblin")
	_check(spawner._upgrade_tier(goblin, 4.0, {}).tier > 1, "Идол: мелочь заменяется врагом ступени выше")
	_check(spawner._upgrade_tier(goblin, 0.0, {}) == goblin, "в первые минуты заменять не на кого")
	spawner.free()
	_free_build(build)


func _test_arcane_mark() -> void:
	var build := _new_build()
	var player: Player = build[0]
	var system: UpgradeSystem = build[1]
	system.give(&"arcane_mark")
	var enemy := Enemy.new()
	enemy.data = load("res://data/enemies/ogre.tres")
	enemy.target = player
	add_child(enemy)
	var hp_before := enemy.hp
	enemy.take_damage(1.0, Vector2.ZERO, &"magic_bolt")
	enemy.take_damage(1.0, Vector2.ZERO, &"orbs")
	_check(not enemy.is_marked(), "двух видов оружия мало для метки")
	enemy.take_damage(10.0, Vector2.ZERO, &"aura")
	_check(enemy.is_marked() and is_equal_approx(hp_before - enemy.hp, 2.0 + 12.0), "третье оружие вешает метку: +20% урона")
	enemy.free()
	_free_build(build)


func _spawn_test_enemy(player: Player, id: String, at: Vector2) -> Enemy:
	var enemy := Enemy.new()
	enemy.data = load("res://data/enemies/%s.tres" % id)
	enemy.target = player
	enemy.position = at
	add_child(enemy)
	return enemy


func _test_new_weapons() -> void:
	var build := _new_build()
	var player: Player = build[0]
	var system: UpgradeSystem = build[1]
	var enemies: Array[Enemy] = []
	for i in 4:
		enemies.append(_spawn_test_enemy(player, "ogre", player.global_position + Vector2(40 + 30 * i, 0)))

	system.give(&"chain_lightning")
	var chain: ChainLightningWeapon = player.weapons[&"chain_lightning"]
	chain._cooldown = 0.0
	chain._physics_process(0.016)
	var hit_count := enemies.filter(func(e: Enemy) -> bool: return e.hp < e.data.max_hp).size()
	_check(hit_count == 4, "молния перескакивает по 4 врагам (3 перескока)")
	_check(enemies[1].hp > enemies[0].hp, "каждый перескок слабее")

	system.give(&"frost_bell")
	for i in 4:
		system.give(&"frost_bell")
	var bell: FrostBellWeapon = player.weapons[&"frost_bell"]
	bell._cooldown = 0.0
	bell._physics_process(0.016)
	_check(enemies[0].is_frozen(), "колокол ур. 5 замораживает")

	for enemy in enemies:
		enemy.hp = enemy.data.max_hp
	enemies[2].hp = enemy_hp_boost(enemies[2])
	system.give(&"cursed_skull")
	var skull_weapon: CursedSkullWeapon = player.weapons[&"cursed_skull"]
	var sorted := enemies.duplicate()
	sorted.sort_custom(CursedSkullWeapon._tougher)
	_check(sorted[0] == enemies[2], "череп выбирает самого живучего")
	enemies[2].curse(0.25, 4.0)
	var before := enemies[2].hp
	enemies[2].take_damage(10.0, Vector2.ZERO, &"test")
	_check(is_equal_approx(before - enemies[2].hp, 12.5), "проклятый враг получает +25% урона")
	_check(skull_weapon.extra_projectiles() == 0, "без Колчана один череп")
	for enemy in enemies:
		enemy.free()
	_free_build(build)


func _test_elites() -> void:
	var build := _new_build()
	var player: Player = build[0]
	var normal := _spawn_test_enemy(player, "orc_warrior", Vector2(300, 0))
	var elite := Enemy.new()
	elite.data = normal.data
	elite.elite = true
	elite.target = player
	elite.position = Vector2(-300, 0)
	add_child(elite)
	_check(is_equal_approx(elite.hp, normal.hp * 3.0) and elite.scale.x > 1.0, "элитный: ×3 здоровья и крупнее")
	_check(elite.is_in_group(&"elites") and elite._sprite.material != null, "элитный в группе elites и с контуром")
	var pumpkin := _spawn_test_enemy(player, "pumpkin_dude", player.global_position + Vector2(10, 0))
	pumpkin._physics_process(0.016)
	_check(pumpkin._fuse > 0.0, "взрывной у героя поджигает фитиль")
	var hp_before := player.hp
	pumpkin._physics_process(1.0)
	_check(pumpkin.dead and player.hp < hp_before, "взрыв ранит героя")
	normal.free()
	elite.free()
	if is_instance_valid(pumpkin):
		pumpkin.free()
	_free_build(build)


func _test_bosses() -> void:
	var build := _new_build()
	var player: Player = build[0]
	var spawner := EnemySpawner.new()
	spawner.player = player
	var arena := Node2D.new()
	add_child(arena)
	spawner.enemies_root = arena
	add_child(spawner)
	var events := []
	var on_incoming := func(title: String) -> void: events.append(title)
	var on_victory := func() -> void: events.append("победа")
	EventBus.boss_incoming.connect(on_incoming)
	EventBus.victory.connect(on_victory)
	var saved_time := GameState.elapsed
	var saved_running := GameState.running
	GameState.running = true

	GameState.elapsed = 297.5
	spawner.check_bosses()
	_check(events == ["Огр-вожак"] and get_tree().get_node_count_in_group(&"bosses") == 0, "за 3 с до 5:00 — предупреждение, босса ещё нет")
	GameState.elapsed = 300.0
	spawner.check_bosses()
	var ogre: Boss = get_tree().get_first_node_in_group(&"bosses")
	_check(ogre is OgreChief and ogre.hp == 2250.0, "на 5:00 появляется Огр-вожак с 2250 ОЗ")
	ogre.freeze(1.0)
	ogre.push(Vector2(500, 0))
	_check(not ogre.is_frozen() and ogre._knockback == Vector2.ZERO, "босс не замерзает и не отбрасывается")
	ogre.take_damage(5000.0)
	_check(not events.has("победа"), "обычный босс — не победа")

	var demon: Boss = spawner.spawn_boss(&"big_demon", true)
	demon.take_damage(demon.hp * 0.6)
	demon._boss_process(0.016)
	_check(demon is DemonBoss and (demon as DemonBoss).enraged, "демон ниже 50% ОЗ входит во вторую фазу")
	demon.take_damage(demon.hp + 1.0)
	_check(events.has("победа") and not GameState.running, "убит финальный босс — победа")

	EventBus.boss_incoming.disconnect(on_incoming)
	EventBus.victory.disconnect(on_victory)
	GameState.elapsed = saved_time
	GameState.running = saved_running
	for node in get_tree().get_nodes_in_group(&"enemies"):
		node.free()
	spawner.free()
	arena.free()
	_free_build(build)


func _test_magnet() -> void:
	var build := _new_build()
	var gems: Array[XpGem] = []
	for i in 3:
		var gem := XpGem.new()
		gem.position = Vector2(500 + 100 * i, 300)
		add_child(gem)
		gems.append(gem)
	_check(not gems.any(func(g: XpGem) -> bool: return g._attracted), "далёкий опыт сам не летит")
	var magnet := MagnetCrystal.new()
	add_child(magnet)
	magnet.collect()
	_check(gems.all(func(g: XpGem) -> bool: return g._attracted), "кристалл-магнит притягивает весь опыт на полу")
	for gem in gems:
		gem.free()
	_free_build(build)


func enemy_hp_boost(enemy: Enemy) -> float:
	return enemy.data.max_hp * 2.0


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
