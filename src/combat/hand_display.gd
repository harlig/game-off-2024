class_name HandDisplay extends Control;

signal card_clicked(card: Card)


func _on_card_clicked(_times_clicked: int, card: Card) -> void:
    card_clicked.emit(card)


func _on_hand_drew(card: Card) -> void:
    $CardsArea.add_child(card)
    card.card_clicked.connect(_on_card_clicked)


func _on_hand_discarded(card: Card) -> void:
    $CardsArea.remove_child(card)
    card.card_clicked.disconnect(_on_card_clicked)


func _on_hand_mana_updated(cur_mana: int, max_mana: int) -> void:
    $ManaDisplay/TextureRect2/Label2.text = str(cur_mana) + "/" + str(max_mana);
