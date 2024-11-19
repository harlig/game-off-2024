class_name BetweenCombat
extends Node3D

const between_combat_scene := preload("res://src/between_combat.tscn")

signal continue_pressed()

static func create_between_combat() -> BetweenCombat:
	var between_combat_instance: BetweenCombat = between_combat_scene.instantiate()
	return between_combat_instance


func _on_button_pressed() -> void:
	continue_pressed.emit()


func _on_area_3d_mouse_entered() -> void:
	$Area3D/MeshInstance3D.material_override.set_shader_parameter("highlight", true)


func _on_area_3d_mouse_exited() -> void:
	$Area3D/MeshInstance3D.material_override.set_shader_parameter("highlight", false)


func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		print("Mouse clicked")
