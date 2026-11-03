extends Node
## Музыка на шине Music: трек меню, боевой трек забега, отдельный трек боя с боссом
## и короткие мелодии победы и поражения. Треки сменяются плавным переходом.
##
## Музыка — AlkaKrab «Fantasy RPG Music Vol. 2»: в игре можно, но выкладывать файлы
## в открытый репозиторий лицензия не разрешает, поэтому assets/music/ не в git.

## Имя -> [файл, громкость дБ, зациклить].
const TRACKS := {
	&"menu": ["menu.ogg", -2.0, true],
	&"battle": ["battle.ogg", -11.0, true],
	&"boss": ["boss.ogg", -9.0, true],
	&"victory": ["victory.ogg", -6.0, false],
	&"defeat": ["defeat.ogg", 0.0, false],
}
const DIR := "res://assets/music/"
const FADE := 1.0
const SILENT_DB := -40.0

var current: StringName = &""
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Music"
		add_child(player)
		_players.append(player)
	EventBus.boss_spawned.connect(func(_boss: Node2D) -> void: play(&"boss"))
	EventBus.boss_defeated.connect(func(_boss: Node2D, final: bool) -> void:
		if not final:
			play(&"battle"))
	EventBus.victory.connect(play.bind(&"victory"))
	EventBus.player_died.connect(play.bind(&"defeat"))


## Плавно перейти на трек; тот же трек не перезапускается.
func play(id: StringName) -> void:
	if id == current or not TRACKS.has(id):
		return
	current = id
	var entry: Array = TRACKS[id]
	var stream: AudioStream = load(DIR + entry[0])
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = entry[2]
	var old := _players[_active]
	_active = 1 - _active
	var new := _players[_active]
	new.stream = stream
	new.volume_db = SILENT_DB
	new.play()
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(new, "volume_db", entry[1], FADE)
	if old.playing:
		_tween.tween_property(old, "volume_db", SILENT_DB, FADE)
		_tween.chain().tween_callback(old.stop)
