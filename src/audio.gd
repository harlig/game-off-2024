class_name Audio extends Node

var disabled := false
var global_volume := 50.0:
	set(value):
		global_volume = value
		global_volume_changed.emit(value)

signal global_volume_changed(new_value: float)

func _ready() -> void:
	if disabled:
		for child: Node in get_children():
			if child is AudioStreamPlayer:
				child.volume_db = -80.0;


func play_shuffle() -> void:
	$Shuffle.play()


func play_card_draw() -> void:
	$Draw.play()


func play_purchase() -> void:
	$Purchase.play()


func play_buzzer() -> void:
	$Buzzer.play()
