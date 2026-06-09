extends Node2D

# ==============================
#            NODES
# ==============================

@onready var enemy_manager = $EnemyManager
@onready var wave_manager = $WaveManager
@onready var world = $World
@onready var path: Path2D = $World/Path2D
@onready var tower_container: Node2D = $World/TowerContainer
@onready var wave_timer_label = $UI/RootUI/WaveTimerLabel
@onready var grid: GridManager = $GridManager
@onready var placement: PlacementManager = $PlacementManager
@onready var tower_manager = $TowerManager
@onready var effects_container = $World/EffectsContainer
@onready var card_manager: CardManager = $CardManager
@onready var phenomenon_manager: PhenomenonManager = $PhenomenonManager
@onready var reward_panel = $UI/RootUI/RewardPanel
@onready var reward_container = $UI/RootUI/RewardPanel/RewardContainer
@onready var synergy_manager: SynergyManager = $SynergyManager
@onready var tower_cards_container = $UI/RootUI/TowerCards
@onready var deck_debug_label = $UI/RootUI/DeckDebugLabel
@onready var card_action_panel: CardActionPanel = $UI/RootUI/CardActionPanel
@onready var mulligan_overlay: MulliganOverlay = $UI/RootUI/MulliganOverlay


# ==============================
#            STATE
# ==============================

var mulligan_mode := false
var selected_mulligan_cards: Array = []
var selected_card_ui: TowerCardUI = null
var _is_dragging_card := false

const TOWER_CARD_SCENE = preload("res://scenes/ui/tower_card.tscn")
const IRONCLAD_STARTER = preload("res://resources/decks/ironclad_starter.tres")
const GRUMBOLT_CARD = preload("res://resources/cards/water_cannon_card.tres")
const FROSTWICK_CARD = preload("res://resources/cards/tesla_coil_card.tres")
const MAMA_COG_CARD = preload("res://resources/cards/industrial_fan_card.tres")
const VEGA_CARD = preload("res://resources/cards/vega_card.tres")


# ==============================
#            READY
# ==============================

func _ready():

	var floating_text = preload("res://scenes/ui/floating_text.tscn").instantiate()
	add_child(floating_text)
	floating_text.global_position = Vector2(300, 300)

	RewardManager.reward_panel = reward_panel
	RewardManager.reward_container = reward_container

	card_manager.setup(placement, tower_container, phenomenon_manager)
	card_manager.setup_starting_deck(IRONCLAD_STARTER.cards)

	refresh_hand_ui()

	wave_manager.setup(path, wave_timer_label, enemy_manager, tower_manager)
	placement.setup(grid, tower_container, path, enemy_manager, tower_manager)
	tower_manager.setup(tower_container)
	grid.setup_buildable_cells()

	Player.caps_changed.connect(_on_caps_changed)
	Player.base_hp_changed.connect(_on_base_hp_changed)
	Player.wave_changed.connect(_on_wave_changed)

	_on_wave_changed(Player.current_wave)
	_on_caps_changed(Player.caps)
	_on_base_hp_changed(Player.base_hp)

	tower_manager.towers_changed.connect(synergy_manager.recalculate_synergies)

	card_action_panel.consume_pressed.connect(_on_action_consume)
	card_manager.consume_resolved.connect(_on_consume_resolved)
	mulligan_overlay.validated.connect(_on_mulligan_validated)

	wave_manager.start_prep_phase()


# ==============================
#     DRAG → BUILD
# ==============================

func _on_card_drag_started(card_data: CardData, _card_ui: TowerCardUI):

	if mulligan_mode:
		return

	_deselect_card()
	_is_dragging_card = true
	card_manager.play_card(card_data)


# ==============================
#     TAP → CONSUME PANEL
# ==============================

func _on_card_tapped(card_data: CardData, card_ui: TowerCardUI):

	if mulligan_mode:
		_handle_mulligan_tap(card_ui)
		return

	# Retap sur la carte déjà sélectionnée → désélectionne
	if selected_card_ui == card_ui:
		_deselect_card()
		return

	# Carte sans consume → on ne fait rien (ou on pourrait montrer un feedback)
	if not card_data.can_consume():
		return

	_select_card(card_ui)


func _select_card(card_ui: TowerCardUI):

	if selected_card_ui:
		selected_card_ui.set_selected(false)

	if placement.is_placing():
		placement.cancel_placement()
	if card_manager.is_consuming():
		card_manager.cancel_consume()

	selected_card_ui = card_ui
	selected_card_ui.set_selected(true)

	card_action_panel.show_for_card(card_ui.card_data, card_ui)


func _deselect_card():

	if selected_card_ui:
		selected_card_ui.set_selected(false)
		selected_card_ui = null

	card_action_panel.hide_panel()

	if placement.is_placing():
		placement.cancel_placement()
	if card_manager.is_consuming():
		card_manager.cancel_consume()


# ==============================
#        CONSUME
# ==============================

func _on_action_consume():

	if not selected_card_ui:
		return

	var card_data = selected_card_ui.card_data

	card_action_panel.hide_panel()
	selected_card_ui.set_selected(false)
	selected_card_ui = null

	card_manager.start_consume_placement(card_data)


func _on_consume_resolved(_card_data: CardData, _position: Vector2):

	refresh_hand_ui()


# ==============================
#         INPUT HANDLING
# ==============================

func _input(event: InputEvent):

	var mouse_world = get_global_mouse_position()

	# Escape annule tout (sauf mulligan)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not mulligan_mode:
			_deselect_card()
			_is_dragging_card = false
		return

	# ── Relâche du drag → pose la tour ──────────────────
	if _is_dragging_card and placement.is_placing():

		var released := false

		if event is InputEventMouseButton:
			if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				released = true
		elif event is InputEventScreenTouch:
			if not event.pressed:
				released = true

		if released:
			_is_dragging_card = false
			placement.try_place_tower(mouse_world)
			refresh_hand_ui()
			get_viewport().set_input_as_handled()
			return

	# ── Mode CONSUME actif ───────────────────────────────
	if card_manager.is_consuming():

		card_manager.update_consume_ghost(mouse_world)

		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				card_manager.confirm_consume(mouse_world)
				refresh_hand_ui()
				get_viewport().set_input_as_handled()
				return
			if event.button_index == MOUSE_BUTTON_RIGHT:
				card_manager.cancel_consume()
				get_viewport().set_input_as_handled()
				return

		if event is InputEventScreenTouch and event.pressed:
			card_manager.confirm_consume(mouse_world)
			refresh_hand_ui()
			get_viewport().set_input_as_handled()
			return

		return

	# ── Mode PLACEMENT tour ──────────────────────────────
	if placement.handle_input(event, mouse_world):
		return

	if tower_manager.handle_input(event, mouse_world):
		return


func _unhandled_input(event: InputEvent):

	if mulligan_mode:
		return
	if card_manager.is_consuming() or placement.is_placing() or _is_dragging_card:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_deselect_card()

	if event is InputEventScreenTouch and event.pressed:
		_deselect_card()


func _physics_process(_delta):
	placement.current_mouse_world = get_global_mouse_position()


# ==============================
#          MULLIGAN
# ==============================

func start_mulligan_phase():
	mulligan_mode = true
	selected_mulligan_cards.clear()
	card_manager.mulligan_used = false
	mulligan_overlay.show_phase()


func _on_mulligan_validated():

	if selected_mulligan_cards.size() > 0:
		var cards_to_replace: Array[CardData] = []
		for card_ui in selected_mulligan_cards:
			cards_to_replace.append(card_ui.card_data)
		card_manager.mulligan(cards_to_replace)
		selected_mulligan_cards.clear()

	mulligan_mode = false
	mulligan_overlay.hide_phase()

	refresh_hand_ui()
	wave_manager.force_start_wave()


func _handle_mulligan_tap(card_ui: TowerCardUI):

	if selected_mulligan_cards.has(card_ui):
		selected_mulligan_cards.erase(card_ui)
		card_ui.set_selected(false)
	else:
		if selected_mulligan_cards.size() < 3:
			selected_mulligan_cards.append(card_ui)
			card_ui.set_selected(true)

	mulligan_overlay.update_count(selected_mulligan_cards.size())


# ==============================
#           HAND UI
# ==============================

func refresh_hand_ui():

	_deselect_card()
	_is_dragging_card = false

	for child in tower_cards_container.get_children():
		child.queue_free()

	for card_data in card_manager.hand:
		var card_ui: TowerCardUI = TOWER_CARD_SCENE.instantiate()
		tower_cards_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.card_tapped.connect(_on_card_tapped)
		card_ui.card_drag_started.connect(_on_card_drag_started)

	update_deck_debug()


func update_deck_debug():

	var total = card_manager.draw_pile.size() + card_manager.hand.size()
	deck_debug_label.text = (
		"Deck: %d\nHand: %d\nTotal: %d"
		% [card_manager.draw_pile.size(), card_manager.hand.size(), total]
	)


# ==============================
#            HUD
# ==============================

func _on_wave_changed(value: int):
	$UI/RootUI/TopBar/WaveLabel.text = "Wave : %d" % value

func _on_caps_changed(value: int):
	$UI/RootUI/TopBar/CapsLabel.text = "Caps : %d" % value

func _on_base_hp_changed(value: int):
	$UI/RootUI/TopBar/BaseHpLabel.text = "Base : %d" % value
