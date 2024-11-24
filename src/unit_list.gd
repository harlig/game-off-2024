class_name UnitList extends Node

static var creature_cards: Array[Creature] = [
	Creature.new("Shriekling", CardType.RANGED, 10, 2, 2, "res://textures/unit/doodle_jump.png"),
	Creature.new("Murkmouth", CardType.MELEE, 30, 3, 3, "res://textures/unit/hippo.png"),
	Creature.new("Wraithvine", CardType.RANGED, 20, 4, 3, "res://textures/unit/flower.png"),
	Creature.new("Gloom", CardType.RANGED, 10, 2, 1, "res://textures/unit/catergator.png"),
	Creature.new("Hollowstalkers", CardType.MELEE, 40, 3, 4, "res://textures/unit/cricket.png"),
	Creature.new("Sablemoth", CardType.RANGED, 20, 1, 1, "res://textures/unit/turkey_heart.png"),
	Creature.new("Creep", CardType.MELEE, 10, 1, 1, "res://textures/unit/slug.png"),
	Creature.new("Netherlimbs", CardType.MELEE, 50, 5, 5, "res://textures/unit/doodle_jump.png"),
	Creature.new("Phantom Husk", CardType.RANGED, 20, 3, 2, "res://textures/unit/papa_smurf.png"),
	Creature.new("Spindler", CardType.RANGED, 10, 2, 2, "res://textures/unit/tripod.png"),
	Creature.new("Rotling", CardType.MELEE, 20, 2, 2, "res://textures/unit/snek.png"),
	Creature.new("Dreadroot", CardType.RANGED, 30, 3, 3, "res://textures/unit/spiky_seahorse.png"),
	Creature.new("Cryptkin", CardType.MELEE, 10, 2, 1, "res://textures/unit/cricket.png"),
	Creature.new("Nightclaw", CardType.MELEE, 30, 4, 4, "res://textures/unit/buff_beak.png"),
	Creature.new("Soul Devourer", CardType.MELEE, 80, 9, 8, "res://textures/unit/minion.png"),
	Creature.new("Void Tyrant", CardType.RANGED, 60, 7, 7, "res://textures/unit/hunchy.png"),
	Creature.new("Shadow Colossus", CardType.RANGED, 70, 6, 6, "res://textures/unit/catergator.png"),
	Creature.new("Ebon Phantom", CardType.MELEE, 50, 8, 8, "res://textures/unit/hand_crawler.png"),
	Creature.new("Healer", CardType.HEALER, 100, 3, 3, "res://textures/unit/ufo.png"),
	Creature.new("Abyssal Fiend", CardType.MELEE, 100, 8, 10, "res://textures/unit/hand_crawler.png"),
	Creature.new("Damage Buffer", CardType.MELEE, 10, 1, 4, "res://textures/unit/turkey_heart.png", [Unit.Buff.new(Unit.BuffType.DAMAGE, 2)]),
	Creature.new("Health Buffer", CardType.MELEE, 10, 1, 4, "res://textures/unit/papa_smurf.png", [Unit.Buff.new(Unit.BuffType.HEALTH, 5)]),
	Creature.new("Speed Buffer", CardType.MELEE, 10, 1, 4, "res://textures/unit/snek.png", [Unit.Buff.new(Unit.BuffType.SPEED, 0.5)]),
	Creature.new("Torchlighter", CardType.MELEE, 10, 1, 2, "res://textures/unit/hand_crawler.png", [], true),
]

static var secret_creature_cards: Array[Creature] = [
	Creature.new("Big Frickin Guy", CardType.MELEE, 250, 4, 0, "res://textures/unit/hand_crawler.png", [Unit.Buff.new(Unit.BuffType.DAMAGE, 5)])
]

class Creature:
	var name: String
	var type: CardType
	var health: int
	var damage: int
	var mana: int
	var strength_factor: int
	var card_image_path: String
	var buffs_i_apply: Array[Unit.Buff] = []
	var can_change_torches: bool = false

	func _init(init_name: String, init_type: CardType, init_health: int, init_damage: int, init_mana: int, init_card_image_path: String, init_buffs_i_apply: Array[Unit.Buff]=[], init_can_change_torches: bool = false) -> void:
		self.name = init_name
		self.type = init_type
		self.health = init_health
		self.damage = init_damage
		self.mana = init_mana
		self.card_image_path = init_card_image_path
		self.buffs_i_apply = init_buffs_i_apply
		self.can_change_torches = init_can_change_torches

		self.strength_factor = health + damage * 2 + mana * 3

	static func copy_of(existing: Creature) -> Creature:
		return Creature.new(existing.name,
			existing.type,
			existing.health,
			existing.damage,
			existing.mana,
			existing.card_image_path,
			existing.buffs_i_apply,
			existing.can_change_torches
		)

	func get_score() -> int:
		var base_score := (health + damage * 2 + mana * 3) / 10.0
		var buff_score := buffs_i_apply.size() * 5
		var torch_score := 10 if can_change_torches else 0
		return clamp(base_score + buff_score + torch_score, 0, 100)

	func _to_string() -> String:
		return "Name: " + name + " Type: " + str(type) + " Health: " + str(health) + " Damage: " + str(damage) + " Mana: " + str(mana) + " Strength Factor: " + str(strength_factor) + " Card Image Path: " + card_image_path + " Buffs I Apply: " + str(buffs_i_apply) + " Can Light Torches: " + str(can_change_torches)


enum CardType {RANGED, MELEE, AIR, HEALER}

static func new_card_by_id(id: int) -> Card:
	return Card.create_creature_card(creature_cards[id])

static func new_card_by_name(unit_name: String) -> Card:
	var unit_arr := creature_cards.filter(func(creature: Creature) -> bool: return creature.name == unit_name)
	return Card.create_creature_card(unit_arr[0])

static func random_secret_card() -> Card:
	var secret_creature := secret_creature_cards[randi() % secret_creature_cards.size()]
	var card := Card.create_creature_card(secret_creature)
	card.is_secret = true
	return card
