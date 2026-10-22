class_name MagnetCrystal
extends Node2D
## Кристалл-магнит: подобранный, притягивает к герою весь опыт, что лежит на полу.

const TEXTURE := preload("res://assets/sprites/kyrise/crystal_01c.png")
const LIFETIME := 60.0

var _player: Player
var _attracted := false
var _speed := 0.0
var _time := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as Player
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	_sprite.position.y = sin(_time * 4.0) * 2.0
	queue_redraw()
	if _time > LIFETIME:
		queue_free()
		return
	if _player == null or _player.dead:
		return
	var target := _player.global_position + Vector2(0, -8)
	if not _attracted and global_position.distance_to(target) <= _player.pickup_radius:
		_attracted = true
	if not _attracted:
		return
	_speed = minf(_speed + 500.0 * delta, 450.0)
	global_position = global_position.move_toward(target, _speed * delta)
	if global_position.distance_to(target) < 4.0:
		collect()


func collect() -> void:
	for gem in get_tree().get_nodes_in_group(&"xp_gems"):
		(gem as XpGem).attract()
	queue_free()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)
	draw_circle(Vector2(0, 6), 5.0, Color(0, 0, 0, 0.25))
	draw_circle(_sprite.position, 9.0 + pulse * 2.0, Color(0.4, 0.75, 1.0, 0.15 + 0.1 * pulse))
