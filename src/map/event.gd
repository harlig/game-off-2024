class_name Event extends Control


signal event_resolved(gold: int)

func _on_button_pressed() -> void:
	emit_signal("event_resolved", 10)
