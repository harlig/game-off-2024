class_name MapSecret extends Control

const secret_scene := preload("res://src/map/map_secret.tscn")

const TRIALS_OFFERED_COUNT := 3
const NUM_CARDS_TO_DRAW := 3

var difficulty: int
# we use a combat deck here bc we need to draw cards
var deck: CombatDeck

var buttons: Array[Button] = []
var cards: Array[Card] = []

enum TrialType {
	CREATURE,
	SPELL,
	DAMAGE,
	HEALTH,
	DAMAGE_AND_HEALTH,
	MANA
}
func trial_type_string(trial_type: TrialType) -> String:
	match trial_type:
		TrialType.CREATURE:
			return "creatures"
		TrialType.SPELL:
			return "spells"
		TrialType.DAMAGE:
			return "damage"
		TrialType.HEALTH:
			return "health"
		TrialType.DAMAGE_AND_HEALTH:
			return "damage + health"
		TrialType.MANA:
			return "mana"
		_:
			return "unknown"

signal gained_secret(secret: String)
signal lost_secret()


####################################################
####################################################
# This is how you should instantiate a secret scene
####################################################
####################################################
static func create_secret_trial(init_difficulty: int, init_deck: Deck) -> MapSecret:
	var secret := secret_scene.instantiate()
	secret.difficulty = init_difficulty
	secret.deck = CombatDeck.create_combat_deck(init_deck.cards)
	return secret
####################################################
####################################################
####################################################
####################################################

func _ready() -> void:
	var used_trial_types := []
	for ndx in range(TRIALS_OFFERED_COUNT):
		var button: Button = $ButtonArea/Button.duplicate()
		var trial_type: TrialType
		while true:
			trial_type = TrialType.values()[randi() % TrialType.size()]
			if trial_type not in used_trial_types:
				used_trial_types.append(trial_type)
				break
		var trial_value := 0
		match trial_type:
			TrialType.CREATURE:
				# we can't draw more creatures than total number of cards we draw
				trial_value = min(difficulty, NUM_CARDS_TO_DRAW)
			TrialType.SPELL:
				# we can't draw more spells than total number of cards we draw
				trial_value = min(difficulty, NUM_CARDS_TO_DRAW)
			TrialType.DAMAGE:
				trial_value = 5 * difficulty
			TrialType.HEALTH:
				trial_value = 10 * difficulty
			TrialType.DAMAGE_AND_HEALTH:
				trial_value = 15 * difficulty
			TrialType.MANA:
				trial_value = 3 * difficulty
			_:
				push_error("Unknown trial type", trial_type)
		button.text = str(trial_value) + " " + trial_type_string(trial_type)
		button.connect("pressed", _on_trial_button_pressed.bind(trial_type, trial_value, ndx))
		button.show()

		buttons.append(button)
		$ButtonArea.add_child(button)

func _on_trial_button_pressed(trial_type: TrialType, trial_value: int, button_pressed_ndx: int) -> void:
	$SecretText.hide()
	var button_pressed: Button = buttons[button_pressed_ndx]
	button_pressed.disabled = true
	var button_size := button_pressed.size
	for ndx in range(len(buttons)):
		if ndx != button_pressed_ndx:
			buttons[ndx].hide()
	for child in $ButtonArea.get_children():
		if child != button_pressed:
			child.queue_free()
	for ndx in range(len(buttons)):
		if ndx == button_pressed_ndx:
			continue

		var button_size_blank_area: Control = Control.new()
		button_size_blank_area.custom_minimum_size = button_size
		$ButtonArea.add_child(button_size_blank_area)
		if ndx < button_pressed_ndx:
			$ButtonArea.move_child(button_size_blank_area, ndx)

	var cards_drawn: Array[Card] = []
	# animate this
	for ndx in range(NUM_CARDS_TO_DRAW):
		var card := await draw_and_tween_card(ndx)
		if card != null:
			cards_drawn.append(card)

	var values_to_count: Array = []
	match trial_type:
		TrialType.CREATURE:
			values_to_count = cards_drawn.map(func(card: Card) -> int:
				if card.type == Card.CardType.UNIT:
					return 1
				return 0
			)
		TrialType.SPELL:
			values_to_count = cards_drawn.map(func(card: Card) -> int:
				if card.type == Card.CardType.SPELL:
					return 1
				return 0
			)
		TrialType.DAMAGE:
			values_to_count = cards_drawn.map(func(card: Card) -> int:
				if card.type == Card.CardType.UNIT:
					return card.creature.damage
				return 0
			)
		TrialType.HEALTH:
			values_to_count = cards_drawn.map(func(card: Card) -> int:
				if card.type == Card.CardType.UNIT:
					return card.creature.health
				return 0
			)
		TrialType.DAMAGE_AND_HEALTH:
			values_to_count = cards_drawn.map(func(card: Card) -> int:
				if card.type == Card.CardType.UNIT:
					return card.creature.damage + card.creature.health
				return 0
			)
		TrialType.MANA:
			values_to_count = cards_drawn.map(func(card: Card) -> int:
				return card.mana
			)
		_:
			push_error("Unknown trial type", trial_type)
	var value_from_cards: int = values_to_count.reduce(func(acc: int, val: int) -> int: return acc + val)

	var secret_text := str(trial_value) + " " + trial_type_string(trial_type)
	var passed_trial := value_from_cards >= trial_value
	var continue_text := "Continue" if passed_trial else "The mysterious figure gets up, turns around, and walks away"

	if passed_trial:
		var new_text := "Very well, since you must know..."
		# TODO: italicize secret_text
		new_text += "\n\n\"" + secret_text + "\""
		$SecretText.text = new_text
		$SecretText.show()
		for card in cards:
			card.queue_free()
		cards.clear()

	$ButtonArea.hide()

	$ContinueButton.text = continue_text
	$ContinueButton.connect("pressed", _on_continue_button_pressed.bind(passed_trial, secret_text))
	$ContinueButton.show()

func _on_continue_button_pressed(passed_trial: bool, secret_gained: String) -> void:
	if passed_trial:
		gained_secret.emit(secret_gained)
	else:
		lost_secret.emit()


func draw_and_tween_card(ndx: int) -> Card:
	var card := deck.draw(false)
	cards.append(card)
	if card != null:
		card.position = $DrawCardLocation.global_position
		add_child(card)

		# 0th card gets 0th slot in card area, 1st gets 2nd, 2nd gets 4th
		var desired_blank_card_slot_ndx := 2 * ndx
		var blank_card_slot: Control = $BlankCardArea.get_child(desired_blank_card_slot_ndx)
		var blank_card_position := blank_card_slot.global_position
		var tween := get_tree().create_tween()
		tween.tween_property(card, "position", blank_card_position, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
	return card