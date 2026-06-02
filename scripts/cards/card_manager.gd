class_name CardManager
extends Node

var placement_manager: PlacementManager
var tower_container: Node2D

var refill_hand_size := 3
var max_hand_size := 4

var draw_pile : Array[CardData] = []
var hand : Array[CardData] = []

func setup(
	new_placement_manager: PlacementManager,
	new_tower_container: Node2D
):

	placement_manager = new_placement_manager
	tower_container = new_tower_container


func setup_starting_deck(cards: Array):

	draw_pile.clear()
	hand.clear()

	draw_pile.clear()

	for card in cards:
		draw_pile.append(card)

	draw_pile.shuffle()

	draw_to_hand(3)


func draw_to_hand(amount: int):

	for i in amount:

		if draw_pile.is_empty():
			return

		var card = draw_pile.pop_back()

		hand.append(card)

		print("DRAW : ", card.card_name)


func draw_until_full_hand():

	var missing_cards = max_hand_size - hand.size()

	if missing_cards <= 0:
		return

	draw_to_hand(missing_cards)

func add_reward_card(card: CardData):
	print("ADD REWARD CARD CALLED")
	if hand.size() < max_hand_size:

		hand.append(card)

		print("REWARD CARD -> HAND : ", card.card_name)

	else:

		draw_pile.append(card)

		print("REWARD CARD -> DRAW PILE : ", card.card_name)

func add_card(card: CardData):

	if card == null:
		return

	hand.append(card)

	print("CARD ADDED : ", card.card_name)


func consume_card(card: CardData):

	if card == null:
		return

	if hand.has(card):

		hand.erase(card)

		print("CARD CONSUMED : ", card.card_name)

		print("HAND SIZE : ", hand.size())

		print("DECK SIZE : ", draw_pile.size())


func play_card(card: CardData):

	match card.card_type:

		CardData.CardType.TOWER:

			if Player.caps < card.mana_cost:

				print("NOT ENOUGH CAPS")

				return

			placement_manager.start_tower_placement(
				card.tower_scene,
				card,
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
