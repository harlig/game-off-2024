class_name Run extends Control

@onready var map := $Map
@onready var camera := $Map/Camera3D
@onready var deck := $DeckControl/Deck
@onready var combat_scene := preload("res://src/combat/combat.tscn")
@onready var shop_scene := preload("res://src/shop.tscn")

var player_position := Vector2(0, 0)
var accessible_nodes := []
var current_node: MapNode = null
var combat_difficulty := 1
var bank := 10:
	set(value):
		print("Bank value changed to: ", value)
		bank = value
		$Map/BankControl/BankText.text = str(value)

func _ready() -> void:
	# Define parameters for map generation
	var initial_spawn_path_directions := 8
	var max_depth := 8

	# Generate the map
	map.generate_map(Vector2(0, 0), initial_spawn_path_directions, max_depth)
	map.visualize()
	$Map/BankControl/BankText.text = str(bank)

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

var time_for_preload := 0.5
var time_spent := 0.0
var has_preloaded := false

func _process(delta: float) -> void:
	if has_preloaded:
		return

	time_spent += delta
	print("Preloading combat maybe - time spent waiting: ", time_spent)
	if time_spent > time_for_preload:
		has_preloaded = true
		await get_tree().create_timer(0.1).timeout
		$PreloadedCombat.show()

		await get_tree().create_timer(0.1).timeout
		$PreloadedCombat.queue_free()

		await get_tree().create_timer(0.1).timeout
		$Loading.hide()

		print("has done preloaded shit")

func update_accessible_nodes() -> void:
	accessible_nodes = map.map_tree[player_position]

func update_camera_position() -> void:
	camera.position = Vector3(player_position.x, camera.position.y, player_position.y)

func show_map() -> void:
	$Map.show()
	$Map/ViewDeck.show()
	$Player.show()

func hide_map() -> void:
	$Map.hide()
	$Map/ViewDeck.hide()
	$Player.hide()


func _on_node_clicked(node_position: Vector2) -> void:

	if node_position in accessible_nodes:
		var map_node: MapNode = map.node_instances[node_position]
		current_node = map_node
		player_position = node_position
		$Player.position = Vector3(player_position.x, 2, player_position.y)

		# ignore if node has been beaten
		if map_node.has_been_beaten:
			pass
		elif map_node.type == MapNode.NodeType.COMBAT:
			hide_map()
			var new_combat: Combat = combat_scene.instantiate()
			new_combat.difficulty = combat_difficulty
			combat_difficulty += 1
			new_combat.connect("reward_chosen", _on_combat_reward_chosen)
			new_combat.connect("combat_over", _on_combat_over)
			add_child(new_combat)
		elif map_node.type == MapNode.NodeType.SHOP:
			hide_map()
			var new_shop: Shop = shop_scene.instantiate()
			new_shop.shop_value = combat_difficulty
			new_shop.player_gold = bank
			new_shop.connect("item_purchased", _on_item_purchased)
			new_shop.connect("shop_closed", _on_shop_closed)
			add_child(new_shop)
		elif map_node.type == MapNode.NodeType.EVENT:
			print("Event node clicked")
			current_node.beat_node()
			pass
		else:
			current_node.beat_node()
			pass

		map.visited_node(map_node)
		map.visualize()

		update_accessible_nodes()
		update_camera_position()

func _on_combat_over(combat_state: Combat.CombatState) -> void:
	if combat_state == Combat.CombatState.WON:
		print("Combat won!")
		$Combat.queue_free()
		current_node.beat_node()
		show_map()
	elif combat_state == Combat.CombatState.LOST:
		print("Combat lost!")
		$Combat.queue_free()
		# TODO: probably want to do something else but idk
		# Move back to start
		player_position = Vector2(0, 0)
		$Player.position = Vector3(player_position.x, 2, player_position.y)
		show_map()
		update_accessible_nodes()
		update_camera_position()

func _on_map_view_deck_clicked() -> void:
	var is_visualizing_deck: bool = deck.toggle_visualize_deck()
	map.set_interactable(!is_visualizing_deck)

func _on_combat_reward_chosen(reward: Reward.RewardData) -> void:
	if reward.type == Reward.RewardData.Type.CARD:
		print("Received card reward: ", reward.card.creature)
		deck.add_card(reward.card)
	elif reward.type == Reward.RewardData.Type.GOLD:
		print("Received gold reward: ", reward.gold)
		bank += reward.gold

func _on_item_purchased(item: Card, cost: int) -> void:
	deck.add_card(item)
	bank -= cost
	# TODO: support items other than cards
	# if item.type == Shop.Item.Type.CARD:
	# 	deck.add_card(item.card)
	# else:
	# 	push_warning("Item type not supported yet")

func _on_shop_closed() -> void:
	$Shop.queue_free()
	current_node.beat_node()
	show_map()
