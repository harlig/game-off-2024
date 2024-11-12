class_name Relic extends TextureRect

const relic_scene := preload("res://src/relic.tscn")

var relic_name: String
var description: String
var units_targeted_team: Attackable.Team = Attackable.Team.PLAYER
var applies_to_card_types: Array[Card.CardType] = []

####################################################
####################################################
# This is how you should instantiate a combat scene
####################################################
####################################################
static func create_relic(init_name: String, init_description: String, relic_image_path: String, init_applies_to_card_types: Array[Card.CardType]) -> Relic:
	var relic_instance: Relic = relic_scene.instantiate()
	relic_instance.relic_name = init_name
	relic_instance.description = init_description
	relic_instance.tooltip_text = relic_instance.description
	relic_instance.texture = load(relic_image_path)
	relic_instance.applies_to_card_types = init_applies_to_card_types
	return relic_instance
####################################################
####################################################
####################################################
####################################################


func apply_to_card(card: Card) -> void:
	if card.type not in applies_to_card_types:
		return
	match card.type:
		Card.CardType.UNIT:
			card.creature.health += 5
		Card.CardType.SPELL:
			card.mana -= 1
