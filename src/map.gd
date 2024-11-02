extends Node3D

class_name Map

@onready var path_scene := preload("res://src/path.tscn");

var initial_spawn_path_directions := 5
var max_depth := 8
var map_tree := {}
var visited_nodes := []
var available_nodes := []

# I start in the center of the map
# spawn $initial_spawn_path_directions paths in random directions
# walk down each path and spawn a node each unit away, then another path and more nodes further down or stop
# represent this as a strong data structure
# keep track of nodes visited, and nodes available to visit based on where I am

func _ready() -> void:
	var center_node := Vector2(0, 0)
	map_tree[center_node] = []
	visited_nodes.append(center_node)
	available_nodes.append(center_node)
	generate_map(center_node, initial_spawn_path_directions, 0)
	visualize_map()

func generate_map(start_node: Vector2, directions: int, depth: int) -> void:
	if depth >= max_depth:
		return

	for i in range(directions):
		var direction := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var new_node := start_node + direction * 100 # Scale the direction for better visibility

		# Check for overlapping nodes
		var overlap := false
		for node: Vector2 in visited_nodes:
			if node.distance_to(new_node) < 50: # Adjust the distance threshold as needed
				overlap = true
				break

		if not overlap and new_node not in visited_nodes:
			map_tree[start_node].append(new_node)
			map_tree[new_node] = []
			visited_nodes.append(new_node)
			available_nodes.append(new_node)
			# Recursively generate more paths from the new node
			generate_map(new_node, directions - 1, depth + 1)

func visualize_map() -> void:
	for parent_node: Vector2 in map_tree.keys():
		for child_node: Vector2 in map_tree[parent_node]:
			# Create a StaticBody3D to represent the child node
			var node := StaticBody3D.new()
			node.position = Vector3(child_node.x, 1, child_node.y)
			add_child(node)

			var node_sprite := Sprite3D.new()
			node_sprite.texture = $Node.texture
			node_sprite.rotation_degrees.x = -90
			node.add_child(node_sprite)

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

			add_child(path)
			path.global_position = new_pos
			path.rotation.y = angle
			(path.material_override as ShaderMaterial).set_shader_parameter("len", length)
			(path.mesh as QuadMesh).size.x = length
