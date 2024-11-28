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

var can_highlight_interactable := false
var interactable_hovered := false

var shop: Shop
var lose_combat: LoseCombat

var type: Type

var audio: Audio

var should_delay_last_torch: bool

enum Type {
	START,
	SHOP,
	RETRY,
	END
}


static func create_between_combat(init_type: Type, init_combat_difficulty: int, init_bank: int, init_deck: Deck, init_times_card_removed: int, init_audio: Audio, init_combats_beaten: int, init_should_delay_last_torch: bool = false) -> BetweenCombat:
	var between_combat_instance: BetweenCombat = between_combat_scene.instantiate()
	between_combat_instance.type = init_type
	between_combat_instance.combat_difficulty = init_combat_difficulty
	between_combat_instance.combats_beaten = init_combats_beaten
	between_combat_instance.bank = init_bank
	between_combat_instance.deck = init_deck
	between_combat_instance.audio = init_audio
	between_combat_instance.times_card_removed = init_times_card_removed
	between_combat_instance.should_delay_last_torch = init_should_delay_last_torch

	if init_type == Type.RETRY:
		between_combat_instance.get_node("Continue").hide()

	if init_type == Type.END:
		(between_combat_instance.get_node("Continue").get_node("Button") as Button).text = "Menu"
		var win_torches: Node = between_combat_instance.get_node("Backdrop").get_node("WinTorches")
		for child in win_torches.get_children():
			(child as Torch).light_torch()
		win_torches.show()
	return between_combat_instance


func _ready() -> void:
	var torches_to_light := combats_beaten
	if should_delay_last_torch:
		torches_to_light -= 1

	for ndx in range($ProgressTorches.get_children().size()):
		var torch := $ProgressTorches.get_child(ndx) as Torch
		if ndx < torches_to_light:
			torch.light_torch()
		else:
			torch.extinguish_torch()


func put_in_focus() -> void:
	if combats_beaten > 0:
		($ProgressTorches.get_child(combats_beaten - 1) as Torch).light_torch()
	can_highlight_interactable = true
	if interactable_hovered:
		$Interactable/MeshInstance3D.material_override.set_shader_parameter("highlight", true)
	# TODO: if your mouse is already in the interactable, you should highlight him
	# TODO: set an on mouse enetered/exited bit, and if it's in the entered state here and not exited the let's highlight our boi

func _on_button_pressed() -> void:
	can_highlight_interactable = false
	$Welcome.hide()
	$Win.hide()
	$Continue.hide()
	continue_pressed.emit()


func _on_area_3d_mouse_entered() -> void:
	interactable_hovered = true
	if can_highlight_interactable:
		$Interactable/MeshInstance3D.material_override.set_shader_parameter("highlight", true)


func _on_area_3d_mouse_exited() -> void:
	interactable_hovered = false
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
	$Welcome/Label.text = "Your deck"
	$Welcome/Narrative.hide()
	$Welcome/Button.hide()
	deck.toggle_visualize_deck()
	$Continue.position.x += 60
	$Continue/Button.pressed.connect(start_combats)
	$Continue.show()

func start_combats() -> void:
	deck.toggle_visualize_deck()
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
