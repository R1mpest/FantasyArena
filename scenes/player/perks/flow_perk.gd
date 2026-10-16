class_name FlowPerk
extends Perk
## «Поток»: каждое убийство даёт +per_kill к скорости атаки на duration секунд, но не больше cap.
## Урон по здоровью сбрасывает весь бонус (урон, поглощённый щитом, не считается).

## Время забега, когда истекает каждый заряд; старые в начале.
var _stacks: Array[float] = []


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	player.hp_lost.connect(_on_hp_lost)


func bonus() -> float:
	return minf(_stacks.size() * float(params.get("per_kill", 0.02)), float(params.get("cap", 0.2)))


func _physics_process(_delta: float) -> void:
	var now := GameState.elapsed
	while not _stacks.is_empty() and _stacks[0] <= now:
		_stacks.pop_front()
	player.attack_speed_bonus = bonus()


func _on_enemy_died(_at: Vector2, _xp: int) -> void:
	if player.dead:
		return
	_stacks.append(GameState.elapsed + float(params.get("duration", 3.0)))
	# Заряды сверх предела бесполезны — держим только самые свежие.
	var max_stacks := ceili(float(params.get("cap", 0.2)) / float(params.get("per_kill", 0.02)))
	while _stacks.size() > max_stacks:
		_stacks.pop_front()
	player.attack_speed_bonus = bonus()


func _on_hp_lost(_amount: float) -> void:
	_stacks.clear()
	player.attack_speed_bonus = 0.0
