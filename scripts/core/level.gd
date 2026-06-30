extends Node2D

# ==============================
#            NODES
# ==============================

@onready var enemy_manager = $EnemyManager
@onready var wave_manager = $WaveManager
@onready var world = $World
@onready var background: Sprite2D = $World/Background
@onready var path: Path2D = $World/Path2D
@onready var tower_container: Node2D = $World/TowerContainer
@onready var grid: GridManager = $GridManager
@onready var placement: PlacementManager = $PlacementManager
@onready var tower_manager = $TowerManager
@onready var effects_container = $World/EffectsContainer
@onready var card_manager: CardManager = $CardManager
@onready var phenomenon_manager: PhenomenonManager = $PhenomenonManager
@onready var reward_panel = $UI/RootUI/RewardPanel
@onready var reward_container = $UI/RootUI/RewardPanel/VBox/RewardContainer
@onready var synergy_manager: SynergyManager = $SynergyManager
@onready var tower_cards_container = $UI/RootUI/TowerCards
@onready var deck_debug_label = $UI/RootUI/DeckDebugLabel
@onready var card_action_panel: CardActionPanel = $UI/RootUI/CardActionPanel
@onready var mulligan_overlay: MulliganOverlay = $UI/RootUI/MulliganOverlay
@onready var wave_preview: WavePreview = $UI/RootUI/WavePreview
@onready var top_hud: TopHUD = $UI/RootUI/TopHUD
@onready var pause_menu:      PauseMenu      = $UI/RootUI/PauseMenu
@onready var game_over_screen: GameOverScreen = $UI/RootUI/GameOverScreen
@onready var tutorial_overlay: TutorialOverlay = $UI/RootUI/TutorialOverlay
@onready var tutorial_banner: Label = $UI/RootUI/TutorialBanner
@onready var tutorial_director: TutorialDirector = $TutorialDirector

var _speed_x2 := false


# ==============================
#            STATE
# ==============================

var mulligan_mode := false
## Le placement/consume n'est autorisé qu'après le premier mulligan validé
## (évite de poser une tour pendant la distribution d'ouverture).
var _build_allowed := false
var selected_mulligan_cards: Array = []
var selected_card_ui: TowerCardUI = null
var _is_dragging_card := false

## Niveau tutoriel scripté : tirage imposé, mulligan désactivé.
var scripted_tutorial := false

const TOWER_CARD_SCENE = preload("res://scenes/ui/tower_card.tscn")
const IRONCLAD_STARTER = preload("res://resources/decks/ironclad_starter.tres")
## Deck scripté du niveau tutoriel (niveau 1) : tirage déterministe, pas de mulligan.
const TUTORIAL_DECK = preload("res://resources/decks/tutorial_deck.tres")
const GRUMBOLT_CARD = preload("res://resources/cards/water_cannon_card.tres")
const FROSTWICK_CARD = preload("res://resources/cards/tesla_coil_card.tres")
const MAMA_COG_CARD = preload("res://resources/cards/industrial_fan_card.tres")
const VEGA_CARD = preload("res://resources/cards/vega_card.tres")

## Fond par niveau. Le niveau 1 garde la texture définie dans la scène ;
## les autres niveaux sont surchargés ici (même position/scale que le nœud Background).
const LEVEL_BACKGROUNDS := {
	2: preload("res://assets/background/map_level_2_green.png"),
}

## Map (grille + cases bloquées) par niveau. Le niveau 1 garde celle de la scène.
const LEVEL_MAPS := {
	2: preload("res://resources/maps/map_level2.tres"),
}


# ==============================
#            READY
# ==============================

func _ready():
	Player.reset()
	Audio.play_game_music()

	# Fond spécifique au niveau (le niveau 1 garde celui de la scène).
	if LEVEL_BACKGROUNDS.has(Progress.current_level_id):
		background.texture = LEVEL_BACKGROUNDS[Progress.current_level_id]

	# Map spécifique au niveau (grille + cases bloquées).
	if LEVEL_MAPS.has(Progress.current_level_id):
		grid.current_map = LEVEL_MAPS[Progress.current_level_id]

	# Vagues spécifiques au niveau (5 vagues mixées). Sinon, celles de la scène.
	var level_waves := WaveLibrary.get_waves(Progress.current_level_id)
	if level_waves.size() > 0:
		wave_manager.waves = level_waves

	# Game feel : le World tremble sur les impacts, le HUD reste stable.
	Juice.register_world(world)

	var floating_text = preload("res://scenes/ui/floating_text.tscn").instantiate()
	add_child(floating_text)
	floating_text.global_position = Vector2(300, 300)

	RewardManager.reward_panel = reward_panel
	RewardManager.reward_container = reward_container

	card_manager.setup(placement, tower_container, phenomenon_manager)

	# Niveau 1 = tutoriel : deck scripté (tirage imposé, sans mulligan).
	var deck: StartingDeckData = TUTORIAL_DECK if Progress.current_level_id == 1 else IRONCLAD_STARTER
	scripted_tutorial = deck.scripted_order
	card_manager.setup_starting_deck(deck.cards, not deck.scripted_order)

	# Les cartes sont cachées au départ — elles arrivent via _opening_sequence
	tower_cards_container.modulate.a = 0.0

	top_hud.setup(enemy_manager)
	wave_manager.setup(path, top_hud, enemy_manager, tower_manager)

	top_hud.speed_button.pressed.connect(_on_speed_button_pressed)
	top_hud.settings_button.pressed.connect(pause_menu.show_menu)
	top_hud.speed_button.pressed.connect(Audio.ui_click)
	top_hud.settings_button.pressed.connect(Audio.ui_click)

	placement.setup(grid, tower_container, path, enemy_manager, tower_manager)
	tower_manager.setup(tower_container)
	grid.setup_buildable_cells()

	Player.caps_changed.connect(_on_caps_changed)
	Player.base_hp_changed.connect(_on_base_hp_changed)
	Player.wave_changed.connect(_on_wave_changed)
	Player.ferraille_changed.connect(_on_ferraille_changed)

	_on_wave_changed(Player.current_wave)
	_on_caps_changed(Player.caps)
	_on_base_hp_changed(Player.base_hp)
	_on_ferraille_changed(Player.ferraille)

	tower_manager.towers_changed.connect(synergy_manager.recalculate_synergies)

	card_action_panel.consume_pressed.connect(_on_action_consume)
	card_manager.consume_resolved.connect(_on_consume_resolved)
	mulligan_overlay.validated.connect(_on_mulligan_validated)

	# Amélioration de tour (clic sur une tour posée)
	_setup_upgrade_button()
	tower_manager.tower_selected.connect(_on_tower_selected)
	tower_manager.tower_deselected.connect(_on_tower_deselected)

	# Niveau tutoriel : le TutorialDirector pilote tout. Sinon, flux normal.
	if scripted_tutorial:
		_build_allowed = true  # le tutoriel gère le placement par étape lui-même
		tutorial_director.run.call_deferred(self)
	else:
		_opening_sequence.call_deferred()


# ==============================
#     DRAG → BUILD
# ==============================

func _on_card_drag_started(card_data: CardData, _card_ui: TowerCardUI):

	if mulligan_mode:
		return

	if not _build_allowed:
		return

	# Tutoriel : seule la tour demandée à l'étape en cours est jouable.
	if not tutorial_director.can_build_card(card_data):
		Audio.error()
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

	if not _build_allowed:
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

	# Tutoriel : seule la carte demandée à l'étape en cours est consommable.
	if not tutorial_director.can_consume_card(card_data):
		Audio.error()
		return

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

	# Clic sur le bouton d'amélioration → laisser le GUI le gérer.
	# Sinon _input désélectionnerait la tour avant que le bouton ne réagisse.
	if _upgrade_button and _upgrade_button.visible \
			and event is InputEventMouseButton and event.pressed \
			and _upgrade_button.get_global_rect().has_point(event.position):
		return

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

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if pause_menu.visible:
			pause_menu.hide_menu()
		else:
			pause_menu.show_menu()
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
	if _upgrade_button and _upgrade_button.visible:
		_reposition_upgrade_button()


# ==============================
#          MULLIGAN
# ==============================

var _mulligan_max_cards := 3

# ==============================
#     AMELIORATION DE TOUR
# ==============================

var _upgrade_button: Button

func _setup_upgrade_button() -> void:
	_upgrade_button = Button.new()
	_upgrade_button.visible = false
	_upgrade_button.focus_mode = Control.FOCUS_NONE
	_upgrade_button.z_index = 100
	$UI/RootUI.add_child(_upgrade_button)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)

func _on_tower_selected(_tower: BaseTower) -> void:
	_refresh_upgrade_button()

func _on_tower_deselected() -> void:
	if _upgrade_button:
		_upgrade_button.visible = false

func _on_upgrade_pressed() -> void:
	var t: BaseTower = tower_manager.selected_tower
	if t == null or not t.can_upgrade():
		return

	# Le son de réussite (UpgradeTower.mp3) est joué dans la tour elle-même.
	if t.try_upgrade():
		_refresh_upgrade_button()

func _refresh_upgrade_button() -> void:
	if _upgrade_button == null:
		return
	var t: BaseTower = tower_manager.selected_tower
	if t == null:
		_upgrade_button.visible = false
		return

	if not t.can_upgrade():
		_upgrade_button.text = "MAX"
		_upgrade_button.disabled = true
	else:
		_upgrade_button.text = "⬆ Améliorer  %d ⛏" % t.upgrade_price()
		_upgrade_button.disabled = Player.ferraille < t.upgrade_price()

	_upgrade_button.visible = true
	_reposition_upgrade_button()

func _reposition_upgrade_button() -> void:
	var t: BaseTower = tower_manager.selected_tower
	if t == null or _upgrade_button == null or not _upgrade_button.visible:
		return
	var screen_pos := t.get_global_transform_with_canvas().origin
	_upgrade_button.reset_size()
	_upgrade_button.position = screen_pos - Vector2(_upgrade_button.size.x * 0.5, 95.0)


func show_defeat() -> void:
	game_over_screen.show_defeat()


func show_victory() -> void:
	game_over_screen.victory_acknowledged.connect(_on_victory_acknowledged, CONNECT_ONE_SHOT)
	game_over_screen.show_victory()


func _on_victory_acknowledged() -> void:
	# Dernière vague : pas de choix de récompense, retour direct à la carte.
	get_tree().change_scene_to_file("res://scenes/ui/WorldMap.tscn")


func _opening_sequence() -> void:
	if not is_inside_tree(): return
	await get_tree().create_timer(0.4).timeout

	if not is_inside_tree(): return
	await _deal_cards_animated()

	if not is_inside_tree(): return
	await get_tree().create_timer(0.5).timeout

	if not is_inside_tree(): return
	wave_manager.start_prep_phase(false)

	# Tutoriel scripté : pas de mulligan (séquence imposée). Sinon, mulligan d'ouverture.
	if not scripted_tutorial:
		start_mulligan_phase(3)


func _deal_cards_animated() -> void:
	refresh_hand_ui(false)
	tower_cards_container.modulate.a = 1.0

	var cards := tower_cards_container.get_children()
	var duration := 0.0

	for i in cards.size():
		var card: Control = cards[i]
		var delay: float = i * 0.15
		card.modulate.a = 0.0
		card.scale = Vector2(0.6, 0.6)
		card.pivot_offset = card.size * 0.5
		# Tween appartient à la carte — auto-tué si la carte est libérée
		var t := card.create_tween()
		t.set_parallel(true)
		t.tween_property(card, "modulate:a", 1.0, 0.22).set_delay(delay).set_trans(Tween.TRANS_SINE)
		t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.28).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_callback(
			Audio.play_sfx.bind(preload("res://assets/audio/sfx/card_draw.wav"), -6.0, 0.1)
		).set_delay(delay)
		duration = delay + 0.28

	if not is_inside_tree(): return
	await get_tree().create_timer(duration + 0.15).timeout


func start_mulligan_phase(max_cards: int = 3):
	_mulligan_max_cards = max_cards
	mulligan_mode = true
	selected_mulligan_cards.clear()
	card_manager.mulligan_used = false
	mulligan_overlay.show_phase(max_cards)


func _on_mulligan_validated():
	if selected_mulligan_cards.size() > 0:
		var cards_to_replace: Array[CardData] = []
		for card_ui in selected_mulligan_cards:
			if is_instance_valid(card_ui):
				cards_to_replace.append(card_ui.card_data)
		if cards_to_replace.size() > 0:
			card_manager.mulligan(cards_to_replace)
		selected_mulligan_cards.clear()

	mulligan_mode = false
	_build_allowed = true
	mulligan_overlay.hide_phase()

	if not is_inside_tree(): return
	await _deal_cards_animated()
	if not is_inside_tree(): return
	wave_manager.force_start_wave()


func _handle_mulligan_tap(card_ui: TowerCardUI):
	if not is_instance_valid(card_ui):
		return

	if selected_mulligan_cards.has(card_ui):
		selected_mulligan_cards.erase(card_ui)
		card_ui.set_selected(false)
	else:
		if selected_mulligan_cards.size() < _mulligan_max_cards:
			selected_mulligan_cards.append(card_ui)
			card_ui.set_selected(true)

	# Nettoyer les références invalidées
	selected_mulligan_cards = selected_mulligan_cards.filter(
		func(c): return is_instance_valid(c)
	)
	mulligan_overlay.update_count(selected_mulligan_cards.size())


# ==============================
#           HAND UI
# ==============================

func refresh_hand_ui(animate: bool = false):

	_deselect_card()
	_is_dragging_card = false

	for child in tower_cards_container.get_children():
		child.queue_free()

	var delay := 0.0
	for card_data in card_manager.hand:
		var card_ui: TowerCardUI = TOWER_CARD_SCENE.instantiate()
		tower_cards_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.card_tapped.connect(_on_card_tapped)
		card_ui.card_drag_started.connect(_on_card_drag_started)

		if animate:
			card_ui.modulate.a = 0.0
			card_ui.scale = Vector2(0.7, 0.7)
			card_ui.pivot_offset = card_ui.size * 0.5
			var t := card_ui.create_tween()
			t.set_parallel(true)
			t.tween_property(card_ui, "modulate:a", 1.0, 0.25).set_delay(delay).set_trans(Tween.TRANS_SINE)
			t.tween_property(card_ui, "scale", Vector2(1.0, 1.0), 0.30).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			delay += 0.12

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
	top_hud.set_wave(value, $WaveManager.waves.size())

func _on_caps_changed(value: int):
	top_hud.set_caps(value)

func _on_base_hp_changed(value: int):
	top_hud.set_base_hp(value)

func _on_ferraille_changed(value: int):
	top_hud.set_ferraille(value)
	_refresh_upgrade_button()

func _on_speed_button_pressed():
	_speed_x2 = not _speed_x2
	Engine.time_scale = 2.0 if _speed_x2 else 1.0
	top_hud.speed_button.text = "▶▶ x2" if _speed_x2 else "▶ x1"

func show_wave_preview(wave_index: int, wave_data: WaveData) -> void:
	wave_preview.show_wave(wave_index, wave_data)

func hide_wave_preview() -> void:
	wave_preview.hide_preview()


# ==============================
#           TUTORIEL
# ==============================

## Affiche un tutoriel (pause), puis attend que le joueur clique « Compris ».
func show_tutorial(title: String, body: String) -> void:
	await tutorial_overlay.show_and_wait(title, body)
