class_name Shop extends Control

@onready var blank_card: Control = $BlankCard

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
		new_card.connect("card_clicked", _on_card_clicked)
		units_in_shop.append(new_card)
		$OfferArea/Units.add_child(new_card)

	for ndx in range(SHOP_SPELL_COUNT):
		var new_card := SpellList.new_card_by_id(randi() % SpellList.spell_cards.size())
		new_card.name = "Spell {ndx}"
		new_card.connect("card_clicked", _on_card_clicked)
		spells_in_shop.append(new_card)
		$OfferArea/Spells.add_child(new_card)


func _on_card_clicked(times_clicked: int, card_instance: Card) -> void:
	if last_clicked_card and last_clicked_card != card_instance:
		last_clicked_card.reset_selected()

	last_clicked_card = card_instance

	if times_clicked == 2:
		if player_gold < card_instance.get_score():
			print("Not enough gold")
			return

		# TODO: factor in actual cost
		var cost := card_instance.get_score()
		player_gold -= cost
		item_purchased.emit(last_clicked_card, cost)
		var new_blank_card := blank_card.duplicate()
		new_blank_card.show()
		var index_of: int
		var card_area: Control
		match card_instance.type:
			Card.CardType.UNIT:
				index_of = units_in_shop.find(card_instance)
				units_in_shop.remove_at(index_of)
				card_area = $OfferArea/Units
			Card.CardType.SPELL:
				index_of = spells_in_shop.find(card_instance)
				spells_in_shop.remove_at(index_of)
				card_area = $OfferArea/Spells
			_:
				push_error("Unknown card type clicked in shop: ", card_instance.type)
		card_area.add_child(new_blank_card)
		# no clue why I need the +1 here but it works
		card_area.move_child(new_blank_card, index_of + 1)

		card_instance.queue_free()
		last_clicked_card = null
