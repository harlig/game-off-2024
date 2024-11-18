class_name HandDisplay extends Control;

const MAX_HAND_WIDTH = 512.0
const SPREAD_WIDTH = 80.0
const ROTATION_PER_CARD = 4.0
const CARD_X_SIZE = 192.0
const CARD_Y_SIZE = 256.0
const CARD_PLAY_HEIGHT = 300.0
const CARD_CANCEL_HEIGHT = 40.0

var current_hover: Card = null
var current_selected: Card = null

var drag_start_position: Vector2
var is_dragging := false

signal unit_spell_selected()
signal card_deselected()
signal secret_acknowledged()

func _input(event: InputEvent) -> void:
	# Try to play current selected on left mouse button event
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and current_selected:
		# Always safe to deselect card (for unit raypickable) and clear line2d
		card_deselected.emit()
		var card := current_selected
		current_selected = null

		is_dragging = false
		$DragLine.clear_points()
		$DragEnd.hide()

		var is_in_play_area: bool = event.position.y < $PlayHeight.position.y
		var did_play: bool = is_in_play_area and await get_parent().try_play_card(card)

		if not did_play:
			place_back_in_hand(card, Color.RED if is_in_play_area else Color.WHITE)

		if current_hover != card:
			show_hovered_card()


	if event is InputEventMouseMotion:
		if is_dragging:
			draw_drag_line(event)
		elif current_selected:
			current_selected.global_position = event.position - current_selected.size * current_selected.scale / 2.0
			if event.position.y >= $PlayHeight.position.y:
				current_selected.highlight(Color.DARK_GRAY)
			else:
				highlight_current_card()


func _on_hand_drew(card: Card, insert_at: int = -1) -> void:
	$HandArea.add_child(card)

	if insert_at >= 0:
		$HandArea.move_child(card, insert_at)

	card.card_clicked.connect(_on_card_clicked)
	card.mouse_entered.connect(_on_card_mouse_entered.bind(card))
	card.mouse_exited.connect(_on_card_mouse_exited.bind(card))

	update_hand_positions();


func _on_hand_discarded(card: Card) -> void:
	card.card_clicked.disconnect(_on_card_clicked)
	card.mouse_entered.disconnect(_on_card_mouse_entered)
	card.mouse_exited.disconnect(_on_card_mouse_exited)
	card.unhighlight()

	$HandArea.remove_child(card)

	update_hand_positions();


func _on_hand_mana_updated(cur_mana: int, max_mana: int) -> void:
	$ManaDisplay/TextureRect2/Label2.text = str(cur_mana) + "/" + str(max_mana);
	if not current_selected:
		return
	highlight_current_card()


func highlight_current_card() -> void:
	if get_parent().get_node("Hand").can_play(current_selected):
		current_selected.highlight(Color.DARK_GREEN)
	else:
		current_selected.highlight(Color.RED)


func _on_card_clicked(_times_clicked: int, card: Card) -> void:
	# when secrets are presented, don't handle input from these
	if current_selected || get_tree().paused:
		return

	current_selected = card

	if !card.is_none_spell():
		drag_start_position = card.global_position + card.size * card.scale / 2.0
		is_dragging = true

	if card.is_unit_spell():
		unit_spell_selected.emit()

	highlight_current_card()


func _on_card_mouse_entered(card: Card) -> void:
	# when secrets are presented, don't handle input from these
	if get_tree().paused:
		return
	current_hover = card

	if current_selected:
		return

	show_hovered_card()


func show_hovered_card() -> void:
	if !current_hover:
		return

	update_hand_positions()

	current_hover.z_index = 1
	current_hover.position = get_card_position(current_hover.get_index())
	current_hover.rotation = get_card_rotation(current_hover.get_index())
	tween_card_to(current_hover, Vector2(current_hover.position.x, -300.0), current_hover.rotation, Vector2(1.3, 1.3), 0.2)


func _on_card_mouse_exited(card: Card) -> void:
	# when secrets are presented, don't handle input from these
	if get_tree().paused:
		return
	current_hover = null;

	if current_selected:
		return

	update_hand_positions();
	place_back_in_hand(card);


func _on_drop_box_entered() -> void:
	if !current_selected:
		return ;

	place_back_in_hand(current_selected)
	current_selected = null


func place_back_in_hand(card: Card, color_to_highlight_then_unhighlight: Color = Color.WHITE) -> void:
	card.z_index = 0
	var pos := get_card_position(card.get_index())
	var rot := get_card_rotation(card.get_index())
	tween_card_to(card, pos, rot, Vector2.ONE, 0.2)

	if color_to_highlight_then_unhighlight != Color.WHITE:
		card.highlight(color_to_highlight_then_unhighlight)
		await get_tree().create_timer(0.5).timeout

	card.unhighlight()


# TODO: Spread around i
func update_hand_positions() -> void:
	# Avoid tween warnings for preloaded combat
	if get_parent().name == "PreloadedCombat":
		return ;

	for i in range($HandArea.get_child_count()):
		var card := $HandArea.get_child(i)
		var pos := get_card_position(i)
		var rot := get_card_rotation(i)

		if card not in [current_hover, current_selected]:
			tween_card_to(card, pos, rot, Vector2.ONE, 0.5);


func get_card_position(ind: int) -> Vector2:
	var hand_size := $HandArea.get_child_count()
	var card_spacing: float = max(CARD_X_SIZE - 12.0 * hand_size, 60.0)
	var hand_width := card_spacing * hand_size

	var do_spread := current_hover or current_selected
	var passed_hover := (current_hover and ind > current_hover.get_index()) or (current_selected and ind > current_selected.get_index())

	var x_pos := ind * card_spacing - hand_width / 2.0
	if do_spread and not passed_hover:
		x_pos -= SPREAD_WIDTH
	elif do_spread and passed_hover:
		x_pos += SPREAD_WIDTH

	var y_pos := -CARD_Y_SIZE * 1.2
	var center_dist: float = abs(ind - (hand_size - 1) / 2.0)
	y_pos += 4.0 * center_dist * center_dist

	var card := $HandArea.get_child(ind)
	var pos := Vector2(x_pos, y_pos)
	if card == current_hover or card == current_selected:
		pos += Vector2(SPREAD_WIDTH, 0.0)

	return pos


func get_card_rotation(ind: int) -> float:
	var hand_size := $HandArea.get_child_count()
	var current_rotation := -ROTATION_PER_CARD * (hand_size - 1) / 2.0 - ROTATION_PER_CARD

	for i in range(hand_size):
		current_rotation += ROTATION_PER_CARD

		if i == ind:
			break

	return deg_to_rad(current_rotation)


func tween_card_to(card: Card, pos: Vector2, rot: float, scele: Vector2, time: float, use_global_position: bool = false) -> Tween:
		card.cancel_tween.emit()

		var tween := create_tween()
		tween.parallel().tween_property(card, "position" if not use_global_position else "global_position", pos, time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(card, "rotation", rot, time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(card, "scale", scele, time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		card.cancel_tween.connect(tween.stop)
		return tween


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
	$DragEnd.rotation = direction.angle() + deg_to_rad(65) * drag_end_direction;
	$DragEnd.global_position = current_position;


func reveal_secret(card: Card) -> void:
	var x_pos: float = global_position.x + (size.x) / 2.0 - CARD_X_SIZE / 2.0
	var y_pos: float = global_position.y + (size.y) / 2.0 - CARD_Y_SIZE / 2.0
	var tween: Tween = tween_card_to(card, Vector2(x_pos, y_pos), 0.0, Vector2(1.0, 1.0), 1.5, true)
	await tween.finished

	card.is_secret_releaved = true
	card.update_display()

	$ContinueButton.show()
	await $ContinueButton.pressed
	$ContinueButton.hide()

	secret_acknowledged.emit()

# Move hover card down a bit
# var hand_size := $HandArea.get_child_count()

# for i in range(hand_size):
# 	var child := $HandArea.get_child(i)

# 	if child != card:
# 		continue

# 	var center_dist: float = abs(i - (hand_size - 1) / 2.0)
# 	card.position.y += 4.0 * center_dist * center_dist
