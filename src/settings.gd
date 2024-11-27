class_name Settings extends VBoxContainer

var audio: Audio

signal back_pressed()

func _ready() -> void:
	audio = get_parent().get_node("Audio")

func _on_volume_slider_value_changed(value: float) -> void:
	for child: AudioStreamPlayer in audio.get_children():
		child.volume_db = -30.0 + value / 5.0
		if value == 0.0:
			child.volume_db = -100.0;


func _on_back_button_pressed() -> void:
	back_pressed.emit()
	$Title.show()
	$Buttons.show()
	$Settings.hide()
