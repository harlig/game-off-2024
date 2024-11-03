class_name MapNode extends StaticBody3D

enum NodeType {
	COMBAT
}

var node_type: NodeType = NodeType.COMBAT

signal node_clicked(node_position: Vector2)

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if !event.is_pressed():
		return ;

	print("Mouse button pressed")
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Left mouse button pressed")
			emit_signal("node_clicked", Vector2(position.x, position.z))
