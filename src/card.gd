class_name Card extends TextureRect
var is_selected := false
var times_clicked := 0

var original_stylebox_override: StyleBoxFlat

var type: CardType
var creature: UnitList.Creature

enum CardType {
	UNIT,
	SPELL
}

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

	var creature_type_text := ""
	match creature.type:
		UnitList.CardType.RANGED:
			creature_type_text = "Ranged"
		UnitList.CardType.MELEE:
			creature_type_text = "Melee"
		UnitList.CardType.AIR:
			creature_type_text = "Air"
	$Description.text = creature_type_text

func set_unit(from_creature: UnitList.Creature) -> void:
	type = CardType.UNIT
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
