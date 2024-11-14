class_name SpellList extends Node

static var card_scene := preload("res://src/card.tscn")

static var spell_cards: Array[Spell] = [
	Spell.new("Fireball", SpellType.DAMAGE, TargetableType.UNIT, 5, 1, "res://textures/spell/fireball.png"),
	Spell.new("Heal", SpellType.HEAL, TargetableType.UNIT, 6, 1, "res://textures/spell/heal.png"),
	Spell.new("Mana", SpellType.CUR_MANA, TargetableType.NONE, 3, 1, "res://textures/hud/mana.png"),
	Spell.new("++ max mana", SpellType.MAX_MANA, TargetableType.NONE, 1, 5, "res://textures/hud/mana.png"),
	Spell.new("Draw cards", SpellType.DRAW_CARDS, TargetableType.NONE, 3, 3, "res://textures/spell/draw_cards.png"),
]

class Spell:
	var name: String
	var type: SpellType
	var targetable_type := TargetableType.NONE
	var value: int
	var mana: int
	var card_image_path: String

	func _init(init_name: String, init_type: SpellType, init_targetable_type: TargetableType, init_value: int, init_mana: int, init_card_image_path: String) -> void:
		self.name = init_name
		self.type = init_type
		self.targetable_type = init_targetable_type
		self.value = init_value
		self.mana = init_mana
		self.card_image_path = init_card_image_path

	static func copy_of(existing: Spell):
		return Spell.new(
			existing.name,
			existing.type,
			existing.targetable_type,
			existing.value,
			existing.mana,
			existing.card_image_path
		)

	func get_score() -> int:
		return value + mana

	func _to_string() -> String:
		return "Spell: " + name + ", " + " Type: " + str(type) + ", " + " Value: " + str(value) + ", " + " Mana: " + str(mana)


enum SpellType {
	DAMAGE,
	HEAL,
	CUR_MANA,
	MAX_MANA,
	DRAW_CARDS,
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
