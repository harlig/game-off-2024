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
	new_combat.set_help_text("Welcome to the forest!\nYou can drag cards into the play area to play them. Try it now!")
	new_combat.spawned_unit.connect(_on_tutorial_combat_spawned_unit)
	new_combat.middle_torch_lit.connect(_on_middle_torch_lit)
	add_sibling(new_combat)
	hide()


func _on_tutorial_combat_over(_state: Combat.CombatState) -> void:
	tutorial_combat.set_help_text("Great job! You've completed the tutorial.\nYou're ready to venture into the forest.\nGood luck!")
	(tutorial_combat.get_node("TutorialMenuButton") as Button).pressed.connect(_on_tutorial_menu_button_pressed)
	(tutorial_combat.get_node("TutorialMenuButton") as Button).show()

func _on_tutorial_menu_button_pressed() -> void:
	show()
	tutorial_combat.queue_free()
	tutorial_deck.queue_free()


func _on_tutorial_combat_spawned_unit() -> void:
	tutorial_combat.spawned_unit.disconnect(_on_tutorial_combat_spawned_unit)
	tutorial_combat.set_help_text("Great job, you've spawned a unit!\nIn order to progress in the combat, you must light the torches to defeat the darkness.\nOnly Torchlighters can light torches. Try to play one.")


func _on_middle_torch_lit(_torch_ndx: int) -> void:
	tutorial_combat.set_help_text("Well done! You've lit a torch.\nThe first time you light a torch in a combat, you'll get a secret added to your hand. Secrets are powerful cards which can help you in combat.\nTry playing the secret you just got.")
