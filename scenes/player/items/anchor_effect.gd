class_name AnchorEffect
extends ItemEffect
## «Якорь»: если стоять на месте дольше 2 с — больше урона и меньше получаемого.
## Скорость бега −10% даёт модификатор предмета, любое движение сбрасывает таймер.

const STILL_TIME := 2.0

var _still := 0.0


func _ready() -> void:
	z_index = -1


func is_active() -> bool:
	return _still >= STILL_TIME


func _physics_process(delta: float) -> void:
	_still = _still + delta if player.velocity.length_squared() < 1.0 and not player.dead else 0.0
	player.temp_might = float(params.get("anchor_might", 1.25)) if is_active() else 1.0
	player.temp_damage_taken = float(params.get("anchor_guard", 0.8)) if is_active() else 1.0
	queue_redraw()


func _draw() -> void:
	if _still <= 0.0:
		return
	var progress := minf(_still / STILL_TIME, 1.0)
	var color := Color(1.0, 0.8, 0.3, 0.8) if is_active() else Color(0.8, 0.75, 0.6, 0.4)
	draw_arc(Vector2.ZERO, 12.0, -PI / 2.0, -PI / 2.0 + TAU * progress, 32, color, 1.5)
