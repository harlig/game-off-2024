class_name SpellList extends Node

static var card_scene := preload("res://src/card.tscn")

static var spell_cards: Array[Spell] = [
	Spell.new("Fireball", SpellType.DAMAGE, 5, 1, "res://textures/spells/fireball.png"),
	Spell.new("Heal", SpellType.HEAL, 6, 1, "res://textures/spells/heal.png"),
	Spell.new("Mana", SpellType.MANA, 3, 5, "res://textures/spells/mana.png"),
]

class Spell:
	var name: String
	var type: SpellType
	var value: int
	var mana: int
	var card_image_path: String

	func _init(init_name: String, init_type: SpellType, init_value: int, init_mana: int, init_card_image_path: String) -> void:
		self.name = init_name
		self.type = init_type
		self.value = init_value
		self.mana = init_mana
		self.card_image_path = init_card_image_path

	func get_score() -> int:
		return value + mana

	func _to_string() -> String:
		return "Name: " + name + " Type: " + str(type) + " Value: " + str(value) + " Mana: " + str(mana) + " Card Image Path: " + card_image_path


enum SpellType {
	DAMAGE,
	HEAL,
	MANA,
}

static func create_card(
	spell: Spell
) -> Card:
	var card_instance: Card = card_scene.instantiate()
	card_instance.set_spell(spell)
	card_instance.mana = spell.mana
	return card_instance

static func new_card_by_id(id: int) -> Card:
	return create_card(spell_cards[id])

static func new_card_by_name(spell_name: String) -> Card:
	var spell_arr := spell_cards.filter(func(spell: Spell) -> bool: return spell.name == spell_name)
	return create_card(spell_arr[0])
