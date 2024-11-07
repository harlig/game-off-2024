class_name UnitList extends Node

static var card_scene := preload("res://src/card.tscn")

static var creature_cards: Array[Creature] = [
	Creature.new("Shriekling", CardType.RANGED, 1, 2, 2, 4, "res://textures/units/cricket.png"),
	Creature.new("Murkmouth", CardType.MELEE, 3, 3, 3, 6, "res://textures/units/hand_crawler.png"),
	Creature.new("Wraithvine", CardType.RANGED, 2, 4, 3, 7, "res://logo.png"),
	Creature.new("Gloom", CardType.AIR, 1, 2, 1, 1, "res://textures/units/cricket.png"),
	Creature.new("Hollowstalkers", CardType.MELEE, 4, 3, 4, 8, "res://textures/units/cricket.png"),
	Creature.new("Sablemoth", CardType.AIR, 2, 1, 1, 2, "res://logo.png"),
	Creature.new("Creep", CardType.MELEE, 1, 1, 1, 1, "res://textures/units/cricket.png"),
	Creature.new("Netherlimbs", CardType.MELEE, 5, 5, 5, 9, "res://logo.png"),
	Creature.new("Phantom Husk", CardType.RANGED, 2, 3, 2, 6, "res://textures/units/cricket.png"),
	Creature.new("Spindler", CardType.RANGED, 1, 2, 2, 4, "res://textures/units/hand_crawler.png"),
	Creature.new("Nightclaw", CardType.MELEE, 3, 4, 4, 7, "res://textures/units/cricket.png"),
	Creature.new("Rotling", CardType.MELEE, 2, 2, 2, 5, "res://logo.png"),
	Creature.new("Dreadroot", CardType.RANGED, 3, 3, 3, 6, "res://textures/units/cricket.png"),
	Creature.new("Haunt", CardType.AIR, 1, 2, 2, 4, "res://logo.png"),
	Creature.new("Cryptkin", CardType.MELEE, 1, 2, 1, 1, "res://textures/units/cricket.png"),
	Creature.new("Soul Devourer", CardType.MELEE, 8, 9, 8, 10, "res://textures/units/hand_crawler.png"),
	Creature.new("Void Tyrant", CardType.AIR, 6, 7, 7, 9, "res://logo.png"),
	Creature.new("Shadow Colossus", CardType.RANGED, 7, 6, 6, 9, "res://logo.png"),
	Creature.new("Ebon Phantom", CardType.MELEE, 5, 8, 8, 9, "res://textures/units/hand_crawler.png"),
	Creature.new("Abyssal Fiend", CardType.MELEE, 10, 10, 10, 10, "res://textures/units/hand_crawler.png")
]

class Creature:
	var name: String
	var type: CardType
	var health: int
	var damage: int
	var mana: int
	var strength_factor: int
	var card_image_path: String

	func _init(init_name: String, init_type: CardType, init_health: int, init_damage: int, init_mana: int, init_strength_factor: int, init_card_image_path: String) -> void:
		self.name = init_name
		self.type = init_type
		self.health = init_health
		self.damage = init_damage
		self.mana = init_mana
		self.strength_factor = init_strength_factor
		self.card_image_path = init_card_image_path

	func get_score() -> int:
		return health + damage

	func _to_string() -> String:
		return "Name: " + name + " Type: " + str(type) + " Health: " + str(health) + " Damage: " + str(damage) + " Mana: " + str(mana) + " Strength Factor: " + str(strength_factor) + " Card Image Path: " + card_image_path


enum CardType {RANGED, MELEE, AIR}

static var available_cards := creature_cards.size()

static func create_card(
	creature: Creature
) -> Card:
	var card_instance: Card = card_scene.instantiate()
	card_instance.set_stats(creature)
	return card_instance

static func new_card_by_id(id: int) -> Card:
	return create_card(creature_cards[id])

static func new_card_by_name(unit_name: String) -> Card:
	var unit_arr := creature_cards.filter(func(creature: Creature) -> bool: return creature.name == unit_name)
	return create_card(unit_arr[0])
