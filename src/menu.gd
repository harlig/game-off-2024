class_name Menu extends Control

@onready var audio: Audio = $Audio
var tutorial: Tutorial
var tutorial_combat: Combat


func _ready() -> void:
	$Settings.audio = audio
	# start player in tutorial
	_on_how_to_play_pressed()


func _on_play_pressed() -> void:
	var run: Run = load("res://src/run.tscn").instantiate()
	run.main_menu = self
	add_sibling.call_deferred(run)
	hide()


func _on_how_to_play_pressed() -> void:
	tutorial = Tutorial.create_tutorial(audio)
	tutorial.tutorial_completed.connect(_on_tutorial_completed)
	add_sibling.call_deferred(tutorial)
	hide()

func _on_tutorial_completed() -> void:
	show()
	tutorial.queue_free()

func _on_settings_pressed() -> void:
	$Title.hide()
	$Buttons.hide()
	$Settings.show()

func _on_settings_back_button_pressed() -> void:
	$Title.show()
	$Buttons.show()
	$Settings.hide()
