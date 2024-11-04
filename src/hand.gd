class_name Hand extends HBoxContainer
var hand_size := 5
var current_size := 0
signal card_played

var last_clicked_card: Node = null
var cards_in_hand: Array[Card] = []

var combat_deck: CombatDeck

# every 2.5 seconds draw a card
func _ready() -> void:
	var draw_timer := Timer.new()
	draw_timer.wait_time = 2.5
	draw_timer.connect("timeout", draw_and_deal)
	add_child(draw_timer)
	draw_timer.start()

func setup_deck(deck: CombatDeck) -> void:
	combat_deck = deck
	deal_full_hand()

func deal_full_hand() -> void:
	for ndx in range(hand_size):
		deal_card(combat_deck.draw())

func draw_and_deal() -> void:
	deal_card(combat_deck.draw())

func deal_card(card: Card) -> void:
	print("Getting dealt card ", card)
	if card == null:
		print("No card to deal")
		return

	card.card_clicked.connect(_on_card_clicked)
	add_child(card)
	current_size += 1
	cards_in_hand.append(card)

func _on_card_clicked(times_clicked: int, card_instance: Card) -> void:
	if last_clicked_card and last_clicked_card != card_instance:
		last_clicked_card.reset_selected()

	last_clicked_card = card_instance

	if times_clicked == 2:
		card_played.emit(card_instance)
		remove_child(card_instance)
		last_clicked_card = null
		card_instance.disconnect("card_clicked", _on_card_clicked)
		cards_in_hand.erase(card_instance)
		combat_deck.discard(card_instance)

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
