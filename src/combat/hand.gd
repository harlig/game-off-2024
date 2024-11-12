class_name Hand extends Node

const HAND_SIZE := 5
const MAX_HAND_SIZE := 8

@export var draw_time := 5.0
@export var mana_time := 2.0

var cards: Array[Card] = []
var deck: CombatDeck;
var max_mana := 8
var cur_mana := 8:
	set(value):
		cur_mana = min(value, max_mana)

var draw_time_remaining := draw_time
var mana_time_remaining := mana_time

signal drew(card: Card)
signal discarded(card: Card)
signal mana_updated(cur: int, max: int)

func _physics_process(delta: float) -> void:
	draw_time_remaining -= delta

	if draw_time_remaining <= 0:
		draw_time_remaining = draw_time
		try_draw_card()

	mana_time_remaining -= delta

	if mana_time_remaining <= 0:
		cur_mana += 1
		mana_time_remaining = mana_time
		mana_updated.emit(cur_mana, max_mana)


func initialize(combat_deck: CombatDeck, first_card_torchlighter: bool = false) -> void:
	deck = combat_deck;

	var cards_drawn := 0
	if first_card_torchlighter:
		var torchlighter := deck.try_draw_torchlighter()
		if torchlighter:
			cards.append(torchlighter)
			drew.emit(torchlighter)
			cards_drawn += 1

	for i in range(HAND_SIZE - cards_drawn):
		try_draw_card();
		cards_drawn += 1


func try_draw_card() -> void:
	if cards.size() >= MAX_HAND_SIZE:
		print("Hand full, can't draw a card!")
		return

	var card := deck.draw()
	cards.append(card)
	drew.emit(card)


func draw_cards(n: int) -> void:
	for i in range(n):
		try_draw_card()


func play_card(card: Card) -> void:
	cur_mana -= card.mana
	mana_updated.emit(cur_mana, max_mana)
	discard(card)


func discard(card: Card) -> void:
	deck.discard(card)
	cards.erase(card)
	discarded.emit(card)


func can_play(card: Card) -> bool:
	return card.mana <= cur_mana


func is_empty() -> bool:
	return cards.size() == 0


# TODO: Confirm this works
func swap(card1: Card, card2: Card) -> void:
	var card1_ndx := cards.find(card1)
	var card2_ndx := cards.find(card2)

	cards[card1_ndx] = card2
	cards[card2_ndx] = card1


# func refresh_hand() -> void:
# 	# discard hand
# 	for card in cards:
# 		discard(card)
# 	cards.clear()

# 	# deal full hand
# 	for ndx in range(HAND_SIZE):
# 		_deal_card(deck.draw())
# 	if player_hand:
# 		_sort_hand()
# 	replenish_mana()

# func _deal_card(card: Card) -> void:
# 	if card == null:
# 		print("No card to deal")
# 		return

# 	cards.append(card)

# 	if player_hand:
# 		card.card_clicked.connect(_on_card_clicked)
# 		$CardsArea.add_child(card)

# func _sort_hand() -> void:
# 	# Sort the cards in hand
# 	cards.sort_custom(_compare_cards)

# 	# Sort the order of nodes in the CardsArea
# 	for card in cards:
# 		var index := cards.find(card)
# 		$CardsArea.move_child(card, index)

# func _compare_cards(a: Card, b: Card) -> int:
# 	if a.type != b.type:
# 		return a.type < b.type
# 	if a.mana != b.mana:
# 		return a.mana < b.mana
# 	return a.get_score() < b.get_score()


# func _on_card_clicked(_times_clicked: int, card: Card) -> void:
# 	if card.mana <= cur_mana:
# 		card_clicked.emit(card);
