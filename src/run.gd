class_name Run extends Control

const combat_scene := preload("res://src/combat/combat.tscn")
const shop_scene := preload("res://src/map/shop.tscn")
const event_scene := preload("res://src/map/event.tscn")
const secret_scene := preload("res://src/map/map_secret.tscn")

@onready var map := $Map
@onready var camera := $Camera3D
@onready var deck := $DeckControl/Deck
@onready var relic_area := $RelicArea

var player_position := Vector2(0, 0)
var accessible_nodes := []
var current_node: MapNode = null
var combat_difficulty := 1
var bank := 10:
	set(value):
		print("Bank value changed to: ", value)
		bank = value
		$Map/BankControl/BankText.text = str(value)

# TODO: do we even want relics?
var relics: Array[Relic] = [
	Relic.create_relic("Torchlighter Relic", "Your first hand of each combat will always draw a Torchlighter", "res://textures/relic/torchlighter_secret.png", []),
]
# var relics: Array[Relic] = [
# 	Relic.create_relic("Health Relic", "When you spawn a unit, give it +5 max hp", "res://textures/relic/health_secret.jpg", [Card.CardType.UNIT]),
# 	Relic.create_relic("Spells Mana Relic", "Your spells each cost -1 mana", "res://textures/relic/mana_secret.jpg", [Card.CardType.SPELL]),
	# Relic.create_relic("Torchlighter Relic", "Your first hand of each combat will always draw a Torchlighter", "res://textures/relic/torchlighter_secret.png", []),
# 	]

var time_for_preload := 0.5
var time_spent := 0.0
var has_preloaded := false
var current_combat: Combat

var secrets_gained: Array[String] = []

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
	current_node = map.node_instance_positions[player_position]
	# set the starting node as beat
	map.visited_node(current_node)

	$Player.position = Vector3(player_position.x, 2, player_position.y)
	update_accessible_nodes()
	# update_camera_position()

	# Connect the node clicked signal
	map.connect("node_clicked", _on_node_clicked)

	# TODO: need to figure out how to dynamically do this when a relic is added
	for relic in relics:
		relic_area.add_child(relic)

	create_combat()

func _process(delta: float) -> void:
	if has_preloaded:
		return
	if OS.has_feature("editor"):
		has_preloaded = true
		$PreloadedCombat.queue_free()
		$Loading.hide()

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

# func update_camera_position() -> void:
# 	camera.position = Vector3(player_position.x, camera.position.y, player_position.y)

func show_map() -> void:
	$Map.show()
	$Map/ViewDeck.show()
	$Player.show()
	$Map/BankControl.show()
	relic_area.show()

func hide_map(should_show_bank: bool) -> void:
	$Map.hide()
	$Map/ViewDeck.hide()
	$Player.hide()
	if not should_show_bank:
		$Map/BankControl.hide()


func create_combat() -> Combat:
	hide_map(false)
	var new_combat: Combat = Combat.create_combat(combat_difficulty, relics)
	current_combat = new_combat
	combat_difficulty += 1

	new_combat.connect("reward_presented", _on_combat_reward_presented)
	new_combat.connect("reward_chosen", _on_combat_reward_chosen)
	new_combat.connect("combat_over", _on_combat_over)
	add_child(new_combat)
	return new_combat


func _on_node_clicked(node_position: Vector2) -> void:
	if node_position in accessible_nodes:
		var map_node: MapNode = map.node_instance_positions[node_position]
		current_node = map_node
		player_position = node_position
		$Player.position = Vector3(player_position.x, $Player.position.y, player_position.y)

		# ignore if node has been beaten
		if map_node.has_been_beaten:
			map.visited_node(current_node)
		elif map_node.type == MapNode.NodeType.COMBAT:
			create_combat()
		elif map_node.type == MapNode.NodeType.SHOP:
			hide_map(true)
			var new_shop: Shop = shop_scene.instantiate()
			new_shop.shop_value = combat_difficulty
			new_shop.player_gold = bank
			new_shop.connect("item_purchased", _on_item_purchased)
			new_shop.connect("shop_closed", _on_shop_closed)
			add_child(new_shop)
			map.visited_node(current_node)
		elif map_node.type == MapNode.NodeType.EVENT:
			hide_map(true)
			var new_event: Event = event_scene.instantiate()
			new_event.type = Event.EventType.values()[randi() % Event.EventType.size()]
			new_event.deck = deck
			print("Made new event type be ", new_event.type)
			new_event.connect("event_resolved", _on_event_resolved)
			relic_area.hide()
			add_child(new_event)
			map.visited_node(current_node)
		elif map_node.type == MapNode.NodeType.SECRET:
			# TODO: should be able to view deck while in a secret
			hide_map(false)
			# each secret is harder to obtain than the last
			var secret: MapSecret = MapSecret.create_secret_trial(len(secrets_gained) + 1, deck)
			secret.connect("gained_secret", _on_gained_secret.bind(secret))
			secret.connect("lost_secret", _on_lost_secret.bind(secret))
			relic_area.hide()
			add_child(secret)
		else:
			map.visited_node(current_node)
			pass

		map.visualize()

		update_accessible_nodes()
		# update_camera_position()

func _on_gained_secret(gained_secret: String, secret_scene_to_delete: MapSecret) -> void:
	secrets_gained.append(gained_secret)
	map.visited_node(current_node)
	show_map()
	print("MapSecrets list is now ", secrets_gained)
	secret_scene_to_delete.queue_free()

func _on_lost_secret(secret_scene_to_delete: MapSecret) -> void:
	# replace some existing node which isn't a secret now with a secret node
	# TODO: we also want to replace the touching nodes with combat nodes
	show_map()
	secret_scene_to_delete.queue_free()

func _on_combat_over(_combat_state: Combat.CombatState) -> void:
	var existing_combat := current_combat
	existing_combat.get_node("Hand").queue_free()
	for torch: Torch in existing_combat.all_torches:
		torch.get_node("CPUParticles3D").emitting = false

	var new_combat := create_combat()
	new_combat.get_node("HandDisplay").hide()
	for torch: Torch in new_combat.all_torches:
		torch.get_node("CPUParticles3D").emitting = false

	var offset := 56
	new_combat.position = Vector3(existing_combat.position.x + offset, existing_combat.position.y, existing_combat.position.z)

	var tween: Tween = get_tree().create_tween();
	tween.parallel().tween_property(existing_combat, "position", Vector3(existing_combat.position.x - offset, existing_combat.position.y, existing_combat.position.z), 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(new_combat, "position", Vector3(new_combat.position.x - offset, new_combat.position.y, new_combat.position.z), 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	for ndx in range(new_combat.furthest_torch_lit + 1):
		var torch := new_combat.all_torches[ndx]
		torch.get_node("CPUParticles3D").emitting = true
	new_combat.show()

	existing_combat.queue_free()
	new_combat.get_node("HandDisplay").show()

	# if combat_state == Combat.CombatState.WON:
	# 	print("Combat won!")
	# 	map.visited_node(current_node)
	# 	show_map()
	# elif combat_state == Combat.CombatState.LOST:
	# 	print("Combat lost!")
	# 	map.hide_node(current_node)
	# 	move_to_unvisited_node()

func move_to_unvisited_node() -> void:
	# Unbeat and hide some of the previously visited nodes
	var nodes_to_unvisit := combat_difficulty
	var previously_visible_nodes: Array[MapNode] = []
	for node_position: Vector2 in map.node_instance_positions.keys():
		var node: MapNode = map.node_instance_positions[node_position]
		if node in map.visible_nodes and node != current_node:
			previously_visible_nodes.append(node)
	previously_visible_nodes.shuffle()
	for i in range(min(nodes_to_unvisit, previously_visible_nodes.size())):
		var node_to_unbeat := previously_visible_nodes[i]
		map.hide_node(node_to_unbeat)

	# Move to an unvisited node deep in the tree
	var unvisited_nodes := []
	for node_position: Vector2 in map.node_instance_positions.keys():
		if not map.node_instance_positions[node_position].has_been_beaten:
			unvisited_nodes.append(node_position)
	if unvisited_nodes.size() > 0:
		player_position = unvisited_nodes[randi() % unvisited_nodes.size()]
		current_node = map.node_instance_positions[player_position]
		$Player.position = Vector3(player_position.x, $Player.position.y, player_position.y)
	show_map()
	update_accessible_nodes()
	# update_camera_position()

	map.visited_node(current_node)

func _on_map_view_deck_clicked() -> void:
	var is_visualizing_deck: bool = deck.toggle_visualize_deck()
	map.set_interactable(!is_visualizing_deck)

func _on_combat_reward_presented() -> void:
	$Map/BankControl.show()

func _on_combat_reward_chosen(reward: Reward.RewardData) -> void:
	if reward.type == Reward.RewardData.Type.CARD:
		print("Received card reward: ", reward.card.creature)
		deck.add_card(reward.card)
	elif reward.type == Reward.RewardData.Type.GOLD:
		print("Received gold reward: ", reward.gold)
		bank += reward.gold
	current_combat.reward.queue_free()

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
	map.visited_node(current_node)
	show_map()

func _on_event_resolved(gold_gained: int) -> void:
	bank += gold_gained
	$Event.queue_free()
	map.visited_node(current_node)
	show_map()
