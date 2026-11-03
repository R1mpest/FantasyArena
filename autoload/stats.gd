extends Node
## Статистика забегов (Ф16): рекорды одного забега и итоги за всё время.
## Хранится в user://stats.cfg. Забег начинается в Run (begin_run), заканчивается
## гибелью героя, победой или выходом из забега — в любом случае учитывается один раз.
## Забеги из тестовых сцен (res://tests/) не записываются.

const PATH := "user://stats.cfg"

## Рекорды: id -> [подпись, больше — лучше (false — меньше лучше, для быстрой победы)].
const RECORDS := {
	&"best_time": ["Лучшее время", true],
	&"best_level": ["Максимальный уровень", true],
	&"best_kills": ["Больше всего убийств", true],
	&"best_bosses": ["Больше всего боссов", true],
	&"fastest_win": ["Самая быстрая победа", false],
}
const TOTALS := {
	&"runs": "Забегов",
	&"wins": "Побед",
	&"deaths": "Поражений",
	&"kills": "Убито врагов",
	&"bosses": "Убито боссов",
	&"levels": "Повышений уровня",
	&"time": "Время в забегах",
}
## Значения, которые показываются как время.
const TIME_KEYS := [&"best_time", &"fastest_win", &"time"]

var path := PATH
var records: Dictionary = {}
var totals: Dictionary = {}
## Рекорды, побитые в последнем законченном забеге (подписи для экрана итогов).
var new_records: PackedStringArray = []

var _active := false
var _bosses := 0


func _ready() -> void:
	load_from(path)
	EventBus.boss_defeated.connect(func(_boss: Node2D, _final: bool) -> void: _bosses += 1)
	EventBus.player_died.connect(func() -> void: finish_run(false))
	EventBus.victory.connect(func() -> void: finish_run(true))


func begin_run() -> void:
	var scene := get_tree().current_scene
	_active = scene == null or not scene.scene_file_path.begins_with("res://tests/")
	_bosses = 0
	new_records = []


## Выход из забега без итога (в меню, «Заново» на паузе): время и убийства всё равно в счёт.
func abandon_run() -> void:
	finish_run(false, false)


func finish_run(victory: bool, ended := true) -> void:
	if not _active:
		return
	_active = false
	record(GameState.elapsed, GameState.level, GameState.kills, _bosses, victory, ended)
	save()


## Учесть забег: обновить итоги и рекорды, запомнить побитые рекорды.
func record(time: float, level: int, kills: int, bosses: int, victory: bool, ended := true) -> void:
	new_records = []
	_add(&"runs", 1)
	_add(&"time", time)
	_add(&"kills", kills)
	_add(&"bosses", bosses)
	_add(&"levels", level - 1)
	if victory:
		_add(&"wins", 1)
	elif ended:
		_add(&"deaths", 1)
	_best(&"best_time", time)
	_best(&"best_level", level)
	_best(&"best_kills", kills)
	_best(&"best_bosses", bosses)
	if victory:
		_best(&"fastest_win", time)


func format_value(id: StringName, value) -> String:
	if value == null:
		return "—"
	if id in TIME_KEYS:
		var total := int(value)
		var hours := total / 3600
		if hours > 0:
			return "%d ч %02d мин" % [hours, (total % 3600) / 60]
		return "%02d:%02d" % [total / 60, total % 60]
	return str(int(value))


func reset() -> void:
	records = {}
	totals = {}
	new_records = []
	save()


func save() -> void:
	var config := ConfigFile.new()
	for id in records:
		config.set_value("records", id, records[id])
	for id in totals:
		config.set_value("totals", id, totals[id])
	config.save(path)


func load_from(file: String) -> void:
	path = file
	records = {}
	totals = {}
	var config := ConfigFile.new()
	if config.load(file) != OK:
		return
	for id in RECORDS:
		if config.has_section_key("records", id):
			records[id] = config.get_value("records", id)
	for id in TOTALS:
		if config.has_section_key("totals", id):
			totals[id] = config.get_value("totals", id)


func _add(id: StringName, amount) -> void:
	totals[id] = totals.get(id, 0) + amount


func _best(id: StringName, value) -> void:
	var higher: bool = RECORDS[id][1]
	if not records.has(id) or (value > records[id] if higher else value < records[id]):
		# Нулевой результат рекордом не считаем (например, 0 боссов в первом забеге).
		if value > 0:
			if records.has(id):
				new_records.append(RECORDS[id][0])
			records[id] = value
