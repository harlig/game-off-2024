class_name Card extends AspectRatioContainer
var is_selected := false
var times_clicked := 0
static var card_scene := preload("res://src/card.tscn")

var original_stylebox_override: StyleBoxFlat

class Data:
	var unit_list := preload("res://src//unit_list.gd")
	var max_health: int = 5
	var health: int = max_health
	var mana: int = 2
	var damage: int = 2
	var card_name: String = "Example Creature"
	var card_image_path: String = "res://logo.png"
	var card_type: int = unit_list.card_type.MELEE
	func get_card_score() -> int:
		return health + damage

	func _to_string() -> String:
		return "Card Data: " + card_name + " with " + str(health) + " health, " + str(mana) + " mana, and " + str(damage) + " damage."

var data: Data = Data.new() # Ensure data is instantiated

signal card_clicked

func _ready() -> void:
	original_stylebox_override = $Background.get_theme_stylebox("panel")
	update_display()

func update_display() -> void:
	$Background/Title.text = data.card_name
	$Background/Health.text = str(data.health)
	$Background/Mana.text = str(data.mana)
	$Background/Damage.text = str(data.damage)
	$Background/TextureRect.texture = load(data.card_image_path)

func set_stats(new_max_health: int, new_health: int, new_mana: int, new_damage: int, new_card_name: String, new_card_image_path: String, new_card_type: int) -> void:
	data.max_health = new_max_health
	data.health = new_health
	data.mana = new_mana
	data.damage = new_damage
	data.card_name = new_card_name
	data.card_image_path = new_card_image_path
	data.card_type = new_card_type
	update_display()

func on_select() -> void:

	var style_box := StyleBoxFlat.new()
	if is_selected:
		card_clicked.emit(1, self)
		style_box.bg_color = Color(204 / 255.0, 204 / 255.0, 0) # Yellowish color; use RGBA values between 0-1
	else:
		card_clicked.emit(2, self)
		style_box.bg_color = Color(120 / 255.0, 120 / 255.0, 120 / 255.0) # Red color; use RGBA values between 0-1

	$Background.add_theme_stylebox_override("panel", style_box)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			is_selected = !is_selected
			on_select()

func reset_selected() -> void:
	is_selected = false
	times_clicked = 0
	$Background.add_theme_stylebox_override("panel", original_stylebox_override)
