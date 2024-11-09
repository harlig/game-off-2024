class_name Hand extends Control

const HAND_SIZE := 5
const MAX_HAND_SIZE := 8
const MAX_MANA := 8

@export var player_hand := false;

var cards_in_hand: Array[Card] = []
var combat_deck: CombatDeck
var cur_mana := 8:
	set(value):
		if value > MAX_MANA:
			cur_mana = MAX_MANA
		else:
			cur_mana = value
		if player_hand:
			$HBoxContainer/TextureRect2/Label2.text = str(cur_mana) + "/" + str(MAX_MANA);

signal card_clicked(card: Card)

func _ready() -> void:
	if player_hand:
		# draw a card every 2 seconds
		var draw_timer: Timer = Timer.new()
		draw_timer.autostart = true
		draw_timer.wait_time = 2.0
		draw_timer.connect("timeout", _on_draw_timer_timeout)

		var mana_timer: Timer = Timer.new()
		mana_timer.autostart = true
		mana_timer.wait_time = 1.0
		mana_timer.connect("timeout", _on_mana_timer_timeout)

		add_child(draw_timer)
		add_child(mana_timer)

func _on_draw_timer_timeout() -> void:
	if cards_in_hand.size() >= MAX_HAND_SIZE:
		print("Hand full, can't draw a card!")
		return
	_deal_card(combat_deck.draw())

func _on_mana_timer_timeout() -> void:
	cur_mana += 1

func replenish_mana() -> void:
	cur_mana = MAX_MANA

func setup_deck(deck: CombatDeck) -> void:
	combat_deck = deck
	refresh_hand()

func refresh_hand() -> void:
	# discard hand
	for card in cards_in_hand:
		discard(card)
	cards_in_hand.clear()

	# deal full hand
	for ndx in range(HAND_SIZE):
		_deal_card(combat_deck.draw())
	if player_hand:
		_sort_hand()
	replenish_mana()

func _deal_card(card: Card) -> void:
	if card == null:
		print("No card to deal")
		return

	cards_in_hand.append(card)

	if player_hand:
		card.card_clicked.connect(_on_card_clicked)
		$CardsArea.add_child(card)

func _sort_hand() -> void:
	# Sort the cards in hand
	cards_in_hand.sort_custom(_compare_cards)

	# Sort the order of nodes in the CardsArea
	for card in cards_in_hand:
		var index := cards_in_hand.find(card)
		$CardsArea.move_child(card, index)

func _compare_cards(a: Card, b: Card) -> int:
	if a.type != b.type:
		return a.type < b.type
	match a.type:
		Card.CardType.UNIT:
			if a.creature.mana != b.creature.mana:
				return a.creature.mana < b.creature.mana
			return a.creature.get_score() < b.creature.get_score()
		Card.CardType.SPELL:
			if a.spell.mana != b.spell.mana:
				return a.spell.mana < b.spell.mana
			return a.spell.get_score() < b.spell.get_score()

	return 0

func play_card(card: Card) -> void:
	cur_mana -= card.creature.mana
	discard(card)
	cards_in_hand.erase(card)

func discard(card: Card) -> void:
	combat_deck.discard(card)

	if player_hand:
		card.card_clicked.disconnect(_on_card_clicked)
		$CardsArea.remove_child(card)

func play_best_card() -> void:
	if cards_in_hand.size() == 0:
		refresh_hand()

	replenish_mana()
	var best_card: Card = null
	var best_card_value: float = -1
	for card in cards_in_hand:
		var card_value: float = card.creature.get_score()
		if card_value > best_card_value:
			best_card = card
			best_card_value = card_value
	if best_card and cur_mana >= best_card.creature.mana:
		print(best_card.creature.name)
		get_parent().spawn_enemy(best_card)
		play_card(best_card)

	else:
		print("No more cards to play")

func _on_card_clicked(_times_clicked: int, card: Card) -> void:
	if card.creature.mana <= cur_mana:
		card_clicked.emit(card);
