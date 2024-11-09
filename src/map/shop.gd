class_name Shop extends Control

const SHOP_SIZE := 6
var shop_value := 1
var player_gold := 0

var last_clicked_card: Card = null

var blank_card: Control

var cards_in_shop := []

signal item_purchased(item: Card)
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
	blank_card = $OfferArea/BlankCard
	for ndx in range(SHOP_SIZE):
		var new_card := UnitList.new_card_by_id(randi() % UnitList.creature_cards.size()) if randf() < 0.7 else SpellList.new_card_by_id(randi() % SpellList.spell_cards.size())
		new_card.connect("card_clicked", _on_card_clicked)
		cards_in_shop.append(new_card)
		$OfferArea.add_child(new_card)


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
		var index_of := cards_in_shop.find(card_instance)
		var new_blank_card := blank_card.duplicate()
		new_blank_card.show()
		$OfferArea.add_child(new_blank_card)
		# no clue why I need the +1 here but it works
		$OfferArea.move_child(new_blank_card, index_of + 1)
		card_instance.queue_free()
		last_clicked_card = null
