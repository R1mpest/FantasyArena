class_name ManaShieldPerk
extends Perk
## «Мана-щит»: щит поглощает урон раньше здоровья и полностью восстанавливается,
## если restore секунд не было попаданий. На 3-м уровне при разрушении отбрасывает врагов.

const KNOCKBACK_RADIUS := 64.0
const KNOCKBACK_FORCE := 240.0
const BUBBLE_RADIUS := 13.0

var _burst := 0.0


func _ready() -> void:
	z_index = 1
	player.shield_broken.connect(_on_shield_broken)


func _on_level_changed() -> void:
	player.shield_max = float(params.get("capacity", 15.0))
	player.shield = player.shield_max


func _physics_process(delta: float) -> void:
	_burst = maxf(0.0, _burst - delta * 3.0)
	queue_redraw()
	if player.dead or player.shield >= player.shield_max:
		return
	if GameState.elapsed - player.last_hit_time >= float(params.get("restore", 6.0)):
		player.shield = player.shield_max


func _on_shield_broken() -> void:
	if not params.get("knockback", false):
		return
	_burst = 1.0
	var center := player.global_position + Vector2(0, -8)
	for enemy in Enemy.in_radius(get_tree(), center, KNOCKBACK_RADIUS):
		enemy.push(center.direction_to(enemy.center()) * KNOCKBACK_FORCE)


func _draw() -> void:
	var center := Vector2(0, -10)
	if player.shield > 0.0:
		var fill := player.shield / player.shield_max
		draw_circle(center, BUBBLE_RADIUS, Color(0.4, 0.75, 1.0, 0.08 + 0.1 * fill))
		draw_arc(center, BUBBLE_RADIUS, 0.0, TAU, 32, Color(0.6, 0.85, 1.0, 0.35 + 0.45 * fill), 1.0)
	if _burst > 0.0:
		var radius := lerpf(BUBBLE_RADIUS, KNOCKBACK_RADIUS, 1.0 - _burst)
		draw_arc(center, radius, 0.0, TAU, 48, Color(0.6, 0.85, 1.0, _burst), 2.0)
