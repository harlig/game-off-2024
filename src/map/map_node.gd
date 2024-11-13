class_name MapNode extends StaticBody3D

enum NodeType {
	COMBAT,
	SHOP,
	EVENT,
	SECRET,
	BLANK
}

const combat_node_sprite := preload("res://textures/map/combat_node.png")
const shop_node_sprite := preload("res://textures/map/shop.png")
const event_node_sprite := preload("res://textures/map/event_node.png")
const secret_node_sprite := preload("res://textures/map/check_box.png")
const beat_node_sprite := preload("res://textures/map/check_box.png")

var type: NodeType = NodeType.COMBAT

var has_been_beaten := false
var original_texture: Texture

signal node_clicked(node_position: Vector2)

func _ready() -> void:
	match type:
		NodeType.COMBAT:
			$Sprite3D.texture = combat_node_sprite
		NodeType.SHOP:
			$Sprite3D.texture = shop_node_sprite
		NodeType.EVENT:
			$Sprite3D.texture = event_node_sprite
		NodeType.SECRET:
			$Sprite3D.texture = secret_node_sprite
	original_texture = $Sprite3D.texture

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if !event.is_pressed():
		return ;

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("node_clicked", Vector2(position.x, position.z))


func beat_node() -> void:
	$Sprite3D.texture = beat_node_sprite
	has_been_beaten = true

func unbeat_node() -> void:
	$Sprite3D.texture = original_texture
	has_been_beaten = false
