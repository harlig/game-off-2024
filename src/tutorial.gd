class_name Tutorial extends Control

const tutorial_scene := preload("res://src/tutorial.tscn")
const highlight_scene := preload("res://src/highlight.tscn")

@onready var continue_button: Button = $ContinueButton

var audio: Audio
var tutorial_combat: Combat
var tutorial_combat_hand_display: HandDisplay

signal tutorial_completed()

static func create_tutorial(init_audio: Audio) -> Tutorial:
	var tutorial: Tutorial = tutorial_scene.instantiate()
	tutorial.audio = init_audio
	return tutorial

func _ready() -> void:
	$Settings.audio = audio

	var tutorial_deck := Deck.create_deck()
	tutorial_deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_deck.get_node("GridContainer").hide()
	add_child(tutorial_deck)

	var run_camera: Camera3D = load("res://src/run.tscn").instantiate().get_node("Camera3D").duplicate()
	add_child(run_camera)

	var new_combat: Combat = Combat.create_combat(tutorial_deck, 1, audio, [], 0, true)

	new_combat.combat_over.connect(_on_tutorial_combat_over)
	new_combat.spawned_unit.connect(_on_tutorial_combat_spawned_unit, ConnectFlags.CONNECT_ONE_SHOT)
	new_combat.middle_torch_lit.connect(_on_middle_torch_lit)
	add_child(new_combat)

	# tutorial starts with max mana
	new_combat.get_node("Hand").cur_mana = new_combat.get_node("Hand").max_mana

	set_help_text("Welcome to the forest!")
	continue_button.pressed.connect(highlight_hand_area, ConnectFlags.CONNECT_ONE_SHOT)
	get_tree().paused = true

	tutorial_combat = new_combat
	tutorial_combat_hand_display = new_combat.get_node("HandDisplay") as HandDisplay


func set_help_text(text: String) -> void:
	$HelpText.text = text


func add_highlight(add_to: Control) -> void:
	var highlight: Control = highlight_scene.instantiate()
	add_to.add_child(highlight)
	continue_button.pressed.connect(func() -> void: highlight.queue_free(), ConnectFlags.CONNECT_ONE_SHOT)


func highlight_hand_area() -> void:
	# insane hack since HandArea in the display dynamically grows horizontally, but I don't give a crap!
	add_highlight(get_node("HandAreaFake"))
	set_help_text("This is your hand.\n\nYou can play cards from here.\nWhen cards are drawn, they will come into your hand.")
	continue_button.pressed.connect(highlight_hand_size_area, ConnectFlags.CONNECT_ONE_SHOT)


func highlight_hand_size_area() -> void:
	add_highlight(tutorial_combat_hand_display.get_node("HandSize"))
	set_help_text("This shows your hand size.\n\nYou can only have 4 cards in your hand at a time, excluding secrets. When your hand is full, you can't draw more cards!")
	continue_button.pressed.connect(highlight_mana_area, ConnectFlags.CONNECT_ONE_SHOT)


func highlight_mana_area() -> void:
	add_highlight(tutorial_combat_hand_display.get_node("ManaArea"))
	set_help_text("This is your mana.\n\nEach card costs mana, shown in the top left of each card. You gain mana on a fixed interval, and can play cards as long as you have enough mana.")
	continue_button.pressed.connect(highlight_draw_area, ConnectFlags.CONNECT_ONE_SHOT)


func highlight_draw_area() -> void:
	add_highlight(tutorial_combat_hand_display.get_node("DrawArea"))
	set_help_text("This is the draw pile.\n\nYou can see how many more cards you have to draw before your deck is shuffled.\n\nYou draw cards on a fixed interval.")
	continue_button.pressed.connect(highlight_discard_area, ConnectFlags.CONNECT_ONE_SHOT)


func highlight_discard_area() -> void:
	add_highlight(tutorial_combat_hand_display.get_node("DiscardArea"))
	set_help_text("This is the discard pile.\n\nWhen you play a card, it goes here. When you try to draw when your draw pile is empty, your discard pile is shuffled into your draw pile.")
	continue_button.pressed.connect(explain_play_cards, ConnectFlags.CONNECT_ONE_SHOT)


func explain_play_cards() -> void:
	get_tree().paused = false
	set_help_text("You can drag cards into the play area to play them.\n\nTry it now!")
	continue_button.hide()


func _on_tutorial_combat_spawned_unit() -> void:
	continue_button.show()
	set_help_text("Great job, you've spawned a unit!\n\nIn order to progress in the combat, you must light the torches to defeat the darkness.\nYour units will only move up to the next unlit torch.\nOnly Torchlighters [img=60]res://textures/tutorial/torch_with_background.png[/img] can light torches.\nYou can hover icons on cards to learn what they do.\n\nPress continue, then try to play a Torchlighter.")
	get_tree().paused = true
	continue_button.pressed.connect(unpause, ConnectFlags.CONNECT_ONE_SHOT)


func unpause() -> void:
	get_tree().paused = false
	continue_button.hide()


func _on_middle_torch_lit(_torch_ndx: int) -> void:
	if _torch_ndx == 1:
		continue_button.show()
		set_help_text("Well done! You've lit a torch.\n\nEach time you light a torch in a combat, you'll get a secret added to your hand which doesn't count towards your hand size.\nSecrets are powerful cards that which help you in combat, and only exist for this combat. They can only be played once.\n\nPress continue, then try playing the secret you just got.")
		get_tree().paused = true
		continue_button.pressed.connect(unpause, ConnectFlags.CONNECT_ONE_SHOT)
	elif _torch_ndx == 2:
		tutorial_combat.get_node("Opponent").play_one_card()
		continue_button.show()
		set_help_text("Your opponent spawns units too.\n\nYou must defeat the darkness by lighting all the torches before the darkness extinguishes all of your torches.\n\nPress continue, then try to light the last torch.")
		get_tree().paused = true
		continue_button.pressed.connect(unpause, ConnectFlags.CONNECT_ONE_SHOT)


func _on_tutorial_combat_over(_state: Combat.CombatState) -> void:
	set_help_text("Great job! You've completed the tutorial.\nYou're ready to venture into the forest.\n\nGood luck!")
	$SkipTutorialButton.hide()
	(tutorial_combat.get_node("TutorialMenuButton") as Button).pressed.connect(tutorial_completed.emit)
	(tutorial_combat.get_node("TutorialMenuButton") as Button).show()


func _on_skip_tutorial_button_pressed() -> void:
	get_tree().paused = false
	tutorial_completed.emit()


var continue_button_was_visible := false

func _on_menu_button_pressed() -> void:
	$SkipTutorialButton.hide()
	$HelpText.hide()
	$MenuButton.hide()
	$Settings.show()
	tutorial_combat_hand_display.hide()
	get_tree().paused = true
	if continue_button.is_visible_in_tree():
		continue_button_was_visible = true
		continue_button.hide()


func _on_settings_back_pressed() -> void:
	$SkipTutorialButton.show()
	$HelpText.show()
	$MenuButton.show()
	$Settings.hide()
	tutorial_combat_hand_display.show()
	get_tree().paused = false

	if continue_button_was_visible:
		continue_button.show()
	continue_button_was_visible = false
