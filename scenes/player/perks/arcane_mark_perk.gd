class_name ArcaneMarkPerk
extends Perk
## «Арканная метка»: враг, задетый 3 разными видами оружия за 2 с, получает больше урона 4 с.
## Учёт попаданий ведёт сам Enemy, навык задаёт силу метки и распространение на 3-м уровне.


func _on_level_changed() -> void:
	player.arcane_bonus = float(params.get("bonus", 0.2))
	player.arcane_spread = bool(params.get("spread", false))
