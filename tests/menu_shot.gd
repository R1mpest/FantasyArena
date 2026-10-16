extends Node
## Скриншот главного меню для записки: godot --path . res://tests/menu_shot.tscn -- --screenshot=menu.png
## С ключом --settings снимок открытого окна настроек.

func _ready() -> void:
	var menu: Node = load("res://scenes/main/main_menu.tscn").instantiate()
	add_child(menu)
	if "--settings" in OS.get_cmdline_user_args():
		menu._open_settings()
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			get_viewport().get_texture().get_image().save_png(arg.get_slice("=", 1))
	get_tree().quit()
