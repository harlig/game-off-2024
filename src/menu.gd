class_name Menu extends Control


var tutorial_combat: Combat

func _on_play_pressed() -> void:
	var run: Run = load("res://src/run.tscn").instantiate()
	add_sibling(run)
	queue_free()


func _on_settings_pressed() -> void:
	print("Settings")

func _on_how_to_play_pressed() -> void:
	# create combat, add it as a sibling, and remove the menu
	# on combat end, it should remove itself and add the menu back
	print("How to play")
	var new_combat: Combat = Combat.create_combat(null, 0, $Audio, [], 0, true)
	tutorial_combat = new_combat
	new_combat.combat_over.connect(_on_tutorial_combat_over)
	add_sibling(new_combat)
	hide()


func _on_tutorial_combat_over() -> void:
	show()
	tutorial_combat.queue_free()
