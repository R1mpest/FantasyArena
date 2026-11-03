extends Node
## Звуковые эффекты: пул проигрывателей на шине SFX. Частые звуки (смерть врага,
## кристалл опыта) ограничены по частоте, иначе 300 врагов превращают звук в шум.
## Звуки игровых событий подключены к EventBus, нажатия любых кнопок — автоматически.

## Имя -> [файл или список вариантов, громкость дБ, минимальный промежуток между повторами, с].
## Из вариантов каждый раз берётся случайный, чтобы частые звуки не звучали одинаково.
## Громкость подобрана по замерам файлов (средний уровень): оружие и боссы слышнее всего,
## смерть врагов и кристаллы — тихий фон.
const SOUNDS := {
	&"bolt": ["bolt.ogg", -5.0, 0.07],
	&"meteor": ["meteor.ogg", 10.0, 0.12],
	&"lightning": ["lightning.wav", -8.0, 0.1],
	&"bell": ["bell.wav", -13.0, 0.2],
	&"skull": ["skull.ogg", -3.0, 0.15],
	&"enemy_death": [["enemy_death_5.wav", "enemy_death_6.wav", "enemy_death_7.wav", "enemy_death_8.wav"], -25.0, 0.06],
	&"xp": ["xp.ogg", 0.0, 0.05],
	&"level_up": ["level_up.wav", -3.0, 0.3],
	&"hurt": ["hurt.ogg", 0.0, 0.3],
	&"player_death": ["player_death.wav", 0.0, 1.0],
	&"boss_incoming": ["boss_incoming.ogg", 0.0, 1.0],
	&"gate": ["gate.ogg", -1.0, 1.0],
	&"boss_defeated": ["boss_defeated.wav", -5.0, 1.0],
	&"boss_death": ["boss_death.ogg", 0.0, 1.0],
	&"ogre_slam": ["ogre_slam.ogg", 2.0, 0.5],
	&"demon_phase": ["demon_phase.ogg", 1.0, 1.0],
	&"arena_event": ["arena_event.wav", -7.0, 1.0],
	&"explosion": ["explosion.wav", -11.0, 0.1],
	&"enemy_shot": ["enemy_shot.wav", -27.0, 0.15],
	&"pause": ["pause.wav", -13.0, 0.1],
	&"click": ["click.ogg", 0.0, 0.05],
	&"card": ["card.ogg", -7.0, 0.2],
	&"shield_break": ["shield_break.ogg", 0.0, 0.3],
}
## Частые звуки играют в своих каналах и не обрывают звуки оружия и боссов.
const BACKGROUND := [&"enemy_death", &"xp", &"enemy_shot"]
const BACKGROUND_VOICES := 4
const DIR := "res://assets/sounds/"
const VOICES := 16

var _players: Array[AudioStreamPlayer] = []
var _background: Array[AudioStreamPlayer] = []
var _next_background := 0
var _streams: Dictionary = {}
## Имя -> время последнего проигрывания (мс, реальное время: звук нужен и на паузе).
var _last: Dictionary = {}
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id: StringName in SOUNDS:
		var files: Array = SOUNDS[id][0] if SOUNDS[id][0] is Array else [SOUNDS[id][0]]
		_streams[id] = files.map(func(file: String) -> AudioStream: return load(DIR + file))
	for i in VOICES + BACKGROUND_VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		(_players if i < VOICES else _background).append(player)
	EventBus.enemy_died.connect(func(_at: Vector2, _xp: int) -> void: play(&"enemy_death"))
	EventBus.xp_collected.connect(func(_amount: int) -> void: play(&"xp", 0.15))
	EventBus.level_up.connect(func(_level: int) -> void: play(&"level_up", 0.0))
	EventBus.player_died.connect(play.bind(&"player_death", 0.0))
	EventBus.boss_incoming.connect(func(_title: String) -> void:
		play(&"gate", 0.0)
		play(&"boss_incoming", 0.0))
	EventBus.boss_defeated.connect(func(_boss: Node2D, _final: bool) -> void:
		play(&"boss_death", 0.0)
		play(&"boss_defeated", 0.0))
	EventBus.arena_event.connect(func(_title: String) -> void: play(&"arena_event", 0.0))
	get_tree().node_added.connect(_on_node_added)


## Проиграть звук; pitch_jitter — случайный разброс высоты, чтобы повторы не звучали одинаково.
func play(id: StringName, pitch_jitter: float = 0.08) -> void:
	var entry: Array = SOUNDS.get(id, [])
	if entry.is_empty():
		push_warning("Нет звука %s" % id)
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(id, -100000)) < int(entry[2] * 1000.0):
		return
	_last[id] = now
	var player: AudioStreamPlayer
	if id in BACKGROUND:
		player = _background[_next_background]
		_next_background = (_next_background + 1) % BACKGROUND_VOICES
	else:
		player = _players[_next]
		_next = (_next + 1) % VOICES
	player.stream = (_streams[id] as Array).pick_random()
	player.volume_db = entry[1]
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()


## Щелчок у всех кнопок интерфейса. Карты улучшений звучат отдельно (LevelUpPanel.choose:
## туда приходит и нажатие, и выбор клавишей 1–3).
func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node is UpgradeCard:
		(node as BaseButton).pressed.connect(play.bind(&"click", 0.0))
