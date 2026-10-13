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
