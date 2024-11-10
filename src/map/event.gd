class_name Event extends Control


enum EventType {GET_GOLD, BUFF_CARD}

var type: EventType

signal event_resolved(gold: int)

func _on_get_gold_button_pressed() -> void:
	emit_signal("event_resolved", 10)


func _ready() -> void:
	match type:
		EventType.GET_GOLD:
			$Label.text = "Random event time!"
			$GetGold.show()
		EventType.BUFF_CARD:
			$Label.text = "Buff a card!"
			$BuffCard.show()
		_:
			push_error("Unknown event type", type)
