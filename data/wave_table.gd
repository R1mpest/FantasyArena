class_name WaveTable
extends Resource
## Таблица волн: по одному отрезку на минуту забега (после последнего действует последний)
## и время появления боссов.
## Отрезок: "enemies" — {id врага: вес}, "interval" — пауза между волнами, с,
## "batch" — сколько врагов в волне, "limit" — сколько врагов может быть на арене,
## "elite" — шанс, что враг появится элитным.

@export var minutes: Array[Dictionary] = []
## {"time": секунды забега, "enemy": id врага-босса}.
@export var bosses: Array[Dictionary] = []


func segment_at(minute: float) -> Dictionary:
	return minutes[clampi(int(minute), 0, minutes.size() - 1)]
