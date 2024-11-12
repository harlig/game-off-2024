class_name Relic extends TextureRect

const relic_scene := preload("res://src/relic.tscn")

var relic_name: String
var description: String

static func create_relic(init_name: String, init_description: String) -> Relic:
	var relic_instance: Relic = relic_scene.instantiate()
	relic_instance.relic_name = init_name
	relic_instance.description = init_description
	relic_instance.tooltip_text = relic_instance.description
	return relic_instance

func apply_to_unit(unit: Unit) -> void:
	# relic sets the unit's max hp to 5 more than it was
	unit.unit_attackable.max_hp += 5
