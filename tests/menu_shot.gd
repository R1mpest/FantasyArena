extends Node
## Скриншот главного меню для записки: godot --path . res://tests/menu_shot.tscn -- --screenshot=menu.png
## С ключом --settings снимок открытого окна настроек, --stats — окна статистики,
## с --herald=N — легат в кадре N (0..3).

func _ready() -> void:
	var menu: Node = load("res://scenes/main/main_menu.tscn").instantiate()
	add_child(menu)
	if "--settings" in OS.get_cmdline_user_args():
		menu._open_settings()
	if "--demo-stats" in OS.get_cmdline_user_args():
		# Пример для иллюстрации в отчёте: в памяти, без записи в файл.
		Stats.records = {&"best_time": 938.0, &"best_level": 40, &"best_kills": 8967, &"best_bosses": 3, &"fastest_win": 938.0}
		Stats.totals = {&"runs": 12, &"wins": 2, &"deaths": 8, &"kills": 41230, &"bosses": 14, &"levels": 302, &"time": 8215.0}
	if "--stats" in OS.get_cmdline_user_args():
		menu._toggle_stats(true)
	if "--help" in OS.get_cmdline_user_args():
		menu._toggle_help(true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--herald="):
			menu._arena.herald_show(int(arg.get_slice("=", 1)))
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			get_viewport().get_texture().get_image().save_png(arg.get_slice("=", 1))
	get_tree().quit()
