extends Node
class_name CardRewardManager

var reward_panel: Control
var reward_card_1: Button
var reward_card_2: Button
var reward_card_3: Button

var reward_selected := false
var reward_cards: Array[RewardData] = []


func _ready():

	print("CARD REWARD READY")


func show_rewards():

	reward_selected = false
	reward_panel.visible = true

	reward_cards = RewardDB.get_random_rewards(3)

	if reward_cards.size() < 3:
		push_error("Not enough rewards loaded")
		return

	reward_card_1.text = reward_cards[0].title + "\n\n" + reward_cards[0].description
	reward_card_2.text = reward_cards[1].title + "\n\n" + reward_cards[1].description
	reward_card_3.text = reward_cards[2].title + "\n\n" + reward_cards[2].description

	print("BTN1=", reward_card_1.text)
	print("BTN2=", reward_card_2.text)
	print("BTN3=", reward_card_3.text)

	if not reward_card_1.pressed.is_connected(_on_reward_card_1_pressed):
		reward_card_1.pressed.connect(_on_reward_card_1_pressed)

	if not reward_card_2.pressed.is_connected(_on_reward_card_2_pressed):
		reward_card_2.pressed.connect(_on_reward_card_2_pressed)

	if not reward_card_3.pressed.is_connected(_on_reward_card_3_pressed):
		reward_card_3.pressed.connect(_on_reward_card_3_pressed)


func select_reward(index: int):

	var reward = reward_cards[index]

	match reward.reward_type:

		RewardData.RewardType.CARD:

			RunDeck.owned_cards.append(
				reward.card_data
			)

			print("ADD CARD :", reward.title)

		RewardData.RewardType.BONUS:

			RunBonuses.add_bonus(
				reward.bonus_data
			)

			print("ADD BONUS :", reward.title)

		RewardData.RewardType.RELIC:

			print("RELIC NOT IMPLEMENTED")


	reward_selected = true
	reward_panel.visible = false


func _on_reward_card_1_pressed():

	print("REWARD 1")

	select_reward(0)


func _on_reward_card_2_pressed():

	print("REWARD 2")

	select_reward(1)


func _on_reward_card_3_pressed():

	print("REWARD 3")

	select_reward(2)
