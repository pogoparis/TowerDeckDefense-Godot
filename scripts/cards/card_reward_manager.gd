extends Node
class_name CardRewardManager

var reward_panel: Control
var reward_card_1: Button
var reward_card_2: Button
var reward_card_3: Button

func show_rewards():

	print("Panel=", reward_panel)
	print("Card1=", reward_card_1)
	print("Card2=", reward_card_2)
	print("Card3=", reward_card_3)

	if reward_card_1 == null:
		print("CARD1 NULL")
		return

	reward_panel.visible = true

	reward_card_1.text = "Grumbolt"
	reward_card_2.text = "Frostwick"
	reward_card_3.text = "Mama Cog"
	
	reward_card_1.modulate = Color.RED
	reward_card_2.modulate = Color.GREEN
	reward_card_3.modulate = Color.BLUE
