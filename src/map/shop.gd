class_name Shop extends Control

@onready var blank_offer: Control = $BlankOffer

const SHOP_UNIT_COUNT := 4
const SHOP_SPELL_COUNT := 4
var shop_value := 1
var player_gold := 0

var last_clicked_card: Card = null

var units_in_shop := []
var spells_in_shop := []

signal item_purchased(item: Card, cost: int)
signal shop_closed()

func _on_leave_shop_button_pressed() -> void:
	shop_closed.emit()

class Item:
	var cost := 0
	var card: Card
	var type: Type

	enum Type {
		CARD,
		# TODO: add other types
	}

	static func for_card(new_card: Card) -> Item:
		var item: Item = Item.new()
		item.card = new_card
		item.type = Type.CARD
		item.cost = new_card.get_score()
		return item


func _ready() -> void:
	# TODO: guarantee unique units and spells
	for ndx in range(SHOP_UNIT_COUNT):
		var new_card := UnitList.new_card_by_id(randi() % UnitList.creature_cards.size())
		new_card.name = "Unit {ndx}"
		var new_offer := create_new_offer(new_card)

		new_card.connect("card_clicked", _on_card_clicked.bind(new_offer))
		units_in_shop.append(new_card)
		$OfferArea/Units.add_child(new_offer)

	for ndx in range(SHOP_SPELL_COUNT):
		var new_card := SpellList.new_card_by_id(randi() % SpellList.spell_cards.size())
		new_card.name = "Spell {ndx}"
		var new_offer := create_new_offer(new_card)

		new_card.connect("card_clicked", _on_card_clicked.bind(new_offer))
		spells_in_shop.append(new_card)
		$OfferArea/Spells.add_child(new_offer)

func create_new_offer(card: Card) -> Control:
	var new_offer := blank_offer.duplicate()
	new_offer.get_node("BlankCard").queue_free()
	new_offer.add_child(card)
	new_offer.show()
	var cost := card.get_score()
	new_offer.get_node("Label").text = "$" + str(cost)
	return new_offer


func _on_card_clicked(times_clicked: int, card: Card, offer: Control) -> void:
	if last_clicked_card and last_clicked_card != card:
		last_clicked_card.reset_selected()

	last_clicked_card = card

	if times_clicked == 2:
		if player_gold < card.get_score():
			print("Not enough gold")
			return

		# TODO: factor in actual cost
		var cost := card.get_score()
		player_gold -= cost
		item_purchased.emit(last_clicked_card, cost)
		var new_blank_offer := blank_offer.duplicate()
		new_blank_offer.get_node("Label").hide()
		new_blank_offer.show()
		var index_of: int
		var card_area: Control
		match card.type:
			Card.CardType.UNIT:
				index_of = units_in_shop.find(card)
				units_in_shop.remove_at(index_of)
				card_area = $OfferArea/Units
			Card.CardType.SPELL:
				index_of = spells_in_shop.find(card)
				spells_in_shop.remove_at(index_of)
				card_area = $OfferArea/Spells
			_:
				push_error("Unknown card type clicked in shop: ", card.type)
		card_area.add_child(new_blank_offer)
		# no clue why I need the +1 here but it works
		card_area.move_child(new_blank_offer, index_of + 1)

		offer.queue_free()
		last_clicked_card = null

func _on_remove_card_offer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		print("Clicked remove card!")
