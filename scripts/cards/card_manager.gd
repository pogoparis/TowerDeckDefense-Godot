class_name CardManager
extends Node

var placement_manager: PlacementManager
var phenomenon_manager: PhenomenonManager
var tower_container: Node2D

var refill_hand_size := 3
var max_hand_size := 4

var draw_pile   : Array[CardData] = []
var hand        : Array[CardData] = []
var discard_pile: Array[CardData] = []

# ==================================================
# CONSUME STATE
# ==================================================

var _consume_card: CardData = null
var _consume_ghost: Node2D = null

signal consume_mode_started(card_data)
signal consume_mode_cancelled
signal consume_resolved(card_data, position)

func is_consuming() -> bool:
	return _consume_card != null


func start_consume_placement(card: CardData):

	if not card.can_consume():
		return

	var real_cost: int = max(0, card.consume_cost - RunBonuses.get_consume_cost_reduction())
	if Player.caps < real_cost:
		print("NOT ENOUGH CAPS TO CONSUME")
		return

	_consume_card = card

	_spawn_consume_ghost()

	consume_mode_started.emit(card)


func _spawn_consume_ghost():

	if _consume_ghost:
		_consume_ghost.queue_free()

	_consume_ghost = Node2D.new()

	var circle := ColorRect.new()
	var r := _consume_card.consume_radius
	circle.size = Vector2(r * 2.0, r * 2.0)
	circle.position = Vector2(-r, -r)

	match _consume_card.consume_phenomenon_type:
		PhenomenonType.Type.WATER_POOL:
			circle.color = Color(0.2, 0.5, 1.0, 0.35)
		PhenomenonType.Type.ELECTRIC_FIELD:
			circle.color = Color(0.9, 0.9, 0.2, 0.35)
		_:
			circle.color = Color(1.0, 1.0, 1.0, 0.30)

	_consume_ghost.add_child(circle)
	_consume_ghost.z_index = 998

	get_tree().current_scene.add_child(_consume_ghost)


func update_consume_ghost(world_position: Vector2):

	if _consume_ghost:
		_consume_ghost.global_position = world_position


func confirm_consume(world_position: Vector2):

	if not is_consuming():
		return

	var real_cost: int = max(0, _consume_card.consume_cost - RunBonuses.get_consume_cost_reduction())
	if not Player.spend_caps(real_cost):
		cancel_consume()
		return

	phenomenon_manager.spawn_phenomenon(
		_consume_card.consume_phenomenon_type,
		world_position,
		_consume_card.consume_radius,
		_consume_card.consume_duration
	)

	var resolved_card := _consume_card

	consume_card(resolved_card)

	_clear_consume()

	consume_resolved.emit(resolved_card, world_position)


func cancel_consume():

	_clear_consume()

	consume_mode_cancelled.emit()


func _clear_consume():

	if _consume_ghost:
		_consume_ghost.queue_free()
		_consume_ghost = null

	_consume_card = null


# ==================================================
# MULLIGAN
# ==================================================

var mulligan_used := false

func can_use_mulligan() -> bool:
	return not mulligan_used


func mulligan(cards_to_replace: Array[CardData]):

	if mulligan_used:
		return

	if cards_to_replace.is_empty():
		return

	for card in cards_to_replace:

		if hand.has(card):

			hand.erase(card)
			draw_pile.append(card)

	draw_pile.shuffle()

	draw_to_hand(cards_to_replace.size())

	mulligan_used = true


# ==================================================
# SETUP
# ==================================================

func setup(
	new_placement_manager: PlacementManager,
	new_tower_container: Node2D,
	new_phenomenon_manager: PhenomenonManager
):

	placement_manager = new_placement_manager
	tower_container = new_tower_container
	phenomenon_manager = new_phenomenon_manager


func setup_starting_deck(cards: Array):

	draw_pile.clear()
	hand.clear()
	discard_pile.clear()

	mulligan_used = false

	for card in cards:
		draw_pile.append(card)

	draw_pile.shuffle()

	draw_to_hand(3)


# ==================================================
# DRAW
# ==================================================

func draw_to_hand(amount: int):

	for i in amount:

		# Si la pioche est vide, on recycle la défausse
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()

		var card = draw_pile.pop_back()
		hand.append(card)


func draw_until_full_hand():

	var missing_cards = refill_hand_size - hand.size()

	if missing_cards <= 0:
		return

	draw_to_hand(missing_cards)


# ==================================================
# DECK MANAGEMENT
# ==================================================

func add_reward_card(card: CardData):

	if hand.size() < max_hand_size:

		hand.append(card)

	else:

		draw_pile.append(card)


func add_card(card: CardData):

	if card == null:
		return

	hand.append(card)


func consume_card(card: CardData):

	if card == null:
		return

	if hand.has(card):
		hand.erase(card)
		discard_pile.append(card)


# ==================================================
# PLAY (BUILD)
# ==================================================

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
