class_name Menu extends Control


func _on_play_pressed() -> void:
	var run: Run = load("res://src/run.tscn").instantiate()
	add_sibling(run)
	queue_free()


func _on_settings_pressed() -> void:
	print("Settings")

func _on_how_to_play_pressed() -> void:
	print("How to play")
