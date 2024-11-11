class_name HandDisplay extends Control;

const MAX_HAND_WIDTH = 512.0
const ROTATION_PER_CARD = 4.0
const CARD_X_SIZE = 192.0
const CARD_Y_SIZE = 256.0

var current_hover: Card = null
var current_hover_new_position: Vector2
var current_hover_new_rotation: float
var clicked: bool = false

var drag_start_position: Vector2

signal try_play_card(card: Card)

signal targetable_card_selected()
signal card_deselected()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and clicked:
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			card_deselected.emit()
			try_play_card.emit(current_hover)

			$DragLine.clear_points()
			place_back_in_hand()
			clicked = false

	if event is InputEventMouseMotion and clicked:
		draw_drag_line(event)


func _on_hand_drew(card: Card) -> void:
	$HandArea.add_child(card)
	update_hand_positions()
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


func _on_card_clicked(_times_clicked: int, card: Card) -> void:
	clicked = true
	drag_start_position = card.global_position + card.size / 2.0

	if card.type == Card.CardType.SPELL and card.spell.targetable_type != SpellList.TargetableType.NONE:
		targetable_card_selected.emit()


func _on_card_mouse_entered(card: Card) -> void:
	if clicked:
		return

	card.cancel_tween.emit()
	current_hover = card
	card.z_index = 1
	card.position.y = -300.0
	card.scale = Vector2(1.3, 1.3)

	update_hand_positions()


func _on_card_mouse_exited(_card: Card) -> void:
	if clicked:
		return

	place_back_in_hand();


func place_back_in_hand() -> void:
	current_hover.cancel_tween.emit()
	current_hover.z_index = 0
	current_hover.scale = Vector2(1.0, 1.0)
	current_hover.position = current_hover_new_position
	current_hover.rotation = current_hover_new_rotation

	current_hover = null;


func update_hand_positions() -> void:
	var hand_size := $HandArea.get_child_count()
	var card_spacing: float = max(CARD_X_SIZE - 12.0 * hand_size, 60.0)
	var hand_width := card_spacing * hand_size
	var current_rotation := -ROTATION_PER_CARD * (hand_size - 1) / 2.0 - ROTATION_PER_CARD

	# print(card_spacing);

	for i in range(hand_size):
		var card := $HandArea.get_child(i)
		current_rotation += ROTATION_PER_CARD

		var x_pos := i * card_spacing - hand_width / 2.0
		var y_pos := -CARD_Y_SIZE * 1.2
		var center_dist: float = abs(i - (hand_size - 1) / 2.0)
		y_pos += 4.0 * center_dist * center_dist

		if card == current_hover:
			current_hover_new_position = Vector2(x_pos, y_pos)
			current_hover_new_rotation = deg_to_rad(current_rotation)
		else:
			card.position = Vector2(x_pos, y_pos)
			card.rotation = deg_to_rad(current_rotation)


		# var tween := get_tree().create_tween()
		# tween.tween_property(card, "position", Vector2(x_pos, y_pos), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		# card.cancel_tween.connect(tween.stop)

		# tween = get_tree().create_tween()
		# tween.tween_property(card, "rotation", deg_to_rad(current_rotation), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		# card.cancel_tween.connect(tween.stop)


func draw_drag_line(event: InputEvent) -> void:
	$DragLine.clear_points();

	var current_position := drag_start_position;
	var direction := drag_start_position.direction_to(event.position)
	var total_distance := drag_start_position.distance_to(event.position)

	while current_position.distance_to(event.position) > 0.5:
		if current_position.distance_to(event.position) < 10:
			current_position = event.position
		else:
			current_position += direction * 10;

		var normal := Vector2(direction.y, -direction.x);
		if event.position.x < drag_start_position.x:
			normal *= -1;

		var progress: float = current_position.distance_to(drag_start_position) / total_distance;
		var quadriatic: float = -4 * progress * (progress - 1);

		$DragLine.add_point(current_position + normal * quadriatic * 100);

# Move hover card down a bit
# var hand_size := $HandArea.get_child_count()

# for i in range(hand_size):
# 	var child := $HandArea.get_child(i)

# 	if child != card:
# 		continue

# 	var center_dist: float = abs(i - (hand_size - 1) / 2.0)
# 	card.position.y += 4.0 * center_dist * center_dist
