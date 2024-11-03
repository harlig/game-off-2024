class_name Card extends AspectRatioContainer
var is_selected := false
var times_clicked := 0

var original_stylebox_override: StyleBoxFlat

class Data:
	var max_health: int = 5
	var health: int = max_health
	var mana: int = 2
	var damage: int = 2
	var card_name: String = "Example Creature"
	var card_image_path: String = "res://logo.png"

var data: Data = Data.new() # Ensure data is instantiated

signal card_clicked

func _ready() -> void:
	update_display()

func update_display() -> void:
	$Background/Title.text = data.card_name
	$Background/Health.text = str(data.health)
	$Background/Mana.text = str(data.mana)
	$Background/Damage.text = str(data.damage)
	$MarginContainer/TextureRect.texture = load(data.card_image_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	resize_portrait()


func resize_portrait() -> void:
	var current_width: float = $MarginContainer.size.x
	var margin_value: float = current_width * 0.2
	$MarginContainer.add_theme_constant_override("margin_left", margin_value)
	$MarginContainer.add_theme_constant_override("margin_right", margin_value)
	$MarginContainer.add_theme_constant_override("margin_top", margin_value * 0.5)
	$MarginContainer.add_theme_constant_override("margin_bottom", margin_value * 0.5)

func set_stats(new_max_health: int, new_health: int, new_mana: int, new_damage: int, new_card_name: String, new_card_image_path: String) -> void:
	data.max_health = new_max_health
	data.health = new_health
	data.mana = new_mana
	data.damage = new_damage
	data.card_name = new_card_name
	data.card_image_path = new_card_image_path
	update_display()

func on_select() -> void:
	if original_stylebox_override == null:
		original_stylebox_override = $Background.get_theme_stylebox("panel")

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
			print("Card Clicked")
			is_selected = !is_selected
			on_select()

func reset_selected() -> void:
	is_selected = false
	times_clicked = 0
	$Background.add_theme_stylebox_override("panel", original_stylebox_override)
