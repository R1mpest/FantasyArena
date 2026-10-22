class_name Boss
extends Enemy
## Босс: своё поведение и опасные атаки с метками на земле (telegraph), полоса здоровья
## сверху экрана. Убийство финального босса — победа.

const CATCH_UP_DISTANCE := 420.0

## Спавнер — чтобы призывать врагов.
var spawner: EnemySpawner
var final := false

## Метки атак: {kind, at, to, radius, width, time, total, color, on_done}. Координаты глобальные.
var _telegraphs: Array[Dictionary] = []


func _ready() -> void:
	super._ready()
	add_to_group(&"bosses")
	EventBus.boss_spawned.emit(self)


func _physics_process(delta: float) -> void:
	_tick_flash(delta)
	_tick_status(delta)
	_update_telegraphs(delta)
	queue_redraw()
	var player := hero()
	if player == null or player.dead:
		return
	# Босс не отстаёт: если герой убежал слишком далеко, появляется ближе.
	if global_position.distance_to(player.global_position) > CATCH_UP_DISTANCE:
		global_position = player.global_position + Vector2.from_angle(randf() * TAU) * CATCH_UP_DISTANCE * 0.5
	_boss_process(delta)


## Поведение конкретного босса.
func _boss_process(_delta: float) -> void:
	pass


func hero() -> Player:
	return target as Player


func hero_center() -> Vector2:
	return target.global_position + Vector2(0, -8)


func hits_hero(at: Vector2, radius: float) -> bool:
	return hero_center().distance_to(at) <= radius + 5.0


func walk_toward(point: Vector2, delta: float, speed_mult: float = 1.0) -> void:
	var direction := global_position.direction_to(point)
	velocity = direction * data.speed * speed_mult * (1.0 - _slow)
	global_position += velocity * delta
	_sprite.flip_h = direction.x < 0.0


func telegraph_circle(at: Vector2, radius: float, time: float, color: Color, on_done: Callable = Callable()) -> void:
	_telegraphs.append({"kind": "circle", "at": at, "radius": radius, "time": time, "total": time, "color": color, "on_done": on_done})


func telegraph_line(from: Vector2, direction: Vector2, length: float, width: float, time: float, color: Color) -> void:
	_telegraphs.append({"kind": "line", "at": from, "to": from + direction * length, "width": width, "time": time, "total": time, "color": color, "on_done": Callable()})


func shoot(direction: Vector2, speed: float, damage_amount: float, color: Color) -> void:
	var shot := EnemyProjectile.new()
	shot.position = center()
	shot.velocity = direction * speed
	shot.damage = damage_amount
	shot.color = color
	get_parent().add_child(shot)


## Призыв врагов кольцом вокруг босса.
func summon(id: StringName, count: int, radius: float) -> void:
	var type := spawner.type_of(id) if spawner != null else null
	if type == null:
		return
	for i in count:
		spawner._spawn(type, GameState.minutes(), false, global_position + Vector2.from_angle(TAU * i / count) * radius)


## Взрыв-вспышка без урона по врагам (урон герою наносит сам босс).
func flash_blast(at: Vector2, radius: float, color: Color) -> void:
	var blast := Blast.new()
	blast.damage = 0.0
	blast.radius = radius
	blast.color = color
	blast.position = at
	get_parent().add_child(blast)


func _update_telegraphs(delta: float) -> void:
	for telegraph in _telegraphs.duplicate():
		telegraph["time"] -= delta
		if telegraph["time"] <= 0.0:
			_telegraphs.erase(telegraph)
			var on_done: Callable = telegraph["on_done"]
			if on_done.is_valid():
				on_done.call()


func _on_death() -> void:
	EventBus.boss_defeated.emit(self, final)
	if final:
		EventBus.victory.emit()


func _draw() -> void:
	super._draw()
	# Рисуем в локальных координатах босса, а он увеличен — переводим обратно.
	var to_local := func(point: Vector2) -> Vector2: return (point - global_position) / scale.x
	for telegraph in _telegraphs:
		var progress: float = 1.0 - telegraph["time"] / telegraph["total"]
		var color: Color = telegraph["color"]
		if telegraph["kind"] == "circle":
			var at: Vector2 = to_local.call(telegraph["at"])
			var radius: float = telegraph["radius"] / scale.x
			draw_circle(at, radius, Color(color, 0.12 + 0.18 * progress))
			draw_arc(at, radius * progress, 0.0, TAU, 40, Color(color, 0.8), 1.0 / scale.x)
			draw_arc(at, radius, 0.0, TAU, 40, Color(color, 0.9), 1.0 / scale.x)
		else:
			draw_line(to_local.call(telegraph["at"]), to_local.call(telegraph["to"]), Color(color, 0.15 + 0.25 * progress), telegraph["width"] / scale.x)
