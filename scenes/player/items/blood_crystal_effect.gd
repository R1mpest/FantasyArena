class_name BloodCrystalEffect
extends ItemEffect
## «Кровавый кристалл»: каждое убийство лечит. Обычное лечение и регенерацию
## отключает сам Player (healing_blocked), поэтому здесь здоровье добавляется напрямую.


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(_at: Vector2, _xp: int) -> void:
	if not player.dead:
		player.hp = minf(player.hp + float(params.get("heal_per_kill", 0.5)), player.max_hp)
