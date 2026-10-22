class_name PhoenixEffect
extends ItemEffect
## «Перо феникса»: одно воскрешение за забег с 50% ОЗ. Ур. 2 — взрыв вокруг,
## ур. 3 — ещё и неуязвимость. После срабатывания слот остаётся занят, перо не качается.

const BLAST_DAMAGE := 80.0
const BLAST_RADIUS := 80.0
const BLAST_FORCE := 260.0


## Возвращает true, если герой воскрешён (перо ещё не сработало).
func try_revive() -> bool:
	if player.spent_items.has(data.id):
		return false
	player.spent_items[data.id] = true
	player.hp = player.max_hp * 0.5
	var center := player.global_position + Vector2(0, -8)
	if params.get("blast", false):
		var blast := Blast.new()
		blast.damage = BLAST_DAMAGE * player.damage_mult()
		blast.radius = BLAST_RADIUS
		blast.color = Color(1.0, 0.65, 0.25)
		blast.source = data.id
		blast.position = center
		player.projectile_root.add_child.call_deferred(blast)
		for enemy in Enemy.in_radius(get_tree(), center, BLAST_RADIUS):
			enemy.push(center.direction_to(enemy.center()) * BLAST_FORCE)
	var invulnerable := float(params.get("invulnerable", 0.0))
	# Хотя бы короткая неуязвимость, чтобы не умереть в тот же кадр.
	player.invulnerable_until = GameState.elapsed + maxf(invulnerable, 0.5)
	return true
