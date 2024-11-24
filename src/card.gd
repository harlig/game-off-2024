class_name Card extends TextureRect

const card_scene := preload("res://src/card.tscn")
const card_back_spell := preload("res://textures/card/back/card_back_spell.png")
const heal_icon_texture: Texture2D = preload("res://textures/card/heal.png")
const torchlighter_icon_texture: Texture2D = preload("res://textures/card/torch.png")

var type: CardType
var mana: int:
	set(value):
		mana = value
		if mana < 0:
			mana = 0
		$ManaArea/Mana.text = str(value)
var creature: UnitList.Creature
var spell: SpellList.Spell
var is_secret: bool = false
var is_secret_releaved: bool = false

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
	card_instance.name = init_creature.name
	card_instance.get_node("CardBack").texture = get_random_card_back()
	return card_instance

static func create_spell_card(init_spell: SpellList.Spell) -> Card:
	var card_instance: Card = card_scene.instantiate()
	card_instance.set_spell(init_spell)
	card_instance.mana = init_spell.mana
	card_instance.name = init_spell.name

	card_instance.get_node("CardBack").texture = card_back_spell
	(card_instance.get_node("CardBack") as TextureRect).custom_minimum_size = Vector2(186, 186)
	(card_instance.get_node("CardBack") as TextureRect).size = Vector2.ZERO
	(card_instance.get_node("CardBack") as TextureRect).position = Vector2(0, 20)
	return card_instance

static func get_random_card_back() -> Texture:
	# var card_backs := [
	# 	"res://textures/card/back/card_back_1.png",
	# 	"res://textures/card/back/card_back_2.png",
	# 	"res://textures/card/back/card_back_3.png",
	# 	"res://textures/card/back/card_back_4.png",
	# 	"res://textures/card/back/card_back_5.png",
	# 	"res://textures/card/back/card_back_6.png",
	# 	"res://textures/card/back/card_back_7.png",
	# ]
	var card_backs := [
		"res://textures/card/back/torchless01.png",
		"res://textures/card/back/torchless02.png",
		"res://textures/card/back/torchless03.png",
		"res://textures/card/back/torchless04.png",
	]
	return load(card_backs[randi() % card_backs.size()])
####################################################
####################################################
####################################################
####################################################

static func random_secret_card() -> Card:
	var random := randf()
	var card: Card
	if random < 0.5:
		card = UnitList.random_secret_card()
	else:
		card = SpellList.random_secret_card()
	return card


func _ready() -> void:
	original_stylebox_override = get_theme_stylebox("panel")
	update_display()

func get_score() -> int:
	match type:
		CardType.UNIT:
			return creature.get_score()
		CardType.SPELL:
			return round(spell.get_score())
		_:
			push_error("Unknown card type", type)
	return -1

func get_cost() -> int:
	return get_score() * 3

static func duplicate_card(card: Card) -> Card:
	var new_card := card.duplicate()
	new_card.type = card.type
	new_card.mana = card.mana
	match card.type:
		CardType.UNIT:
			new_card.creature = UnitList.Creature.copy_of(card.creature)
		CardType.SPELL:
			new_card.spell = SpellList.Spell.copy_of(card.spell)
	return new_card

func update_display() -> void:
	match type:
		CardType.UNIT:
			update_unit_display()
		CardType.SPELL:
			update_spell_display()
	if is_secret:
		texture = load("res://textures/card/card_secret.png")
		if not is_secret_releaved:
			$TextureRect.hide()
			$Title.text = "SECRET"
			$DamageArea/Damage.text = "??"
			$HealthArea/Health.text = "??"
			if type == CardType.SPELL:
				# TODO: give an option to affect the rest of the run
				$DescriptionArea/SpellDescription.text = "Affects the rest of this combat"

	$ManaArea/Mana.text = str(mana)

func update_unit_display() -> void:
	$Title.text = creature.name
	$HealthArea/Health.text = str(creature.health)
	$DamageArea/Damage.text = str(creature.damage)
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
			$DamageArea/TextureRect.texture = heal_icon_texture
	$DescriptionArea/Type.text = creature_type_text

	add_buff_icons()

func add_buff_icons() -> void:
	var children := $DescriptionArea/HBoxContainer.get_children()
	for child in children:
		if child.name == "TextureRect":
			continue
		# free, don't queue free otherwise there can be a tad of lag in removing the old ones
		child.free()

	for buff in creature.buffs_i_apply:
		display_icon(buff.texture(), buff.description())

	if creature.can_change_torches:
		display_icon(torchlighter_icon_texture, "Can light torches")

	if creature.type == UnitList.CardType.HEALER:
		$DescriptionArea/Type.tooltip_text = "Rather than attacking, this unit heals ally units"

func display_icon(icon_texture: Texture2D, icon_help_text: String) -> void:
	var new_texture_rect: TextureRect = $DescriptionArea/HBoxContainer/TextureRect.duplicate()
	new_texture_rect.tooltip_text = icon_help_text
	new_texture_rect.texture = icon_texture
	new_texture_rect.show()
	if is_inside_tree():
		$DescriptionArea/HBoxContainer.add_child(new_texture_rect)

func update_spell_display() -> void:
	$Title.text = spell.name
	$ManaArea/Mana.text = str(mana)
	$DamageArea.hide()
	$HealthArea.hide()
	$TextureRect.texture = load(spell.card_image_path)
	texture = load("res://textures/card/card_blank.png")

	$DescriptionArea/Type.text = "Spell"

	var description_text := ""
	match spell.type:
		SpellList.SpellType.DAMAGE:
			description_text = "Deals " + str(int(round(spell.value))) + " damage"
		SpellList.SpellType.HEAL:
			description_text = "Heals " + str(int(round(spell.value))) + " health"
		SpellList.SpellType.CUR_MANA:
			description_text = "Gives " + str(int(round(spell.value))) + " mana"
		SpellList.SpellType.MAX_MANA:
			description_text = "Increase max mana by " + str(int(round(spell.value))) + " for this combat"
		SpellList.SpellType.MANA_REGEN:
			description_text = "Increase mana regen by " + str(spell.value) + "x for this combat"
		SpellList.SpellType.DRAW_CARDS:
			if spell.value <= Hand.MAX_HAND_SIZE:
				description_text = "Draw " + str(int(round(spell.value))) + " cards"
			else:
				description_text = "Draw cards until hand is full"
		SpellList.SpellType.DRAW_CARDS_REGEN:
			description_text = "Increase draw speed by " + str(int(round(spell.value))) + "x for this combat"

	$DescriptionArea/SpellDescription.show()
	$DescriptionArea/SpellDescription.text = description_text
	$DescriptionArea/SpellDescription.tooltip_text = description_text

func highlight_attribute(attribute: String) -> void:
	match attribute:
		"health":
			$HealthArea/Health.add_theme_color_override("font_color", Color.GREEN)
		"damage":
			$DamageArea/Damage.add_theme_color_override("font_color", Color.GREEN)
		"mana":
			$ManaArea/Mana.add_theme_color_override("font_color", Color.GREEN)

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

	card_string += " - Score: " + str(get_score())
	return card_string


func highlight(highlight_color: Color) -> void:
	if not is_inside_tree():
		return
	$Highlight.material.set_shader_parameter("color", highlight_color)
	$Highlight.show()

func unhighlight() -> void:
	# TODO: if I remove this, I get errors in the editor. however if I keep it, cards don't unhighlight once they've been discarded
	if not is_inside_tree():
		return

	$Highlight.hide()
