class_name BetweenCombat
extends Node3D

const between_combat_scene := preload("res://src/between_combat.tscn")
const shop_scene := preload("res://src/map/shop.tscn")

signal continue_pressed()
signal item_purchased(item: Card, cost: int)
signal card_removed(cost: int)

var combat_difficulty: int
var bank: int
var deck: Deck
var times_card_removed: int

var can_highlight_shopkeeper := true
var shop: Shop


static func create_between_combat(init_combat_difficulty: int, init_bank: int, init_deck: Deck, init_times_card_removed: int) -> BetweenCombat:
	var between_combat_instance: BetweenCombat = between_combat_scene.instantiate()
	between_combat_instance.combat_difficulty = init_combat_difficulty
	between_combat_instance.bank = init_bank
	between_combat_instance.deck = init_deck
	between_combat_instance.times_card_removed = init_times_card_removed
	return between_combat_instance


func _on_button_pressed() -> void:
	can_highlight_shopkeeper = false
	continue_pressed.emit()


func _on_area_3d_mouse_entered() -> void:
	if can_highlight_shopkeeper:
		$Shop/MeshInstance3D.material_override.set_shader_parameter("highlight", true)


func _on_area_3d_mouse_exited() -> void:
	$Shop/MeshInstance3D.material_override.set_shader_parameter("highlight", false)


func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not can_highlight_shopkeeper:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		create_shop()
		$Shop/MeshInstance3D.material_override.set_shader_parameter("highlight", false)
		can_highlight_shopkeeper = false


func create_shop() -> void:
	$Control.hide()
	if shop != null:
		shop.show()
		return

	var new_shop: Shop = shop_scene.instantiate()
	add_child(new_shop)

	new_shop.shop_value = combat_difficulty
	new_shop.player_gold = bank
	new_shop.deck = deck
	new_shop.times_card_removed = times_card_removed
	new_shop.item_purchased.connect(item_purchased.emit)
	new_shop.shop_closed.connect(_on_shop_closed)
	new_shop.card_removed.connect(card_removed.emit)
	shop = new_shop

func _on_shop_closed() -> void:
	shop.hide()
	$Control.show()
	can_highlight_shopkeeper = true
