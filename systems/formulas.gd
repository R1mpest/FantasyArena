class_name Formulas
extends RefCounted
## Формулы баланса из ТЗ. Чистые функции, чтобы их было легко покрыть тестами.

const XP_A := 5.0
const XP_P := 1.5
const XP_B := 10.0
const K_ALPHA := 0.08
const K_BETA := 0.004


## Опыт, нужный для перехода с уровня level на следующий: XP(L) = floor(a*L^p + b).
static func xp_to_next(level: int) -> int:
	return int(floor(XP_A * pow(level, XP_P) + XP_B))


## Множитель силы врагов от времени забега в минутах: k(t) = 1 + αt + βt².
static func difficulty(minutes: float) -> float:
	return 1.0 + K_ALPHA * minutes + K_BETA * minutes * minutes


## Пауза между волнами спавна, секунды.
static func spawn_interval(minutes: float) -> float:
	return maxf(0.35, 1.0 - 0.05 * minutes)


## Сколько врагов появляется за одну волну.
static func spawn_batch(minutes: float) -> int:
	return 1 + int(minutes * 0.6)
