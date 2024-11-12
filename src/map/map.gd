class_name Map extends Node3D

signal node_clicked(node_position: Vector2)
signal view_deck_clicked()

@onready var path_scene := preload("res://src/map/path.tscn");
@onready var node_scene := preload("res://src/map/map_node.tscn");
@onready var tree := $Tree

var map_tree := {}
var all_node_positions: Array[Vector2] = []
var visited_nodes: Array[MapNode] = []
var nodes_explicitly_hidden: Array[MapNode] = []
var node_instance_positions := {}
var bushes := []
var can_interact := true
var paths := []
var paths_between := {}
var visible_nodes := {}
var blank_spaces := {}

func set_interactable(interactable: bool) -> void:
	can_interact = interactable
	if can_interact:
		$TranslucentCover.hide()
	else:
		$TranslucentCover.show()

func generate_map(center_node: Vector2, initial_spawn_path_directions: int, max_depth: int) -> void:
	map_tree.clear()
	all_node_positions.clear()
	node_instance_positions.clear()
	blank_spaces.clear()

	map_tree[center_node] = []
	all_node_positions.append(center_node)
	var start_node := _generate_map(center_node, initial_spawn_path_directions, 0, max_depth)
	visited_node(start_node)

	_compute_blank_spaces()
	spawn_on_blank_spaces()

func _generate_map(start_node: Vector2, directions: int, depth: int, max_depth: int) -> MapNode:
	if depth >= max_depth:
		return

	var attempts := 0
	while len(map_tree[start_node]) < directions and attempts < directions * 10:
		attempts += 1
		var direction := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var new_node_position := start_node + direction

		# Check for overlapping nodes
		var overlap := false
		for node: Vector2 in all_node_positions:
			if node.distance_to(new_node_position) < 1:
				overlap = true
				break

		if not overlap and new_node_position not in all_node_positions:
			map_tree[start_node].append(new_node_position)
			map_tree[new_node_position] = [start_node]
			all_node_positions.append(new_node_position)
			# Recursively generate more paths from the new node
			_generate_map(new_node_position, directions, depth + 1, max_depth)

	for parent_node_position: Vector2 in map_tree.keys():
		for child_node_position: Vector2 in map_tree[parent_node_position]:
			if child_node_position not in node_instance_positions:
				var node: MapNode = node_scene.instantiate()
				node.position = Vector3(child_node_position.x, 1.2, child_node_position.y)
				node.scale = Vector3(0.05, 0.05, 0.05)

				node.type = generate_new_node_type()
				node.connect("node_clicked", _on_node_clicked)
				add_child(node)
				node.hide();
				node_instance_positions[child_node_position] = node # Store the MapNode instance
	return node_instance_positions[start_node]

func generate_new_node_type() -> MapNode.NodeType:
	var random := randf()
	if random < 0.5:
		return MapNode.NodeType.COMBAT
	elif random < 0.6:
		return MapNode.NodeType.SHOP
	elif random < 0.9:
		return MapNode.NodeType.EVENT
	else:
		return MapNode.NodeType.BLANK


func visualize() -> void:
	for bush: MeshInstance3D in bushes:
		bush.queue_free()
	bushes.clear()

	for parent_node: Vector2 in map_tree.keys():
		for child_node: Vector2 in map_tree[parent_node]:
			var map_node: MapNode = node_instance_positions[child_node]
			if map_node in visited_nodes:
				if map_node in nodes_explicitly_hidden:
					map_node.hide()
				else:
					map_node.show()

				if child_node in map_tree:
					for grandchild_node: Vector2 in map_tree[child_node]:
						var grandchild_map_node: MapNode = node_instance_positions[grandchild_node]
						if grandchild_map_node in nodes_explicitly_hidden:
							grandchild_map_node.hide()
						else:
							grandchild_map_node.show()

			var start_pos := Vector3(parent_node.x, -1, parent_node.y)
			var end_pos := Vector3(child_node.x, -1, child_node.y)

			if (start_pos in paths_between and paths_between[start_pos] == end_pos) or (end_pos in paths_between and paths_between[end_pos] == start_pos):
				continue

			# Create a DottedLine to represent the connection
			var path := path_scene.instantiate() as MeshInstance3D

			# Calculate the position, rotation, and scale of the dotted line
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
			paths_between[start_pos] = end_pos
			paths_between[end_pos] = start_pos
			paths.append(path)

	spawn_bushes()

func spawn_bushes() -> void:
	for node_position: Vector2 in node_instance_positions.keys():
		var node: MapNode = node_instance_positions[node_position]
		if node not in visible_nodes or not visible_nodes[node]:
			var bush := tree.duplicate() as MeshInstance3D
			add_child(bush)
			bush.show()
			bush.global_transform.origin = Vector3(node_position.x, 1, node_position.y - 0.25)
			bush.rotation_degrees = Vector3(-90, 0, 0)
			bushes.append(bush)

func _on_node_clicked(node_position: Vector2) -> void:
	if can_interact:
		emit_signal("node_clicked", node_position)

func _on_view_deck_pressed() -> void:
	view_deck_clicked.emit()

func visited_node(visited: MapNode) -> void:
	visible_nodes[visited] = true
	visited.beat_node()

	if visited not in visited_nodes:
		visited_nodes.append(visited)

	if visited in nodes_explicitly_hidden:
		nodes_explicitly_hidden.erase(visited)

	for grandchild_node_position: Vector2 in map_tree[Vector2(visited.position.x, visited.position.z)]:
		var grandchild_map_node: MapNode = node_instance_positions[grandchild_node_position]
		if grandchild_map_node in nodes_explicitly_hidden:
			nodes_explicitly_hidden.erase(grandchild_map_node)
		visible_nodes[grandchild_map_node] = true
	visualize()


func hide_node(unvisited: MapNode) -> void:
	visible_nodes[unvisited] = false
	if unvisited not in nodes_explicitly_hidden:
		nodes_explicitly_hidden.append(unvisited)
	unvisited.hide()

const BLANK_SPACE_RADIUS := 2.0
const NUM_TREES_TO_SPAWN_PER_NODE := 5
const DISTANCE_FROM_PATH_OR_NODE := 0.4
func _compute_blank_spaces() -> void:
	for node_position: Vector2 in all_node_positions:
		var node_blank_spaces: Array[Vector2] = []
		var attempts := 0
		while len(node_blank_spaces) < NUM_TREES_TO_SPAWN_PER_NODE and attempts < 100:
			attempts += 1
			var random_offset := Vector2(randf_range(-BLANK_SPACE_RADIUS, BLANK_SPACE_RADIUS), randf_range(-BLANK_SPACE_RADIUS, BLANK_SPACE_RADIUS))
			var maybe_blank_space_position := node_position + random_offset
			var valid := true

			if maybe_blank_space_position.distance_to(node_position) < DISTANCE_FROM_PATH_OR_NODE:
				valid = false

			for other_node in all_node_positions:
				if maybe_blank_space_position.distance_to(other_node) < DISTANCE_FROM_PATH_OR_NODE:
					valid = false
					break

			for path_start: Vector3 in paths_between.keys():
				var path_end: Vector3 = paths_between[path_start]
				var path_midpoint: Vector3 = (path_start + path_end) / 2
				var path_points_to_check: Array[Vector3] = [path_start, path_midpoint, path_end]
				var path_points_to_add := 5
				for ndx in range(path_points_to_add):
					path_points_to_check.append(path_start.lerp(path_end, (1.0 / path_points_to_add * ndx) * randf_range(0.7, 1.3)))

				for path_point: Vector3 in path_points_to_check:
					if maybe_blank_space_position.distance_to(Vector2(path_point.x, path_point.z)) < DISTANCE_FROM_PATH_OR_NODE:
						valid = false
						break

			if valid:
				node_blank_spaces.append(maybe_blank_space_position)

		blank_spaces[node_position] = node_blank_spaces

func spawn_on_blank_spaces() -> void:
	for node_position: Vector2 in blank_spaces.keys():
		for blank_space: Vector2 in blank_spaces[node_position]:
			var new_tree := $Tree2.duplicate() as MeshInstance3D
			new_tree.show()
			new_tree.position = Vector3(blank_space.x, 1, blank_space.y)
			new_tree.rotation_degrees = Vector3(-70, 0, 0)
			add_child(new_tree)
