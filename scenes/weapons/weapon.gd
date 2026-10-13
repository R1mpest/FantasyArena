class_name Weapon
extends Node2D
## Оружие, которое игрок получает картой прокачки. Статы — float и меняются через UpgradeData.

var player: Player


func apply_upgrade(upgrade: UpgradeData) -> void:
	upgrade.apply_to(self)
