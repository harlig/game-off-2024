class_name Relic extends TextureRect

const relic_scene := preload("res://src/relic.tscn")

var relic_name: String
var description: String
var units_targeted_team: Attackable.Team = Attackable.Team.PLAYER

####################################################
####################################################
# This is how you should instantiate a combat scene
####################################################
####################################################
static func create_relic(init_name: String, init_description: String) -> Relic:
	var relic_instance: Relic = relic_scene.instantiate()
	relic_instance.relic_name = init_name
	relic_instance.description = init_description
	relic_instance.tooltip_text = relic_instance.description
	return relic_instance
####################################################
####################################################
####################################################
####################################################


func apply_to_card(card: Card) -> void:
	if card.type == Card.CardType.UNIT:
		# should also show the new max hp as like green
		card.creature.health += 5
	else:
		print("Relic does not apply to card: ", card.name)
