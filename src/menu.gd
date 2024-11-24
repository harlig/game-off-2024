class_name Menu extends Control


var tutorial_combat: Combat
var tutorial_deck: Deck
var tutorial_camera: Camera3D

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

	tutorial_deck = Deck.create_deck()
	tutorial_deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_deck.get_node("GridContainer").hide()
	add_sibling(tutorial_deck)

	var run_camera: Camera3D = load("res://src/run.tscn").instantiate().get_node("Camera3D").duplicate()
	tutorial_camera = run_camera
	add_sibling(run_camera)

	var new_combat: Combat = Combat.create_combat(tutorial_deck, 0, $Audio, [], 0, true)
	tutorial_combat = new_combat
	new_combat.combat_over.connect(_on_tutorial_combat_over)
	add_sibling(new_combat)
	hide()


func _on_tutorial_combat_over(_state: Combat.CombatState) -> void:
	show()
	tutorial_combat.queue_free()
	tutorial_deck.queue_free()
