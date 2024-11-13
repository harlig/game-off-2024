class_name Secret extends Control

const secret_scene := preload("res://src/map/secret.tscn")

const TRIALS_OFFERED_COUNT := 3
const NUM_CARDS_TO_DRAW := 3

var difficulty: int
# we use a combat deck here bc we need to draw cards
var deck: CombatDeck

var buttons: Array[Button] = []

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
static func create_secret_trial(init_difficulty: int, init_deck: Deck) -> Secret:
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
		var button: Button = $ButtonsArea/Button.duplicate()
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
		$ButtonsArea.add_child(button)

func _on_trial_button_pressed(trial_type: TrialType, trial_value: int, button_pressed_ndx: int) -> void:
	$SecretText.text = "Dealing your fate..."
	var button_pressed: Button = buttons[button_pressed_ndx]
	button_pressed.disabled = true
	var button_size := button_pressed.size
	for ndx in range(len(buttons)):
		if ndx != button_pressed_ndx:
			buttons[ndx].hide()
	for child in $ButtonsArea.get_children():
		if child != button_pressed:
			child.queue_free()
	for ndx in range(len(buttons)):
		if ndx == button_pressed_ndx:
			continue

		var button_size_blank_area: Control = Control.new()
		button_size_blank_area.custom_minimum_size = button_size
		$ButtonsArea.add_child(button_size_blank_area)
		if ndx < button_pressed_ndx:
			$ButtonsArea.move_child(button_size_blank_area, ndx)

	var cards_drawn: Array[Card] = []
	# animate this
	for ndx in range(NUM_CARDS_TO_DRAW):
		var card := deck.draw(false)
		if card != null:
			cards_drawn.append(card)

	print("Drew these cards ", cards_drawn)
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
	print("Value from cards: ", value_from_cards, "... trial value: ", trial_value)
	await get_tree().create_timer(2.0).timeout
	if value_from_cards >= trial_value:
		gained_secret.emit(str(trial_value) + " " + trial_type_string(trial_type))
	else:
		lost_secret.emit()
