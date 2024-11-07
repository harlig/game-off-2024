class_name Card extends TextureRect
var is_selected := false
var times_clicked := 0
static var card_scene := preload("res://src/card.tscn")

var original_stylebox_override: StyleBoxFlat

var creature: UnitList.Creature

signal card_clicked

func _ready() -> void:
	original_stylebox_override = get_theme_stylebox("panel")
	update_display()

func update_display() -> void:
	$Title.text = creature.name
	$Health.text = str(creature.health)
	$Mana.text = str(creature.mana)
	$Damage.text = str(creature.damage)
	$TextureRect.texture = load(creature.card_image_path)

func set_stats(from_creature: UnitList.Creature) -> void:
	creature = from_creature
	update_display()

func on_select() -> void:

	var style_box := StyleBoxFlat.new()
	if is_selected:
		card_clicked.emit(1, self)
		style_box.bg_color = Color(204 / 255.0, 204 / 255.0, 0) # Yellowish color; use RGBA values between 0-1
	else:
		card_clicked.emit(2, self)
		style_box.bg_color = Color(120 / 255.0, 120 / 255.0, 120 / 255.0) # Red color; use RGBA values between 0-1

	add_theme_stylebox_override("panel", style_box)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			is_selected = !is_selected
			on_select()

func reset_selected() -> void:
	is_selected = false
	times_clicked = 0
	add_theme_stylebox_override("panel", original_stylebox_override)
