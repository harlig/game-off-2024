extends Node3D

class_name Map

signal node_clicked(node_position: Vector2)
signal view_deck_clicked()

@onready var path_scene := preload("res://src/path.tscn");
@onready var node_scene := preload("res://src/map_node.tscn");

var map_tree := {}
var visited_nodes := []
var available_nodes := []
var node_instances := {}
var can_interact := true

func set_interactable(interactable: bool) -> void:
	can_interact = interactable
	if can_interact:
		$TranslucentCover.hide()
	else:
		$TranslucentCover.show()

func generate_map(center_node: Vector2, initial_spawn_path_directions: int, max_depth: int) -> void:
	map_tree.clear()
	visited_nodes.clear()
	available_nodes.clear()
	node_instances.clear()

	map_tree[center_node] = []
	visited_nodes.append(center_node)
	available_nodes.append(center_node)
	_generate_map(center_node, initial_spawn_path_directions, 0, max_depth)

func _generate_map(start_node: Vector2, directions: int, depth: int, max_depth: int) -> void:
	if depth >= max_depth:
		return

	var attempts := 0
	while len(map_tree[start_node]) < directions and attempts < directions * 10:
		attempts += 1
		var direction := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var new_node := start_node + direction

		# Check for overlapping nodes
		var overlap := false
		for node: Vector2 in visited_nodes:
			if node.distance_to(new_node) < 1:
				overlap = true
				break

		if not overlap and new_node not in visited_nodes:
			map_tree[start_node].append(new_node)
			map_tree[new_node] = [start_node]
			visited_nodes.append(new_node)
			available_nodes.append(new_node)
			# Recursively generate more paths from the new node
			_generate_map(new_node, directions, depth + 1, max_depth)

func visualize_map() -> void:
	for parent_node: Vector2 in map_tree.keys():
		for child_node: Vector2 in map_tree[parent_node]:
			if child_node not in node_instances:
				var node: MapNode = node_scene.instantiate()
				node.position = Vector3(child_node.x, 1.2, child_node.y)
				node.scale = Vector3(0.05, 0.05, 0.05)
				node.connect("node_clicked", _on_node_clicked)
				add_child(node)
				node_instances[child_node] = node # Store the MapNode instance

			# Create a DottedLine to represent the connection
			var path := path_scene.instantiate() as MeshInstance3D

			# Calculate the position, rotation, and scale of the dotted line
			var start_pos := Vector3(parent_node.x, 0, parent_node.y)
			var end_pos := Vector3(child_node.x, 0, child_node.y)
			var direction := (end_pos - start_pos)
			var sine: float = -direction.z / abs(direction.z)

			if direction.z == 0:
				sine = 1

			var angle := acos(direction.normalized().dot(Vector3.RIGHT)) * sine
			var length := direction.length() * 0.95
			var new_pos := (start_pos + end_pos) / 2
			new_pos.y = 1

			add_child(path)
			path.global_position = new_pos
			path.rotation.y = angle
			(path.material_override as ShaderMaterial).set_shader_parameter("len", length)
			(path.mesh as QuadMesh).size.x = length

func _on_node_clicked(node_position: Vector2) -> void:
	if can_interact:
		emit_signal("node_clicked", node_position)

func _on_view_deck_pressed() -> void:
	view_deck_clicked.emit()
