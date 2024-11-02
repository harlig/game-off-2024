extends HBoxContainer
@export var card_scene: PackedScene
var hand_size = 5
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	deal(5)
	pass # Replace with function body.

func deal(cards_to_deal: int) -> void:
	for i in range(cards_to_deal):
		var card_instance = card_scene.instantiate()
		card_instance.z_index = hand_size - i
		print(card_instance.z_index)
		card_instance.setStats(
			5 + i, # max_health
			5 + i, # health
			2 + i, # mana
			3 + i, # damage
			"Creature " + str(i + 1), # card_name
			"res://logo.png" # card_image_path
		)
		var rotation_increment = deg_to_rad(5) # Adjust the degree increment for rotation
		card_instance.rotation = rotation_increment * i
		add_child(card_instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
