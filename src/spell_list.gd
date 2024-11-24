class_name SpellList extends Node

static var card_scene := preload("res://src/card.tscn")

static var spell_cards: Array[Spell] = [
	# Spell.new("Fireball", SpellType.DAMAGE, TargetableType.UNIT, 4, 2, "res://textures/spell/fireball.png"),
	# Spell.new("Heal", SpellType.HEAL, TargetableType.UNIT, 5, 2, "res://textures/spell/heal.png"),
	Spell.new("Mana", SpellType.CUR_MANA, TargetableType.NONE, 2, 1, "res://textures/hud/mana.png"),
	Spell.new("Fast mana regen", SpellType.MANA_REGEN, TargetableType.NONE, 1.5, 4, "res://textures/hud/mana.png"),
	Spell.new("More max mana", SpellType.MAX_MANA, TargetableType.NONE, 1, 4, "res://textures/hud/mana.png"),
	Spell.new("Draw cards", SpellType.DRAW_CARDS, TargetableType.NONE, 2, 3, "res://textures/spell/draw_cards.png"),
	Spell.new("Fast draw cards", SpellType.DRAW_CARDS_REGEN, TargetableType.NONE, 1.5, 4, "res://textures/spell/draw_cards.png"),
]

static var secret_spell_cards: Array[Spell] = [
	Spell.new("More max mana", SpellType.MAX_MANA, TargetableType.NONE, 2, 2, "res://textures/hud/mana.png"),
	Spell.new("Fast mana regen", SpellType.MANA_REGEN, TargetableType.NONE, 2.0, 2, "res://textures/hud/mana.png"),
	Spell.new("Draw cards", SpellType.DRAW_CARDS, TargetableType.NONE, 10, 5, "res://textures/spell/draw_cards.png"),
	Spell.new("Fast draw cards", SpellType.DRAW_CARDS_REGEN, TargetableType.NONE, 2.5, 3, "res://textures/spell/draw_cards.png"),
]

class Spell:
	var name: String
	var type: SpellType
	var targetable_type := TargetableType.NONE
	var value: float
	var mana: int
	var card_image_path: String

	func _init(init_name: String, init_type: SpellType, init_targetable_type: TargetableType, init_value: float, init_mana: int, init_card_image_path: String) -> void:
		self.name = init_name
		self.type = init_type
		self.targetable_type = init_targetable_type
		self.value = init_value
		self.mana = init_mana
		self.card_image_path = init_card_image_path

	static func copy_of(existing: Spell) -> Spell:
		return Spell.new(
			existing.name,
			existing.type,
			existing.targetable_type,
			existing.value,
			existing.mana,
			existing.card_image_path
		)

	func get_score() -> float:
		var base_score := (value + mana * 2) / 5
		return clamp(base_score, 0, 100)

	func _to_string() -> String:
		return "Spell: " + name + ", " + " Type: " + str(type) + ", " + " Value: " + str(value) + ", " + " Mana: " + str(mana)


enum SpellType {
	DAMAGE,
	HEAL,
	CUR_MANA,
	MAX_MANA,
	MANA_REGEN,
	DRAW_CARDS,
	DRAW_CARDS_REGEN,
}

enum TargetableType {
	NONE,
	UNIT,
	AREA,
}

static func new_card_by_id(id: int) -> Card:
	return Card.create_spell_card(spell_cards[id])

static func new_card_by_name(spell_name: String) -> Card:
	var spell_arr := spell_cards.filter(func(spell: Spell) -> bool: return spell.name == spell_name)
	return Card.create_spell_card(spell_arr[0])


static func random_secret_card() -> Card:
	var secret_spell := secret_spell_cards[randi() % secret_spell_cards.size()]
	var card := Card.create_spell_card(secret_spell)
	card.is_secret = true
	return card
