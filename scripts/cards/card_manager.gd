class_name CardManager
extends Node

var placement_manager: PlacementManager
var tower_container: Node2D

func setup(
	new_placement_manager: PlacementManager,
	new_tower_container: Node2D
):

	placement_manager = new_placement_manager
	tower_container = new_tower_container

func play_card(card: CardData):
	
	match card.card_type:

		CardData.CardType.TOWER:
			placement_manager.start_tower_placement(
				card.tower_scene,
				tower_container
			)

		CardData.CardType.SPELL:

			print("TODO SPELL:", card.card_name)

		CardData.CardType.UPGRADE:

			print("TODO UPGRADE:", card.card_name)

		CardData.CardType.TACTIC:

			print("TODO TACTIC:", card.card_name)

		CardData.CardType.ECONOMY:

			print("TODO ECONOMY:", card.card_name)

		CardData.CardType.RELIC:

			print("TODO RELIC:", card.card_name)
