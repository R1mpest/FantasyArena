extends Node
## Состояние текущего забега: таймер, уровень, убийства.

var elapsed: float = 0.0
var kills: int = 0
var level: int = 1
var running: bool = false


func _ready() -> void:
	EventBus.enemy_died.connect(func(_pos: Vector2, _xp: int) -> void: kills += 1)
	EventBus.level_up.connect(func(new_level: int) -> void: level = new_level)
	EventBus.player_died.connect(func() -> void: running = false)
	EventBus.victory.connect(func() -> void: running = false)


func _process(delta: float) -> void:
	if running:
		elapsed += delta


func reset() -> void:
	elapsed = 0.0
	kills = 0
	level = 1
	running = true


func minutes() -> float:
	return elapsed / 60.0


func format_time() -> String:
	var total := int(elapsed)
	return "%02d:%02d" % [int(total / 60.0), total % 60]
