extends Node2D

class_name Run

@onready var map := $Map
@onready var camera := $Map/Camera3D

var player_position := Vector2(0, 0)
var accessible_nodes := []

func _ready() -> void:
	# Define parameters for map generation
	var initial_spawn_path_directions := 5
	var max_depth := 6

	# Generate the map
	map.generate_map(Vector2(0, 0), initial_spawn_path_directions, max_depth)
	map.visualize_map()

	# Initialize player position and accessible nodes
	player_position = Vector2(0, 0)
	$Player.position = Vector3(player_position.x, 2, player_position.y)
	update_accessible_nodes()
	update_camera_position()

	# Connect the node clicked signal
	map.connect("node_clicked", _on_node_clicked)

func update_accessible_nodes() -> void:
	accessible_nodes = map.map_tree[player_position]

func update_camera_position() -> void:
	camera.position = Vector3(player_position.x, camera.position.y, player_position.y)

func _on_node_clicked(node_position: Vector2) -> void:
	if node_position in accessible_nodes:
		print("Node at position ", node_position, " is accessible.")
		var map_node: MapNode = map.node_instances[node_position]
		print("Node is a ", MapNode.NodeType.keys()[map_node.node_type], " node.")
		player_position = node_position
		$Player.position = Vector3(player_position.x, 2, player_position.y)
		update_accessible_nodes()
		update_camera_position()
