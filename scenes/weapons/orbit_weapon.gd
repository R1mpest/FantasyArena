class_name OrbitWeapon
extends Weapon
## «Магические сферы»: сферы вращаются вокруг героя и бьют задетых врагов.
## Размер и орбита растут от Линзы, вращение — от Песочных часов, число сфер — от Колчана.

## Один и тот же враг получает урон от сфер не чаще раза в столько секунд.
const HIT_COOLDOWN := 0.45
const KNOCKBACK_FORCE := 130.0

var damage := 12.0
var orb_size := 1.0
var rotation_speed := 2.6
var orb_count := 2.0
var knockback := false

var _angle := 0.0
## instance_id врага -> время забега, когда его снова можно ударить.
var _next_hit: Dictionary = {}


func _ready() -> void:
	z_index = 1


func _physics_process(delta: float) -> void:
	# Ускорение перезарядки у сфер превращается в скорость вращения.
	_angle = wrapf(_angle + rotation_speed / player.cooldown_factor() * delta, 0.0, TAU)
	queue_redraw()
	if player.dead:
		return
	var now := GameState.elapsed
	for offset in _orb_offsets():
		for enemy in Enemy.in_radius(get_tree(), global_position + offset, _orb_radius()):
			var id := enemy.get_instance_id()
			if _next_hit.get(id, 0.0) > now:
				continue
			_next_hit[id] = now + HIT_COOLDOWN
			enemy.take_damage(damage_of(damage), offset.normalized(), data.id)
			if knockback:
				enemy.push(offset.normalized() * KNOCKBACK_FORCE)
	if _next_hit.size() > 500:
		for id in _next_hit.keys():
			if _next_hit[id] < now:
				_next_hit.erase(id)


func _draw() -> void:
	var radius := _orb_radius()
	for offset in _orb_offsets():
		draw_circle(offset, radius * 1.7, Color(0.35, 0.8, 1.0, 0.18))
		draw_circle(offset, radius, Color(0.4, 0.85, 1.0))
		draw_circle(offset + Vector2(-radius, -radius) * 0.25, radius * 0.45, Color(0.9, 0.98, 1.0))


func _orb_radius() -> float:
	return 5.0 * orb_size * area()


func _orb_offsets() -> Array[Vector2]:
	var result: Array[Vector2] = []
	var count := int(orb_count) + extra_projectiles()
	var distance := (26.0 + 8.0 * orb_size) * area()
	for i in count:
		result.append(Vector2.from_angle(_angle + TAU * i / count) * distance)
	return result
