extends HBoxContainer
@export var card_scene: PackedScene
var hand_size := 5
var current_size := 0
signal card_played

var last_clicked_card: Node = null

func _ready() -> void:
	deal_full_demo_hand()
	pass # Replace with function body.

func deal_full_demo_hand() -> void:
	for i in range(hand_size):
		deal_specific_card(
			5 + i, # max_health
			5 + i, # health
			2 + i, # mana
			3 + i, # damage
			"Creature " + str(i + 1), # card_name
			"res://logo.png" # card_image_path
		)
	deal_specific_card(
			20, # max_health
			20, # health
			8, # mana
			25, # damage
			"Demogorgon", # card_name
			"res://logo.png" # card_image_path
		)

func deal_specific_card(new_max_health: int, new_health: int, new_mana: int, new_damage: int, new_card_name: String, new_card_image_path: String) -> void:
		var card_instance: Card = card_scene.instantiate()
		card_instance.set_stats(
			new_max_health, # max_health
			new_health, # health
			new_mana, # mana
			new_damage, # damage
			new_card_name, # card_name
			new_card_image_path # card_image_path
		)


		card_instance.card_clicked.connect(_on_card_clicked)
		add_child(card_instance)
		current_size += 1

func _on_card_clicked(times_clicked: int, card_instance: Card) -> void:
	if last_clicked_card and last_clicked_card != card_instance:
		last_clicked_card.reset_selected()

	last_clicked_card = card_instance

	if times_clicked == 2:
		card_played.emit(card_instance)
		remove_child(card_instance)
		card_instance.queue_free() # Might need to remove later TBD
		last_clicked_card = null
