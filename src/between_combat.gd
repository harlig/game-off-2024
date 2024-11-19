class_name BetweenCombat
extends Node3D

const between_combat_scene := preload("res://src/between_combat.tscn")
const shop_scene := preload("res://src/map/shop.tscn")

signal continue_pressed()
signal item_purchased

var combat_difficulty: int
var bank: int

var can_highlight_shopkeeper := true
var can_open_shop := false
var shop: Shop

static func create_between_combat(init_combat_difficulty: int, init_bank: int) -> BetweenCombat:
	var between_combat_instance: BetweenCombat = between_combat_scene.instantiate()
	between_combat_instance.combat_difficulty = init_combat_difficulty
	between_combat_instance.bank = init_bank
	return between_combat_instance


func _on_button_pressed() -> void:
	continue_pressed.emit()


func _on_area_3d_mouse_entered() -> void:
	if can_highlight_shopkeeper:
		$Area3D/MeshInstance3D.material_override.set_shader_parameter("highlight", true)


func _on_area_3d_mouse_exited() -> void:
	$Area3D/MeshInstance3D.material_override.set_shader_parameter("highlight", false)


func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not can_open_shop:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		create_shop()


func create_shop() -> void:
	$Control.hide()
	var new_shop: Shop = shop_scene.instantiate()
	new_shop.shop_value = combat_difficulty
	new_shop.player_gold = bank
	new_shop.item_purchased.connect(item_purchased.emit)
	new_shop.shop_closed.connect(_on_shop_closed)
	shop = new_shop
	add_child(new_shop)

func _on_shop_closed() -> void:
	can_highlight_shopkeeper = false
	can_open_shop = false
	shop.queue_free()
	shop = null
	$Control.show()
