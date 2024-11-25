class_name Menu extends Control

@onready var audio: Audio = $Audio
var tutorial_combat: Combat
var tutorial_deck: Deck
var tutorial_camera: Camera3D


func _ready() -> void:
	_on_volume_slider_value_changed($Settings/VolumeSlider.value)


func _on_play_pressed() -> void:
	var run: Run = load("res://src/run.tscn").instantiate()
	run.main_menu = self
	remove_child(audio)
	run.add_child(audio)
	add_sibling(run)
	hide()


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
	new_combat.set_help_text("Welcome to the forest!\n\nYou can drag cards into the play area to play them.\n\nTry it now!")
	new_combat.spawned_unit.connect(_on_tutorial_combat_spawned_unit)
	new_combat.middle_torch_lit.connect(_on_middle_torch_lit)
	add_sibling(new_combat)
	hide()


func _on_tutorial_combat_over(_state: Combat.CombatState) -> void:
	tutorial_combat.set_help_text("Great job! You've completed the tutorial.\nYou're ready to venture into the forest.\n\nGood luck!")
	(tutorial_combat.get_node("TutorialMenuButton") as Button).pressed.connect(_on_tutorial_menu_button_pressed)
	(tutorial_combat.get_node("TutorialMenuButton") as Button).show()

func _on_tutorial_menu_button_pressed() -> void:
	show()
	tutorial_combat.queue_free()
	tutorial_deck.queue_free()


func _on_tutorial_combat_spawned_unit() -> void:
	tutorial_combat.spawned_unit.disconnect(_on_tutorial_combat_spawned_unit)
	tutorial_combat.set_help_text("Great job, you've spawned a unit!\n\nIn order to progress in the combat, you must light the torches to defeat the darkness.\nYour units will only move up to the next unlit torch.\nOnly Torchlighters can light torches.\n\nTry to play one.")


func _on_middle_torch_lit(_torch_ndx: int) -> void:
	tutorial_combat.set_help_text("Well done! You've lit a torch.\n\nThe first time you light a torch in a combat, you'll get a secret added to your hand which doesn't count towards your hand size.\nSecrets are powerful cards that which help you in combat, and only exist for this combat. They can only be played once.\n\nTry playing the secret you just got.")


func _on_settings_pressed() -> void:
	$Title.hide()
	$Buttons.hide()
	$Settings.show()


func _on_volume_slider_value_changed(value: float) -> void:
	for child: AudioStreamPlayer in audio.get_children():
		child.volume_db = -30.0 + value / 5.0
		if value == 0.0:
			child.volume_db = -100.0;


func _on_back_button_pressed() -> void:
	$Title.show()
	$Buttons.show()
	$Settings.hide()
