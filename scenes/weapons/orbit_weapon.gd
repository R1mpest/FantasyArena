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
var _sprites: Array[Sprite2D] = []


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


func _process(_delta: float) -> void:
	var offsets := _orb_offsets()
	while _sprites.size() < offsets.size():
		var sprite := Sprite2D.new()
		sprite.texture = SpriteLib.pack("projectiles/orb")
		add_child(sprite)
		_sprites.append(sprite)
	# Кадр спрайта 16 px, сфера в нём около 10 px — подгоняем под радиус удара.
	var scale_to_radius := _orb_radius() * 2.0 / 10.0
	for i in _sprites.size():
		_sprites[i].visible = i < offsets.size()
		if i < offsets.size():
			_sprites[i].position = offsets[i]
			_sprites[i].scale = Vector2.ONE * scale_to_radius


func _draw() -> void:
	var radius := _orb_radius()
	for offset in _orb_offsets():
		draw_circle(offset, radius * 1.6, Color(0.6, 0.4, 1.0, 0.15))


func _orb_radius() -> float:
	return 5.0 * orb_size * area()


func _orb_offsets() -> Array[Vector2]:
	var result: Array[Vector2] = []
	var count := int(orb_count) + extra_projectiles()
	var distance := (26.0 + 8.0 * orb_size) * area()
	for i in count:
		result.append(Vector2.from_angle(_angle + TAU * i / count) * distance)
	return result
