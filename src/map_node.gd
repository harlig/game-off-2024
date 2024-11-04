class_name MapNode extends StaticBody3D

enum NodeType {
	COMBAT
}

@onready var combat_node_sprite := preload("res://textures/combat_node.png")

var node_type: NodeType = NodeType.COMBAT
@onready var beat_node_sprite := preload("res://textures/check_box.png")

var has_been_beaten := false

signal node_clicked(node_position: Vector2)

func _ready() -> void:
	if node_type == NodeType.COMBAT:
		$Sprite3D.texture = combat_node_sprite

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if !event.is_pressed():
		return ;

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("node_clicked", Vector2(position.x, position.z))


func beat_node() -> void:
	$Sprite3D.texture = beat_node_sprite
	has_been_beaten = true
