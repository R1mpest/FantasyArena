extends Node
## Снимок любой сцены для проверки картинки (нужен экран, не headless):
## godot --path . res://tests/screenshot.tscn -- --scene=res://scenes/main/main_menu.tscn --out=menu.png

func _ready() -> void:
	var scene := ""
	var out := "screenshot.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene = arg.get_slice("=", 1)
		elif arg.begins_with("--out="):
			out = arg.get_slice("=", 1)
	add_child(load(scene).instantiate())
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("SCREENSHOT ", out)
	get_tree().quit()
