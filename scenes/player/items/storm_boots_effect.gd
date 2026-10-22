class_name StormBootsEffect
extends ItemEffect
## «Сапоги бури»: каждые step пикселей пройденного пути — молния в ближайшего врага.

const STRIKE_RANGE := 160.0

var _travelled := 0.0
var _last_position := Vector2.ZERO


func _ready() -> void:
	_last_position = player.global_position


func _physics_process(_delta: float) -> void:
	var moved := player.global_position.distance_to(_last_position)
	_last_position = player.global_position
	if player.dead:
		return
	_travelled += moved
	var step := float(params.get("step", 120.0))
	while _travelled >= step:
		_travelled -= step
		_strike()


func _strike() -> void:
	var origin := player.global_position + Vector2(0, -10)
	var best: Enemy = null
	var best_distance := INF
	for enemy in Enemy.in_radius(get_tree(), origin, STRIKE_RANGE * player.area()):
		var distance := origin.distance_squared_to(enemy.center())
		if distance < best_distance:
			best = enemy
			best_distance = distance
	if best == null:
		return
	best.take_damage(float(params.get("damage", 25.0)) * player.damage_mult(), origin.direction_to(best.center()), data.id)
	var bolt := LightningFx.new()
	bolt.from = origin
	bolt.to = best.center()
	player.projectile_root.add_child(bolt)
