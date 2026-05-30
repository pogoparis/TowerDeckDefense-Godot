extends Node
class_name CardRewardManager

var reward_panel: Control
var reward_container

var reward_card_scene := preload(
	"res://scenes/ui/reward_card.tscn"
)

var reward_selected := false
var reward_cards: Array[RewardData] = []

func show_rewards():

	reward_selected = false
	reward_panel.visible = true

	clear_rewards()

	reward_cards = RewardDB.get_random_rewards(3)

	if reward_cards.size() < 3:
		push_error("Not enough rewards loaded")
		return

	for reward in reward_cards:

		var card = reward_card_scene.instantiate()

		reward_container.add_child(card)

		card.setup(reward)
		
		card.reward_clicked.connect(_on_reward_selected)
		
func select_reward(index: int):

	var reward = reward_cards[index]

	match reward.reward_type:

		RewardData.RewardType.CARD:

			RunDeck.owned_cards.append(
				reward.card_data
			)

		RewardData.RewardType.BONUS:

			RunBonuses.add_bonus(
				reward.bonus_data
			)


		RewardData.RewardType.RELIC:

			print("RELIC NOT IMPLEMENTED")


	reward_selected = true
	reward_panel.visible = false

func clear_rewards():

	for child in reward_container.get_children():
		child.queue_free()

func _on_reward_selected(reward: RewardData):

	var index := reward_cards.find(reward)

	if index != -1:
		select_reward(index)
