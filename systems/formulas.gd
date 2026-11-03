class_name Formulas
extends RefCounted
## Формулы баланса из ТЗ. Чистые функции, чтобы их было легко покрыть тестами.

## a = 6 вместо стартовых 5: замерами автопрогона подобрано под 35–40 повышений за 15 минут.
const XP_A := 6.0
const XP_P := 1.5
const XP_B := 10.0
const K_ALPHA := 0.04
## Квадратичный член: урон героя к поздней игре растёт мультипликативно (оружие × уровни ×
## предметы), и линейного роста здоровья врагов не хватало — с 8-й минуты враги таяли за секунды.
const K_BETA := 0.006
## Рост урона врагов (касание, выстрелы, взрывы): d(t) = 1 + γt, ×1,75 к 15-й минуте.
const DAMAGE_GAMMA := 0.05
const XP_ALPHA := 0.0
const XP_BETA := 0.0


## Опыт, нужный для перехода с уровня level на следующий: XP(L) = floor(a*L^p + b).
static func xp_to_next(level: int) -> int:
	return int(floor(XP_A * pow(level, XP_P) + XP_B))


## Множитель здоровья врагов от времени забега: k(t) = 1 + αt + βt² (×1,7 к 8-й минуте,
## ×2,95 к 15-й). Остальной рост сложности — пул врагов и плотность из таблицы волн.
static func difficulty(minutes: float) -> float:
	return 1.0 + K_ALPHA * minutes + K_BETA * minutes * minutes


## Множитель урона врагов от времени забега: d(t) = 1 + γt. На боссов не действует.
static func enemy_damage(minutes: float) -> float:
	return 1.0 + DAMAGE_GAMMA * minutes


## Множитель опыта с врага. Сейчас 1: темп повышений задаёт XP(L), а коэффициенты
## оставлены, чтобы подстроить рост опыта, если поздняя игра начнёт затягиваться.
static func xp_multiplier(minutes: float) -> float:
	return 1.0 + XP_ALPHA * minutes + XP_BETA * minutes * minutes


static func xp_drop(base_xp: int, minutes: float) -> int:
	return maxi(1, roundi(base_xp * xp_multiplier(minutes)))
