class_name Tutorial extends Control

const tutorial_scene := preload("res://src/tutorial.tscn")

var audio: Audio
var tutorial_combat: Combat

signal tutorial_completed()

static func create_tutorial(init_audio: Audio) -> Tutorial:
	var tutorial: Tutorial = tutorial_scene.instantiate()
	tutorial.audio = init_audio
	return tutorial

func _ready() -> void:
	var tutorial_deck := Deck.create_deck()
	tutorial_deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_deck.get_node("GridContainer").hide()
	add_child(tutorial_deck)

	var run_camera: Camera3D = load("res://src/run.tscn").instantiate().get_node("Camera3D").duplicate()
	add_child(run_camera)

	var new_combat: Combat = Combat.create_combat(tutorial_deck, 0, audio, [], 0, true)
	tutorial_combat = new_combat
	new_combat.combat_over.connect(_on_tutorial_combat_over)
	new_combat.set_help_text("Welcome to the forest!\n\nYou can drag cards into the play area to play them.\n\nTry it now!")
	new_combat.spawned_unit.connect(_on_tutorial_combat_spawned_unit)
	new_combat.middle_torch_lit.connect(_on_middle_torch_lit)
	add_child(new_combat)


func _on_tutorial_combat_over(_state: Combat.CombatState) -> void:
	tutorial_combat.set_help_text("Great job! You've completed the tutorial.\nYou're ready to venture into the forest.\n\nGood luck!")
	(tutorial_combat.get_node("TutorialMenuButton") as Button).pressed.connect(tutorial_completed.emit)
	(tutorial_combat.get_node("TutorialMenuButton") as Button).show()


func _on_tutorial_combat_spawned_unit() -> void:
	tutorial_combat.spawned_unit.disconnect(_on_tutorial_combat_spawned_unit)
	tutorial_combat.set_help_text("Great job, you've spawned a unit!\n\nIn order to progress in the combat, you must light the torches to defeat the darkness.\nYour units will only move up to the next unlit torch.\nOnly Torchlighters [img=60]res://textures/card/torch.png[/img] can light torches.\n\nTry to play one.")


func _on_middle_torch_lit(_torch_ndx: int) -> void:
	tutorial_combat.set_help_text("Well done! You've lit a torch.\n\nThe first time you light a torch in a combat, you'll get a secret added to your hand which doesn't count towards your hand size.\nSecrets are powerful cards that which help you in combat, and only exist for this combat. They can only be played once.\n\nTry playing the secret you just got.")
