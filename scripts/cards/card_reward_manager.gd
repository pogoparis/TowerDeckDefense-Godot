extends Node
class_name CardRewardManager

var reward_panel: Control
var reward_card_1: Button
var reward_card_2: Button
var reward_card_3: Button
var reward_selected := false

func show_rewards():

	reward_selected = false

	reward_panel.visible = true

	reward_card_1.text = "Grumbolt"
	reward_card_2.text = "Frostwick"
	reward_card_3.text = "Mama Cog"

func select_reward():

	reward_selected = true
	reward_panel.visible = false

func _on_reward_card_1_pressed():

	RewardManager.select_reward()

func _on_reward_card_2_pressed():

	RewardManager.select_reward()

func _on_reward_card_3_pressed():

	RewardManager.select_reward()
