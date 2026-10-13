class_name UiKit
extends RefCounted
## Помощники для интерфейса, который собирается из кода.


static func label(text: String = "", size: int = 10, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = align
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override(&"font_size", size)
	result.add_theme_constant_override(&"outline_size", 4)
	result.add_theme_color_override(&"font_outline_color", Color.BLACK)
	return result


static func bar(fill: Color) -> ProgressBar:
	var result := ProgressBar.new()
	result.show_percentage = false
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.6)
	background.set_border_width_all(1)
	background.border_color = Color.BLACK
	var foreground := StyleBoxFlat.new()
	foreground.bg_color = fill
	result.add_theme_stylebox_override(&"background", background)
	result.add_theme_stylebox_override(&"fill", foreground)
	return result


static func button(text: String) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(240, 34)
	result.alignment = HORIZONTAL_ALIGNMENT_LEFT
	result.add_theme_font_size_override(&"font_size", 10)
	return result


## Затемнение на весь экран с панелью по центру. Возвращает [фон, контейнер панели].
static func modal() -> Array:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.16)
	style.set_border_width_all(1)
	style.border_color = Color(0.55, 0.45, 0.65)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override(&"panel", style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	panel.add_child(box)
	return [dim, box]
