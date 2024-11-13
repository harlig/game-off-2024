class_name Card extends TextureRect

const card_scene := preload("res://src/card.tscn")

var type: CardType
var mana: int:
	set(value):
		mana = value
		if mana < 0:
			mana = 0
		$Mana.text = str(value)
var creature: UnitList.Creature
var spell: SpellList.Spell

var is_selected := false
var times_clicked := 0

var original_stylebox_override: StyleBoxFlat

# TODO: Seperating AOE spell vs targeted spell here might remove some nested match logic in combat
enum CardType {
	UNIT,
	SPELL
}

@warning_ignore("unused_signal")
signal cancel_tween()
signal card_clicked(times_clicked: int, card: Card)

####################################################
####################################################
# This is how you should instantiate a card scene
####################################################
####################################################
static func create_creature_card(init_creature: UnitList.Creature) -> Card:
	var card_instance: Card = card_scene.instantiate()
	card_instance.set_unit(init_creature)
	card_instance.mana = init_creature.mana
	return card_instance

static func create_spell_card(init_spell: SpellList.Spell) -> Card:
	var card_instance: Card = card_scene.instantiate()
	card_instance.set_spell(init_spell)
	card_instance.mana = init_spell.mana
	return card_instance
####################################################
####################################################
####################################################
####################################################


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
		UnitList.CardType.HEALER:
			creature_type_text = "Healer"
	$Description.text = creature_type_text

	for buff in creature.buffs_i_apply:
		$Description.text += "\n" + buff.description()

	if creature.can_change_torches:
		$Description.text += "\nCan light torches"

	if creature.type == UnitList.CardType.HEALER:
		$Description.text += "\nHeals nearby allies for " + str(creature.damage) + " health"

func update_spell_display() -> void:
	$Title.text = spell.name
	$Mana.text = str(mana)
	$Damage.hide()
	$Health.hide()
	$TextureRect.texture = load(spell.card_image_path)
	texture = load("res://textures/card/card_blank.png")

	match spell.type:
		SpellList.SpellType.DAMAGE:
			$Description.text = "Deals " + str(spell.value) + " damage"
		SpellList.SpellType.HEAL:
			$Description.text = "Heals " + str(spell.value) + " health"
		SpellList.SpellType.CUR_MANA:
			$Description.text = "Gives " + str(spell.value) + " mana"
		SpellList.SpellType.MAX_MANA:
			$Description.text = "Increase max mana by " + str(spell.value) + " for this combat"
		SpellList.SpellType.DRAW_CARDS:
			$Description.text = "Draw " + str(spell.value) + " cards"

func highlight_attribute(attribute: String) -> void:
	match attribute:
		"health":
			$Health.add_theme_color_override("font_color", Color.GREEN)
		"damage":
			$Damage.add_theme_color_override("font_color", Color.GREEN)
		"mana":
			$Mana.add_theme_color_override("font_color", Color.GREEN)

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


func is_area_spell() -> bool:
	return type == CardType.SPELL and spell.targetable_type == SpellList.TargetableType.AREA;


func is_unit_spell() -> bool:
	return type == CardType.SPELL and spell.targetable_type == SpellList.TargetableType.UNIT;


func is_none_spell() -> bool:
	return type == CardType.SPELL and spell.targetable_type == SpellList.TargetableType.NONE;


func _to_string() -> String:
	var card_string := ""
	match type:
		CardType.UNIT:
			card_string = "Unit: " + creature.name + " - " + str(creature.health) + " health, " + str(creature.damage) + " damage"
		CardType.SPELL:
			card_string = "Spell: " + spell.name + " - " + str(spell.value) + " value" + " type " + str(spell.type)
	return card_string
