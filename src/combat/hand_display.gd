class_name HandDisplay extends Control;

const MAX_HAND_WIDTH = 512.0
const ROTATION_PER_CARD = 4.0
const CARD_X_SIZE = 192.0
const CARD_Y_SIZE = 256.0
const CARD_PLAY_HEIGHT = 300.0
const CARD_CANCEL_HEIGHT = 40.0

var current_hover: Card = null
var current_hover_return_pos: Vector2
var current_hover_return_rot: float

var current_selected: Card = null
var current_selected_return_pos: Vector2
var current_selected_return_rot: float

var drag_start_position: Vector2
var is_dragging := false

signal unit_spell_selected()
signal card_deselected()

func _input(event: InputEvent) -> void:
	# Try to play current seleceted on left mouse button event
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and current_selected:
		# Always safe to deselect card (for unit raypickable) and clear line2d
		card_deselected.emit()
		is_dragging = false
		$DragLine.clear_points()
		$DragEnd.hide()

		var tried_play_card_and_failed: bool = false
		if event.position.y < $PlayHeight.position.y:
			tried_play_card_and_failed = !(get_parent().try_play_card(current_selected))

		if current_hover != current_selected:
			show_hovered_card()

		if tried_play_card_and_failed:
			place_back_in_hand(current_selected, current_selected_return_pos, current_selected_return_rot, Color.RED)
		else:
			place_back_in_hand(current_selected, current_selected_return_pos, current_selected_return_rot)
		current_selected = null

	if event is InputEventMouseMotion:
		if is_dragging:
			draw_drag_line(event)
		elif current_selected:
			current_selected.global_position = event.position - current_selected.size * current_selected.scale / 2.0


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
	card.unhighlight()


func _on_hand_mana_updated(cur_mana: int, max_mana: int) -> void:
	$ManaDisplay/TextureRect2/Label2.text = str(cur_mana) + "/" + str(max_mana);

	if not current_selected:
		return

	if get_parent().get_node("Hand").can_play(current_selected):
		current_selected.highlight(Color.DARK_GREEN)
	else:
		current_selected.highlight(Color.DIM_GRAY)


func _on_card_clicked(_times_clicked: int, card: Card) -> void:
	if current_selected:
		return

	current_selected = card

	if !card.is_none_spell():
		drag_start_position = card.global_position + card.size * card.scale / 2.0
		is_dragging = true

	if card.is_unit_spell():
		unit_spell_selected.emit()

	if get_parent().get_node("Hand").can_play(current_selected):
		current_selected.highlight(Color.DARK_GREEN)
	else:
		current_selected.highlight(Color.DIM_GRAY)


func _on_card_mouse_entered(card: Card) -> void:
	current_hover = card

	if current_selected:
		return

	show_hovered_card()


func show_hovered_card() -> void:
	if !current_hover:
		return

	current_hover.cancel_tween.emit()
	current_hover.z_index = 1
	current_hover.position.y = -300.0
	current_hover.scale = Vector2(1.3, 1.3)

	update_hand_positions()


func _on_card_mouse_exited(card: Card) -> void:
	current_hover = null;

	if current_selected:
		return

	place_back_in_hand(card, current_hover_return_pos, current_hover_return_rot);


func _on_drop_box_entered() -> void:
	if !current_selected:
		return ;

	place_back_in_hand(current_selected, current_selected_return_pos, current_selected_return_rot)
	current_selected = null


func place_back_in_hand(card: Card, pos: Vector2, rot: float, color_to_highlight_then_unhighlight: Color = Color.WHITE) -> void:
	card.cancel_tween.emit()
	card.z_index = 0
	card.scale = Vector2(1.0, 1.0)
	card.position = pos
	card.rotation = rot
	if color_to_highlight_then_unhighlight != Color.WHITE:
		card.highlight(color_to_highlight_then_unhighlight)
		await get_tree().create_timer(0.5).timeout
	card.unhighlight()


# TODO: Spread around i
func update_hand_positions() -> void:
	# Avoid tween warnings for preloaded combat
	if get_parent().name == "PreloadedCombat":
		return ;

	var hand_size := $HandArea.get_child_count()
	var card_spacing: float = max(CARD_X_SIZE - 12.0 * hand_size, 60.0)
	var hand_width := card_spacing * hand_size
	var current_rotation := -ROTATION_PER_CARD * (hand_size - 1) / 2.0 - ROTATION_PER_CARD

	for i in range(hand_size):
		var card := $HandArea.get_child(i)
		current_rotation += ROTATION_PER_CARD

		var x_pos := i * card_spacing - hand_width / 2.0
		var y_pos := -CARD_Y_SIZE * 1.2
		var center_dist: float = abs(i - (hand_size - 1) / 2.0)
		y_pos += 4.0 * center_dist * center_dist

		var pos := Vector2(x_pos, y_pos)
		var rot := deg_to_rad(current_rotation)

		if card == current_hover:
			current_hover_return_pos = pos
			current_hover_return_rot = rot
		elif card == current_selected:
			current_selected_return_pos = pos
			current_selected_return_rot = rot
		else:
			card.cancel_tween.emit()

			var tween := get_tree().create_tween()
			tween.parallel().tween_property(card, "position", pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.parallel().tween_property(card, "rotation", rot, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			card.cancel_tween.connect(tween.stop)

			# card.position = Vector2(x_pos, y_pos)
			# card.rotation = deg_to_rad(current_rotation)


func draw_drag_line(event: InputEvent) -> void:
	$DragLine.clear_points();
	$DragEnd.show();

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
		var quadriatic: float = -8 * progress * (progress - 1);

		$DragLine.add_point(current_position + normal * quadriatic * 100);

	var drag_end_direction := -1 if direction.x < 0 else 1
	$DragEnd.rotation = direction.angle() + deg_to_rad(50) * drag_end_direction;
	$DragEnd.global_position = current_position;

# Move hover card down a bit
# var hand_size := $HandArea.get_child_count()

# for i in range(hand_size):
# 	var child := $HandArea.get_child(i)

# 	if child != card:
# 		continue

# 	var center_dist: float = abs(i - (hand_size - 1) / 2.0)
# 	card.position.y += 4.0 * center_dist * center_dist
