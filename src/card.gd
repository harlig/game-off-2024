class_name Card extends TextureRect
var is_selected := false
var times_clicked := 0

var original_stylebox_override: StyleBoxFlat

var type: CardType
var mana: int
var creature: UnitList.Creature
var spell: SpellList.Spell

enum CardType {
	UNIT,
	SPELL
}


signal card_clicked

func _ready() -> void:
	original_stylebox_override = get_theme_stylebox("panel")
	update_display()

func get_score() -> int:
	match type:
		CardType.UNIT:
			return creature.get_score()
		CardType.SPELL:
			return spell.get_score()
		_:
			push_error("Unknown card type", type)
	return -1

static func duplicate_card(card: Card) -> Card:
	var new_card := card.duplicate()
	new_card.type = card.type
	new_card.mana = card.mana
	match card.type:
		CardType.UNIT:
			new_card.creature = card.creature
		CardType.SPELL:
			new_card.spell = card.spell
	return new_card

func update_display() -> void:
	match type:
		CardType.UNIT:
			update_unit_display()
		CardType.SPELL:
			update_spell_display()
	$Mana.text = str(mana)

func update_unit_display() -> void:
	$Title.text = creature.name
	$Health.text = str(creature.health)
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

func update_spell_display() -> void:
	$Title.text = spell.name
	$Mana.text = str(mana)
	# $TextureRect.texture = load(creature.card_image_path)

	match spell.type:
		SpellList.SpellType.DAMAGE:
			$Description.text = "Deals " + str(spell.value) + " damage"
			$Damage.text = str(spell.value)
			$Health.hide()
		SpellList.SpellType.HEAL:
			$Description.text = "Heals " + str(spell.value) + " health"
			$Health.text = str(spell.value)
			$Damage.hide()
		SpellList.SpellType.CUR_MANA:
			$Description.text = "Gives " + str(spell.value) + " mana"
			$Damage.hide()
			$Health.hide()
		SpellList.SpellType.MAX_MANA:
			$Description.text = "Increase max mana by " + str(spell.value) + " for this combat"
			$Damage.hide()
			$Health.hide()
		SpellList.SpellType.DRAW_CARDS:
			$Description.text = "Draw " + str(spell.value) + " cards"
			$Damage.hide()
			$Health.hide()

func set_unit(from_creature: UnitList.Creature) -> void:
	type = CardType.UNIT
	creature = from_creature
	update_unit_display()

func set_spell(from_spell: SpellList.Spell) -> void:
	type = CardType.SPELL
	spell = from_spell
	update_spell_display()

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
