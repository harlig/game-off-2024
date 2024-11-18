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

	# emit signal immediately to update mana display
	mana_updated.emit(cur_mana, max_mana)


func try_draw_card() -> bool:
	if cards.filter(func(_card: Card) -> bool: return _card and !_card.is_secret).size() >= MAX_HAND_SIZE:
		print("Hand full, can't draw a card!")
		return false

	var card := deck.draw()
	cards.append(card)
	drew.emit(card)
	return true


func draw_cards(n: int) -> void:
	for i in range(n):
		# if we can't draw a card, don't keep trying
		if not try_draw_card():
			return


func add_secret(card: Card) -> void:
	# TODO: make this add to the end of the secret cards
	cards.insert(0, card)
	drew.emit(card, 0)
	pass


func play_card(card: Card) -> void:
	cur_mana -= card.mana
	mana_updated.emit(cur_mana, max_mana)
	var hand_display := get_node_or_null("../HandDisplay")
	if card.is_secret and hand_display:
		hand_display.reveal_secret(card)
		get_tree().paused = true
		await hand_display.secret_acknowledged
		get_tree().paused = false
	# secrets don't get sent to the discard pile
	if !card.is_secret:
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
