class_name Menu extends Control

@onready var audio: Audio = $Audio
var tutorial: Tutorial
var tutorial_combat: Combat


func _ready() -> void:
	_on_volume_slider_value_changed($Settings/VolumeSlider.value)
	# start player in tutorial
	_on_how_to_play_pressed()


func _on_play_pressed() -> void:
	var run: Run = load("res://src/run.tscn").instantiate()
	run.main_menu = self
	remove_child(audio)
	run.add_child(audio)
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


func _on_volume_slider_value_changed(value: float) -> void:
	for child: AudioStreamPlayer in audio.get_children():
		child.volume_db = -30.0 + value / 5.0
		if value == 0.0:
			child.volume_db = -100.0;


func _on_back_button_pressed() -> void:
	$Title.show()
	$Buttons.show()
	$Settings.hide()
