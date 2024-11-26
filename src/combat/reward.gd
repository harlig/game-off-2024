class_name Reward extends Control

signal reward_chosen(reward: RewardData)
signal rewards_done()

var combat_beaten_gold := 25:
	set(value):
		combat_beaten_gold = value
		$AllRewards/RewardsContainer/RewardsArea/Gold.text = "+%d gold" % combat_beaten_gold
var reward_skipped_gold: int = 50:
	set(value):
		reward_skipped_gold = value
		$SelectCard/SkipButton.text = "Skip\n(+%dg)" % reward_skipped_gold

var got_combat_gold_reward := false
var got_select_card_reward := false

class RewardData:
	enum Type {CARD, GOLD}

	var type: Type
	var card: Card = null
	var gold: int = 0

	static func for_card(reward_card: Card) -> RewardData:
		var reward_data := RewardData.new()
		reward_data.type = Type.CARD
		reward_data.card = reward_card
		return reward_data

	static func for_gold(reward_gold: int) -> RewardData:
		var reward_data := RewardData.new()
		reward_data.type = Type.GOLD
		reward_data.gold = reward_gold
		return reward_data

func _ready() -> void:
	combat_beaten_gold = combat_beaten_gold
	reward_skipped_gold = reward_skipped_gold


func add_card_offerings(cards: Array[Card]) -> void:
	for enemy_card: Card in cards:
		var card_offered := Card.duplicate_card(enemy_card)
		card_offered.connect("card_clicked", _on_reward_clicked)
		card_offered.mouse_entered.connect(_on_card_mouse_entered.bind(card_offered))
		card_offered.mouse_exited.connect(_on_card_mouse_exited.bind(card_offered))
		$SelectCard/Offers.add_child(card_offered)

func _on_card_mouse_entered(card: Card) -> void:
	card.highlight(Color.DARK_GREEN)

func _on_card_mouse_exited(card: Card) -> void:
	card.unhighlight()


func _on_reward_clicked(_times_clicked: int, reward_card: Card) -> void:
	reward_card.unhighlight()
	reward_card.reset_selected()
	reward_chosen.emit(RewardData.for_card(reward_card))
	got_select_card_reward = true
	finish_this_reward()


func _on_skip_button_pressed() -> void:
	reward_chosen.emit(RewardData.for_gold(reward_skipped_gold))
	got_select_card_reward = true
	finish_this_reward()


func _on_gold_pressed() -> void:
	reward_chosen.emit(RewardData.for_gold(combat_beaten_gold))
	got_combat_gold_reward = true
	$AllRewards/RewardsContainer/RewardsArea/Gold.hide()
	$AllRewards/RewardsContainer/RewardsArea/BlankGold.show()
	finish_this_reward()

func finish_this_reward() -> void:
	if got_combat_gold_reward and got_select_card_reward:
		rewards_done.emit()
		return
	$SelectCard.hide()
	$AllRewards.show()


func _on_card_pressed() -> void:
	$AllRewards/RewardsContainer/RewardsArea/Card.hide()
	$AllRewards/RewardsContainer/RewardsArea/BlankCard.show()
	$AllRewards.hide()
	$SelectCard.show()
