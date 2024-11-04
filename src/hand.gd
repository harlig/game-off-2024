class_name Hand extends Control

@onready var cards_area: HBoxContainer = $CardsArea
@onready var mana_area_container: HBoxContainer = $ManaArea/HBoxContainer
@onready var full_mana_icon := preload("res://textures/full_mana.png")
@onready var empty_mana_icon := preload("res://textures/empty_mana.png")
const HAND_SIZE := 5
const MAX_MANA := 10

signal card_played

var last_clicked_card: Node = null
var cards_in_hand: Array[Card] = []
var combat_deck: CombatDeck
var mana_consumed := 0

func _ready() -> void:
	for ndx in range(MAX_MANA):
		var icon := TextureRect.new()
		icon.texture = full_mana_icon
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		mana_area_container.add_child(icon)
	replenish_mana()

func replenish_mana() -> void:
	mana_consumed = 0
	for ndx in range(MAX_MANA):
		var icon := mana_area_container.get_child(ndx) as TextureRect
		icon.texture = full_mana_icon

func use_mana(mana_used: int) -> void:
	mana_consumed += mana_used
	for ndx in range(mana_consumed):
		var icon := mana_area_container.get_child(ndx) as TextureRect
		icon.texture = empty_mana_icon

func setup_deck(deck: CombatDeck) -> void:
	combat_deck = deck
	refresh_hand()

func refresh_hand() -> void:
	_discard_hand()
	_deal_full_hand()
	replenish_mana()

func _deal_full_hand() -> void:
	for ndx in range(HAND_SIZE):
		_deal_card(combat_deck.draw())

func _deal_card(card: Card) -> void:
	if card == null:
		print("No card to deal")
		return

	card.card_clicked.connect(_on_card_clicked)
	cards_area.add_child(card)
	cards_in_hand.append(card)

func _discard_hand() -> void:
	last_clicked_card = null
	for card in cards_in_hand:
		discard(card)
	cards_in_hand.clear()

func _on_card_clicked(times_clicked: int, card_instance: Card) -> void:
	if last_clicked_card and last_clicked_card != card_instance:
		last_clicked_card.reset_selected()

	last_clicked_card = card_instance

	if times_clicked == 2:
		# check if we have enough mana
		if mana_consumed + card_instance.data.mana > MAX_MANA:
			# TODO: something more disruptive
			print("Not enough mana")
			return
		play_card(last_clicked_card)


func play_card(card: Card) -> void:
	use_mana(card.data.mana)
	card_played.emit(card)
	discard(card)
	cards_in_hand.erase(card)
	last_clicked_card = null

func discard(card: Card) -> void:
	card.disconnect("card_clicked", _on_card_clicked)
	combat_deck.discard(card)
	cards_area.remove_child(card)

func play_best_card() -> void:
	var best_card: Card = null
	var best_card_value: float = -1
	for card in cards_in_hand:
		var card_value: float = card.data.get_card_score()
		if card_value > best_card_value:
			best_card = card
			best_card_value = card_value
	if best_card:
		_on_card_clicked(2, best_card)
	else:
		print("No more cards to play")
