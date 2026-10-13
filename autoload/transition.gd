extends CanvasLayer
## Плавная смена сцен через затемнение экрана.

const MENU_SCENE := "res://scenes/main/main_menu.tscn"
const RUN_SCENE := "res://scenes/main/run.tscn"

var _curtain: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_curtain = ColorRect.new()
	_curtain.color = Color(0.05, 0.03, 0.08, 0.0)
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_curtain)


func change_scene(path: String) -> void:
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_out := create_tween()
	fade_out.tween_property(_curtain, "color:a", 1.0, 0.25)
	await fade_out.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	var fade_in := create_tween()
	fade_in.tween_property(_curtain, "color:a", 0.0, 0.25)
	await fade_in.finished
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
