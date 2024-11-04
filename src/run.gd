extends Node2D

class_name Run

@onready var map := $Map
@onready var camera := $Map/Camera3D
@onready var deck := $Control/Deck
@onready var combat_scene := preload("res://src/combat.tscn")

var player_position := Vector2(0, 0)
var accessible_nodes := []
var current_node: MapNode = null

func _ready() -> void:
	# Define parameters for map generation
	var initial_spawn_path_directions := 5
	var max_depth := 6

	# Generate the map
	map.generate_map(Vector2(0, 0), initial_spawn_path_directions, max_depth)
	map.visualize_map()

	# Initialize player position and accessible nodes
	player_position = Vector2(0, 0)
	current_node = map.node_instances[player_position]
	# set the starting node as beat
	current_node.beat_node()

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
		current_node = map_node
		print("Node is a ", MapNode.NodeType.keys()[map_node.node_type], " node.")
		player_position = node_position
		$Player.position = Vector3(player_position.x, 2, player_position.y)

		# ignore if node has been beaten
		if map_node.has_been_beaten:
			pass
		elif map_node.node_type == MapNode.NodeType.COMBAT:
			# Start combat
			print("Starting combat at node ", node_position)
			$Map.hide()
			$Map/ViewDeck.hide()
			$Player.hide()
			var new_combat := combat_scene.instantiate()
			new_combat.connect("combat_over", _on_combat_over)
			add_child(new_combat)

		update_accessible_nodes()
		update_camera_position()

func _on_combat_over(combat_state: Combat.CombatState) -> void:
	if combat_state == Combat.CombatState.WON:
		print("Combat won!")
		$Combat.queue_free()
		current_node.beat_node()
		$Map.show()
		$Map/ViewDeck.show()
		$Player.show()
	elif combat_state == Combat.CombatState.LOST:
		print("Combat lost!")
		$Combat.queue_free()
		# TODO: probably want to do something else but idk
		# Restart the game
		$Map.show()
		$Map/ViewDeck.show()
		$Player.show()
		player_position = Vector2(0, 0)
		$Player.position = Vector3(player_position.x, 2, player_position.y)
		update_accessible_nodes()
		update_camera_position()


func _on_map_view_deck_clicked() -> void:
	var is_visualizing_deck: bool = deck.toggle_visualize_deck()
	map.set_interactable(!is_visualizing_deck)
