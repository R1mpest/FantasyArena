extends Node
## Глобальные сигналы игры. Системы не вызывают друг друга напрямую,
## а шлют и слушают события здесь.

@warning_ignore("unused_signal")
signal enemy_died(position: Vector2, xp: int)
@warning_ignore("unused_signal")
signal xp_collected(amount: int)
@warning_ignore("unused_signal")
signal level_up(level: int)
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal boss_incoming(title: String)
@warning_ignore("unused_signal")
signal boss_spawned(boss: Node2D)
@warning_ignore("unused_signal")
signal boss_defeated(boss: Node2D, final: bool)
@warning_ignore("unused_signal")
signal victory
