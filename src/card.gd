class_name Card extends AspectRatioContainer
var max_health := 5
var health := max_health
var mana := 2
var damage := 2
var card_name := "Example Creature"
var card_image_path := "res://logo.png"
var is_selected := false
var times_clicked := 0

var original_stylebox_override: StyleBoxFlat

signal card_clicked
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_display()

	pass # Replace with function body.

func update_display() -> void:
	$Background/Title.text = card_name
	$Background/Health.text = str(health)
	$Background/Mana.text = str(mana)
	$Background/Damage.text = str(damage)
	$MarginContainer/TextureRect.texture = load(card_image_path)

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
	max_health = new_max_health
	health = new_health
	mana = new_mana
	damage = new_damage
	card_name = new_card_name
	card_image_path = new_card_image_path
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
