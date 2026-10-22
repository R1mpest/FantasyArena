extends Node
## Снимок карт прокачки с самыми длинными текстами — проверка, что текст помещается.
## godot --path . res://tests/cards_shot.tscn -- --screenshot=cards.png

const IDS := [&"cursed_skull", &"frost_bell", &"anchor", &"storm_boots"]


func _ready() -> void:
	var run: Node2D = load("res://scenes/main/run.tscn").instantiate()
	add_child(run)
	var system: UpgradeSystem = run.upgrade_system
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.08)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	row.position = Vector2(8, 80)
	layer.add_child(row)
	for i in IDS.size():
		for kind in [CardOffer.Kind.WEAPON, CardOffer.Kind.ITEM]:
			for data: Resource in system._all(kind):
				if data.id == IDS[i]:
					var card := UpgradeCard.new()
					card.setup(system._offer(kind, data), i + 1)
					row.add_child(card)
	get_tree().paused = true
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			get_viewport().get_texture().get_image().save_png(arg.get_slice("=", 1))
	get_tree().quit()
