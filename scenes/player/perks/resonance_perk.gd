class_name ResonancePerk
extends Perk
## «Резонанс»: каждый N-й магический снаряд взрывается при попадании.
## Сам счёт снарядов ведёт AutoWeapon, навык только задаёт N и радиус.


func _on_level_changed() -> void:
	player.resonance_every = int(params.get("every", 6))
	player.resonance_radius = float(params.get("radius", 24.0))
