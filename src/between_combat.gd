class_name BetweenCombat
extends Node3D

const between_combat_scene := preload("res://src/between_combat.tscn")
const shop_scene := preload("res://src/map/shop.tscn")

signal continue_pressed()
signal item_purchased(item: Card, cost: int)
signal card_removed(cost: int)
signal game_lost()

var combat_difficulty: int
var combats_beaten: int
var bank: int
var deck: Deck
var times_card_removed: int

var can_highlight_interactable := true

var shop: Shop
var lose_combat: LoseCombat

var type: Type

var audio: Audio

enum Type {
	START,
	SHOP,
	RETRY,
	END
}


static func create_between_combat(init_type: Type, init_combat_difficulty: int, init_bank: int, init_deck: Deck, init_times_card_removed: int, init_audio: Audio, init_combats_beaten: int) -> BetweenCombat:
	var between_combat_instance: BetweenCombat = between_combat_scene.instantiate()
	between_combat_instance.type = init_type
	between_combat_instance.combat_difficulty = init_combat_difficulty
	between_combat_instance.combats_beaten = init_combats_beaten
	between_combat_instance.bank = init_bank
	between_combat_instance.deck = init_deck
	between_combat_instance.audio = init_audio
	between_combat_instance.times_card_removed = init_times_card_removed

	if init_type == Type.RETRY:
		between_combat_instance.get_node("Continue").hide()

	if init_type == Type.END:
		(between_combat_instance.get_node("Continue").get_node("Button") as Button).text = "Menu"
		between_combat_instance.get_node("Backdrop").get_node("WinTorches").show()
	return between_combat_instance


func _ready() -> void:
	for ndx in range($ProgressTorches.get_children().size()):
		var torch := $ProgressTorches.get_child(ndx) as Torch
		if ndx < combats_beaten:
			torch.light_torch()
		else:
			torch.extinguish_torch()


func _on_button_pressed() -> void:
	can_highlight_interactable = false
	$Continue.hide()
	continue_pressed.emit()


func _on_area_3d_mouse_entered() -> void:
	if can_highlight_interactable:
		$Interactable/MeshInstance3D.material_override.set_shader_parameter("highlight", true)


func _on_area_3d_mouse_exited() -> void:
	$Interactable/MeshInstance3D.material_override.set_shader_parameter("highlight", false)


func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not can_highlight_interactable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if type == Type.START:
			$Welcome.show()
		if type == Type.SHOP:
			create_shop()
		elif type == Type.RETRY:
			create_lose_combat()
		elif type == Type.END:
			$Win.show()
			$Continue.show()
		$Interactable/MeshInstance3D.material_override.set_shader_parameter("highlight", false)
		can_highlight_interactable = false


func _on_welcome_button_pressed() -> void:
	$Welcome.hide()
	deck.toggle_visualize_deck(_who_cares_0, _who_cares_1, _who_cares_1)
	$Continue.position.x += 60
	$Continue/Button.pressed.connect(start_combats)
	$Continue.show()

func start_combats() -> void:
	deck.toggle_visualize_deck(_who_cares_0, _who_cares_1, _who_cares_1)
	$Continue/Button.pressed.disconnect(start_combats)


func create_shop() -> void:
	$Continue.hide()
	if shop != null:
		shop.show()
		return

	var new_shop: Shop = shop_scene.instantiate()
	add_child(new_shop)

	new_shop.shop_value = combat_difficulty
	new_shop.player_gold = bank
	new_shop.deck = deck
	new_shop.times_card_removed = times_card_removed
	new_shop.audio = audio
	new_shop.item_purchased.connect(item_purchased.emit)
	new_shop.shop_closed.connect(_on_shop_closed)
	new_shop.card_removed.connect(card_removed.emit)
	shop = new_shop

func _on_shop_closed() -> void:
	shop.hide()
	$Continue.show()
	can_highlight_interactable = true

func create_lose_combat() -> void:
	# TODO: if I have no more cards I can remove, let's lose the game
	var new_lose_combat: LoseCombat = LoseCombat.create_lose_combat(CombatDeck.create_combat_deck(deck.cards))
	new_lose_combat.card_removed.connect(_on_lose_combat_card_removed)
	new_lose_combat.game_lost.connect(_on_game_lost)
	add_child(new_lose_combat)
	lose_combat = new_lose_combat

func _on_lose_combat_card_removed(card: Card) -> void:
	deck.remove_card(card)
	lose_combat.hide()
	$Continue.show()


func _on_game_lost() -> void:
	for dict: Dictionary in $Continue/Button.pressed.get_connections():
		$Continue/Button.pressed.disconnect(dict.callable)

	$Continue/Button.text = "Menu"
	$Continue.show()
	$Continue/Button.pressed.connect(game_lost.emit)

func _who_cares_0(_t: int, _c: Card) -> void:
	pass

func _who_cares_1(_c: Card) -> void:
	pass
