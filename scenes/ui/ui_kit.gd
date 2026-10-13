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


static func button(text: String, width: float = 160.0) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(width, 26)
	result.add_theme_font_size_override(&"font_size", 12)
	result.add_theme_constant_override(&"outline_size", 4)
	result.add_theme_color_override(&"font_outline_color", Color.BLACK)
	var normal := box(Color(0.2, 0.15, 0.26), Color(0.45, 0.35, 0.55))
	var hover := box(Color(0.3, 0.22, 0.38), Color(0.95, 0.75, 0.3))
	result.add_theme_stylebox_override(&"normal", normal)
	result.add_theme_stylebox_override(&"hover", hover)
	result.add_theme_stylebox_override(&"focus", hover)
	result.add_theme_stylebox_override(&"pressed", box(Color(0.14, 0.1, 0.18), Color(0.95, 0.75, 0.3)))
	return result


static func box(background: Color, border: Color, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	return style


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
