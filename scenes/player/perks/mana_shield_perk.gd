class_name ManaShieldPerk
extends Perk
## «Мана-щит»: щит поглощает урон раньше здоровья и полностью восстанавливается,
## если restore секунд не было попаданий. На 3-м уровне при разрушении отбрасывает врагов.

const KNOCKBACK_RADIUS := 64.0
const KNOCKBACK_FORCE := 240.0
const BUBBLE_RADIUS := 13.0

var _burst := 0.0
var _bubble: AnimatedSprite2D


func _ready() -> void:
	z_index = 1
	_bubble = SpriteLib.strip_sprite("res://assets/sprites/spells/shield.png", 8.0)
	_bubble.position = Vector2(0, -10)
	# Кадр 48 px, пузырь — под радиус BUBBLE_RADIUS.
	_bubble.scale = Vector2.ONE * BUBBLE_RADIUS * 2.0 / 40.0
	add_child(_bubble)
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
	_bubble.visible = player.shield > 0.0
	if player.shield > 0.0:
		_bubble.modulate.a = 0.2 + 0.3 * player.shield / player.shield_max
	if _burst > 0.0:
		var radius := lerpf(BUBBLE_RADIUS, KNOCKBACK_RADIUS, 1.0 - _burst)
		draw_arc(center, radius, 0.0, TAU, 48, Color(0.6, 0.85, 1.0, _burst), 2.0)
