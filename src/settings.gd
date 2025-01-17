class_name Settings extends VBoxContainer

var audio: Audio:
	set(value):
		audio = value
		$VolumeSlider.value = audio.global_volume
		audio.global_volume_changed.connect(func(new_value: float) -> void:
			$VolumeSlider.value=new_value
	)

signal back_pressed()

func _on_volume_slider_value_changed(value: float) -> void:
	audio.global_volume = value
	for child: AudioStreamPlayer in audio.get_children():
		child.volume_db = -30.0 + value / 5.0
		if value == 0.0:
			child.volume_db = -100.0;


func _on_back_button_pressed() -> void:
	back_pressed.emit()
