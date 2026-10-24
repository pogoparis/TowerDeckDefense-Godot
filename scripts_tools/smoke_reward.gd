extends Node
## Fumigène : accorde une récompense CARTE et suit où elle atterrit.
## Reproduit le cas signalé — « j'ai choisi le Punk de Feu et il n'est pas
## arrivé dans ma main » — dans les deux états possibles de la main.

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Runner.new())


class Runner extends Node:
	func _ready() -> void:
		Progress.current_level_id = 3
		Progress.selected_deck = null
		get_tree().change_scene_to_file("res://scenes/ui/level.tscn")
		await get_tree().create_timer(2.0).timeout

		var scene := get_tree().current_scene
		var cm = scene.card_manager
		var card = load("res://resources/cards/fire_punk_card.tres")

		print("max_hand_size=", cm.max_hand_size, "  refill=", cm.refill_hand_size)

		for scenario in ["main a 3", "main pleine"]:
			# On repart d'une main connue pour chaque scénario.
			while cm.hand.size() > 3:
				cm.discard_card(cm.hand[0])
			cm.draw_to_hand(3 - cm.hand.size())
			if scenario == "main pleine":
				cm.draw_to_hand(cm.max_hand_size - cm.hand.size())

			var before: int = cm.hand.size()
			var reward := RewardData.new()
			reward.reward_type = RewardData.RewardType.CARD
			reward.card_data = card
			reward.title = card.card_name

			# select_reward() lit reward_cards : on rejoue le vrai chemin,
			# pas un raccourci qui contournerait justement le bug.
			RewardManager.reward_cards = [reward] as Array[RewardData]
			RewardManager.select_reward(0)
			await get_tree().process_frame
			await get_tree().process_frame

			var in_hand := 0
			for c in cm.hand:
				if c != null and c.card_name == card.card_name:
					in_hand += 1
			var in_draw := 0
			for c in cm.draw_pile:
				if c != null and c.card_name == card.card_name:
					in_draw += 1
			var affiches: int = scene.tower_cards_container.get_child_count()

			print("%-12s | main %d -> %d | %s en main:%d, en pioche:%d | cartes affichees:%d"
				% [scenario, before, cm.hand.size(), card.card_name,
				   in_hand, in_draw, affiches])

		get_tree().quit()
