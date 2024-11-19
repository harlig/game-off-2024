class_name BetweenCombat
extends Node3D

const between_combat_scene := preload("res://src/between_combat.tscn")

signal continue_pressed()

static func create_between_combat() -> BetweenCombat:
	var between_combat_instance: BetweenCombat = between_combat_scene.instantiate()
	return between_combat_instance


func _on_button_pressed() -> void:
	continue_pressed.emit()
