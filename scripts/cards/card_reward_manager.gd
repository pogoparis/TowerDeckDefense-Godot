extends Node
class_name CardRewardManager

var reward_panel: Control
var reward_card_1: Button
var reward_card_2: Button
var reward_card_3: Button
var reward_selected := false
var reward_cards: Array[CardData] = []

func _ready():

	print("CARD REWARD READY")

func show_rewards():

	reward_selected = false
	reward_panel.visible = true

	reward_cards.clear()

	reward_cards.append(preload("res://resources/cards/grumbolt_card.tres"))
	reward_cards.append(preload("res://resources/cards/frostwick_card.tres"))
	reward_cards.append(preload("res://resources/cards/mama_cog_card.tres"))

	reward_card_1.text = reward_cards[0].card_name
	reward_card_2.text = reward_cards[1].card_name
	reward_card_3.text = reward_cards[2].card_name

	if not reward_card_1.pressed.is_connected(_on_reward_card_1_pressed):
		reward_card_1.pressed.connect(_on_reward_card_1_pressed)

	if not reward_card_2.pressed.is_connected(_on_reward_card_2_pressed):
		reward_card_2.pressed.connect(_on_reward_card_2_pressed)

	if not reward_card_3.pressed.is_connected(_on_reward_card_3_pressed):
		reward_card_3.pressed.connect(_on_reward_card_3_pressed)

func select_reward(index: int):

	var card = reward_cards[index]

	RunDeck.owned_cards.append(card)

	print("ADD CARD :", card.card_name)

	reward_selected = true
	reward_panel.visible = false

func _on_reward_card_1_pressed():

	print("REWARD 1")

	RewardManager.select_reward(0)

func _on_reward_card_2_pressed():
	RewardManager.select_reward(1)

func _on_reward_card_3_pressed():
	RewardManager.select_reward(2)
