class_name HandDisplay extends Control;

signal card_clicked(card: Card)

const MAX_HAND_WIDTH = 512.0
const ROTATION_PER_CARD = 4.0
const CARD_X_SIZE = 192.0
const CARD_Y_SIZE = 256.0

var current_hover: Card = null

func _on_card_clicked(_times_clicked: int, card: Card) -> void:
	card_clicked.emit(card)


func _on_hand_drew(card: Card) -> void:
	$HandArea.add_child(card)
	update_hand_positions();
	card.card_clicked.connect(_on_card_clicked)
	card.mouse_entered.connect(_on_card_mouse_entered.bind(card))
	card.mouse_exited.connect(_on_card_mouse_exited.bind(card))


func _on_hand_discarded(card: Card) -> void:
	$HandArea.remove_child(card)
	update_hand_positions()
	card.card_clicked.disconnect(_on_card_clicked)
	card.mouse_entered.disconnect(_on_card_mouse_entered)
	card.mouse_exited.disconnect(_on_card_mouse_exited)


func _on_hand_mana_updated(cur_mana: int, max_mana: int) -> void:
	$ManaDisplay/TextureRect2/Label2.text = str(cur_mana) + "/" + str(max_mana);


func _on_card_mouse_entered(card: Card) -> void:
	current_hover = card
	card.position.y -= 50.0
	card.rotation = 0.0

	update_hand_positions()


func _on_card_mouse_exited(card: Card) -> void:
	if current_hover == card:
		current_hover = null

	update_hand_positions()


func update_hand_positions() -> void:
	var hand_size := $HandArea.get_child_count()

	if current_hover != null:
		hand_size -= 1

	var card_spacing: float = max(CARD_X_SIZE - 12.0 * hand_size, 60.0)
	var hand_width := card_spacing * hand_size
	var current_rotation := -ROTATION_PER_CARD * (hand_size - 1) / 2.0

	# print(card_spacing);

	for i in range(hand_size):
		var card := $HandArea.get_child(i)

		if card == current_hover:
			continue

		var x_pos := i * card_spacing - hand_width / 2.0
		var y_pos := -CARD_Y_SIZE * 1.2
		var center_dist: float = abs(i - (hand_size - 1) / 2.0)
		y_pos += 4.0 * center_dist * center_dist

		var tween := get_tree().create_tween()
		tween.tween_property(card, "position", Vector2(x_pos, y_pos), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween = get_tree().create_tween()
		tween.tween_property(card, "rotation", deg_to_rad(current_rotation), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

		current_rotation += ROTATION_PER_CARD
