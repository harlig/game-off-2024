class_name Run extends Control

const between_combat_scene := preload("res://src/between_combat.tscn")
const BETWEEN_COMBAT_OFFSET := 56

const COMBATS_TO_BEAT := 5

@onready var camera := $Camera3D
@onready var deck := $DeckControl/Deck
@onready var relic_area := $RelicArea
@onready var bank_control := $BankControl

var combat_difficulty := 1
var combats_beaten := 0
var main_menu: Menu
var audio: Audio

var bank := 50:
	set(value):
		bank = value
		bank_control.get_node("Value").text = str(value)
var times_card_removed := 0

# TODO: do we even want relics?
var relics: Array[Relic] = [
# 	Relic.create_relic("Health Relic", "When you spawn a unit, give it +5 max hp", "res://textures/relic/health_secret.jpg", [Card.CardType.UNIT]),
# 	Relic.create_relic("Spells Mana Relic", "Your spells each cost -1 mana", "res://textures/relic/mana_secret.jpg", [Card.CardType.SPELL]),
	# Relic.create_relic("Torchlighter Relic", "Your first hand of each combat will always draw a Torchlighter", "res://textures/relic/torchlighter_secret.png", []),
]

var time_for_preload := 0.5
var time_spent := 0.0
var has_preloaded := false
var current_combat: Combat

func _ready() -> void:
	# kinda janky but guarantees that the bank's text will get updated to its starting value
	bank = bank

	audio = main_menu.audio
	$Settings.audio = audio

	# preload a combat to try to reduce stuttering
	var preloaded_combat: Combat = Combat.create_combat($DeckControl/Deck, combat_difficulty, audio, relics, combats_beaten)
	preloaded_combat.name = "PreloadedCombat"
	preloaded_combat.hide()
	add_child(preloaded_combat)

	# TODO: create a between combat and a next between combat
	var between_combat: BetweenCombat
	between_combat = BetweenCombat.create_between_combat(BetweenCombat.Type.START, combat_difficulty, bank, deck, times_card_removed, audio, combats_beaten)
	between_combat.continue_pressed.connect(continue_to_next_combat.bind(between_combat))
	between_combat.get_node("Continue").hide()
	between_combat.card_removed.connect(_on_card_removed)
	add_child(between_combat)
	between_combat.put_in_focus()

func _process(delta: float) -> void:
	if has_preloaded:
		return
	if OS.has_feature("editor"):
		has_preloaded = true
		$PreloadedCombat.queue_free()
		$Loading.hide()

	time_spent += delta
	print("Preloading combat maybe - time spent waiting: ", time_spent)
	if time_spent > time_for_preload:
		has_preloaded = true
		await get_tree().create_timer(0.1).timeout
		$PreloadedCombat.show()

		await get_tree().create_timer(0.1).timeout
		$PreloadedCombat.queue_free()

		await get_tree().create_timer(0.1).timeout
		$Loading.hide()

		print("has done preloaded shit")

func create_combat() -> Combat:
	var new_combat: Combat = Combat.create_combat(deck, combat_difficulty, audio, relics, combats_beaten)
	current_combat = new_combat
	new_combat.get_node("ViewDeckButton").hide()

	new_combat.reward_presented.connect(_on_reward_presented)
	new_combat.reward_chosen.connect(_on_combat_reward_chosen)
	new_combat.rewards_done.connect(_on_combat_rewards_done)
	new_combat.combat_over.connect(_on_combat_over)

	add_child(new_combat)
	return new_combat

func _on_reward_presented() -> void:
	bank_control.show()
	$MenuButton.hide()

func _on_combat_over(combat_state: Combat.CombatState) -> void:
	var existing_combat := current_combat
	current_combat = null

	# on combat won, create a shop and go right
	# on combat lose, create a retry and go left
	if combat_state == Combat.CombatState.WON:
		combat_difficulty += 1
		combats_beaten += 1
		var between_combat: BetweenCombat
		if combats_beaten == COMBATS_TO_BEAT:
			between_combat = BetweenCombat.create_between_combat(BetweenCombat.Type.END, combat_difficulty, bank, deck, times_card_removed, audio, combats_beaten, true)
			between_combat.continue_pressed.connect(continue_to_menu)
		else:
			between_combat = BetweenCombat.create_between_combat(BetweenCombat.Type.SHOP, combat_difficulty, bank, deck, times_card_removed, audio, combats_beaten, true)
			between_combat.continue_pressed.connect(continue_to_next_combat.bind(between_combat))
			between_combat.item_purchased.connect(_on_item_purchased)
		between_combat.get_node("Continue").hide()
		between_combat.card_removed.connect(_on_card_removed)
		add_child(between_combat)

		between_combat.position = Vector3(existing_combat.position.x + BETWEEN_COMBAT_OFFSET, between_combat.position.y, between_combat.position.z)

		var tween: Tween = get_tree().create_tween();
		tween.parallel().tween_property(existing_combat, "position", Vector3(existing_combat.position.x - BETWEEN_COMBAT_OFFSET, existing_combat.position.y, existing_combat.position.z), 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(existing_combat.get_node("Backdrop/DirectionalLight3D"), "light_energy", 0.0, 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(between_combat, "position", Vector3(existing_combat.position.x, between_combat.position.y, between_combat.position.z), 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		between_combat.put_in_focus()
	elif combat_state == Combat.CombatState.LOST:
		var between_combat: BetweenCombat = BetweenCombat.create_between_combat(BetweenCombat.Type.RETRY, combat_difficulty, bank, deck, times_card_removed, audio, combats_beaten, false)
		between_combat.continue_pressed.connect(continue_to_next_combat.bind(between_combat))
		between_combat.game_lost.connect(continue_to_menu)
		add_child(between_combat)

		between_combat.position = Vector3(existing_combat.position.x - BETWEEN_COMBAT_OFFSET, between_combat.position.y, between_combat.position.z)

		var tween: Tween = get_tree().create_tween();
		tween.parallel().tween_property(existing_combat, "position", Vector3(existing_combat.position.x + BETWEEN_COMBAT_OFFSET, existing_combat.position.y, existing_combat.position.z), 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
		# tween.parallel().tween_property(between_combat.get_node("Backdrop/DirectionalLight3D"), "light_energy", 0.0, 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT) # SHOULD WE TWEEN HERE?
		tween.parallel().tween_property(between_combat, "position", Vector3(existing_combat.position.x, between_combat.position.y, between_combat.position.z), 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		between_combat.put_in_focus()
	existing_combat.queue_free()

func continue_to_next_combat(between_combat: BetweenCombat) -> void:
	bank_control.hide()
	var offset := 56
	get_tree().paused = true
	var new_combat := create_combat()
	new_combat.position = Vector3(between_combat.position.x + offset, new_combat.position.y, new_combat.position.z)
	new_combat.get_node("Opponent").should_spawn = false
	new_combat.get_node("HandDisplay").hide()

	var tween: Tween = get_tree().create_tween();
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TweenPauseMode.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(between_combat, "position", Vector3(between_combat.position.x - offset, between_combat.position.y, between_combat.position.z), 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(between_combat.get_node("Backdrop/DirectionalLight3D"), "light_energy", 0.0, 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(new_combat, "position", Vector3(between_combat.position.x, new_combat.position.y, new_combat.position.z), 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	between_combat.queue_free()
	new_combat.get_node("HandDisplay").show()
	get_tree().paused = false

	await new_combat.countdown_combat()

	new_combat.get_node("ViewDeckButton").show()
	new_combat.get_node("Opponent").should_spawn = true
	$MenuButton.show()


func continue_to_menu() -> void:
	main_menu.show()
	queue_free()


func _on_combat_reward_chosen(reward: Reward.RewardData) -> void:
	if reward.type == Reward.RewardData.Type.CARD:
		deck.add_card(reward.card)
		audio.play_shuffle()
	elif reward.type == Reward.RewardData.Type.GOLD:
		bank += reward.gold
		audio.play_purchase()

func _on_combat_rewards_done() -> void:
	current_combat.reward.queue_free()

func _on_item_purchased(item: Card, cost: int) -> void:
	deck.add_card(item)
	bank -= cost
	# TODO: support items other than cards
	# if item.type == Shop.Item.Type.CARD:
	# 	deck.add_card(item.card)
	# else:
	# 	push_warning("Item type not supported yet")


func _on_card_removed(cost: int) -> void:
	times_card_removed += 1
	bank -= cost


func _on_menu_button_pressed() -> void:
	$Settings.show()
	if current_combat:
		current_combat.hide_elements_for_pause()
	get_tree().paused = true


func _on_settings_back_pressed() -> void:
	$Settings.hide()
	if current_combat:
		current_combat.show_elements_for_pause()
	get_tree().paused = false
