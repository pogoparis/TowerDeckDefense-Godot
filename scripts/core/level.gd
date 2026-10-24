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

## Decks thématiques (10 cartes chacun). Chaque deck raconte une stratégie
## lisible, au lieu d'un fourre-tout où le joueur ne peut rien apprendre.
##   Brasier = Feu + Élec, dopés par les deux supports (halo + marque).
##   Roche   = Terre + Eau + Air, défensif et anti-blindés.
const DECK_BRASIER = preload("res://resources/decks/deck_brasier.tres")
const DECK_ROCHE = preload("res://resources/decks/deck_roche.tres")

## Deck utilisé par niveau (en attendant un écran de choix de deck).
const LEVEL_DECKS := {
	2: DECK_BRASIER,
	3: DECK_ROCHE,
}

## Fond par niveau. Le niveau 1 garde la texture définie dans la scène ;
## les autres niveaux sont surchargés ici (même position/scale que le nœud Background).
const LEVEL_BACKGROUNDS := {
	2: preload("res://assets/background/map_level_2_green.png"),
	3: preload("res://assets/maps/Ruines.png"),
}

## Chemin par niveau : une SCÈNE que l'on ouvre et où l'on trace à la souris.
##
## ── POURQUOI UNE SCÈNE ET PAS DES COORDONNÉES ────────────────────────────
## Le tracé a d'abord été une liste de Vector2 dans ce fichier. Ça marchait,
## mais placer un chemin à l'aveugle en tapant des nombres est le plus sûr
## moyen de le faire passer dans une maison — ce qui est arrivé deux fois.
## Godot sait déjà faire ça très bien : on ouvre la scène, on voit le décor,
## on déplace les points.
##
## Chaque scène contient trois choses :
##   • le FOND du niveau, à l'échelle exacte du jeu, comme repère ;
##   • les REPÈRES (grille, bord d'écran, hauteur de la barre de cartes),
##     dessinés par scripts_tools/path_editor_guides.gd ;
##   • le PATH2D, seul élément réellement lu par le jeu.
##
## Le reste de la scène n'est jamais instancié en partie : on n'en extrait
## que la courbe.
##
## Un tracé plus long rend le niveau plus FACILE — les mobs passent plus de
## temps sous le feu. Celui des Ruines fait 3016 px contre 1920 pour le tracé
## commun, soit +57 % : voulu, le niveau 3 était infranchissable.
const LEVEL_PATH_SCENES := {
	3: preload("res://scenes/paths/chemin_niveau_3.tscn"),
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
	RewardDB.reset_taken()
	# Le pool dépend des déblocages : il peut avoir grandi depuis la dernière partie.
	RewardDB.load_rewards()
	RunDeck.reset()
	Audio.play_game_music()

	# Fond spécifique au niveau (le niveau 1 garde celui de la scène).
	if LEVEL_BACKGROUNDS.has(Progress.current_level_id):
		background.texture = LEVEL_BACKGROUNDS[Progress.current_level_id]
	_fit_background()
	_apply_level_path()

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

	card_manager.setup(placement, tower_container)

	# Niveau 1 = tutoriel : deck scripté (tirage imposé, sans mulligan).
	# Sinon : deck thématique du niveau, ou le fourre-tout en dernier recours.
	var deck: StartingDeckData = TUTORIAL_DECK
	if Progress.current_level_id != 1:
		# Priorité au deck choisi par le joueur ; sinon celui du niveau.
		if Progress.selected_deck != null:
			deck = Progress.selected_deck
		else:
			deck = LEVEL_DECKS.get(Progress.current_level_id, IRONCLAD_STARTER)
	scripted_tutorial = deck.scripted_order

	# Liste personnalisée par le joueur (échanges sur l'écran de deck) si elle
	# existe, sinon le deck préconstruit tel quel.
	var cards: Array = deck.cards
	if not scripted_tutorial and not Progress.custom_deck_cards.is_empty():
		cards = Progress.custom_deck_cards
	card_manager.setup_starting_deck(cards, not deck.scripted_order)

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
	# Hors tutoriel : construction limitée à une bande autour du chemin.
	# Rayon 3 = modèle BTD6 — la PLACE est généreuse, c'est l'ÉCONOMIE qui
	# limite. On empêche juste de bâtir dans les coins lointains inutiles.
	if not scripted_tutorial:
		# Rayon 4 en cases de 96 px = 384 px de bande, soit la même largeur de
		# terrain qu'avant (rayon 3 en cases de 128) mais découpée plus finement.
		grid.restrict_to_path_band(path, 4)

	Player.caps_changed.connect(_on_caps_changed)
	Player.base_hp_changed.connect(_on_base_hp_changed)
	Player.wave_changed.connect(_on_wave_changed)

	_on_wave_changed(Player.current_wave)
	_on_caps_changed(Player.caps)
	_on_base_hp_changed(Player.base_hp)

	tower_manager.towers_changed.connect(synergy_manager.recalculate_synergies)

	mulligan_overlay.validated.connect(_on_mulligan_validated)

	# Mise en scène du danger : flash sur les fuites, bordure sous 6 PV.
	# Ajouté en code plutôt que dans la scène pour qu'il soit AU-DESSUS du HUD
	# sans avoir à réordonner les nœuds existants.
	var danger := DangerOverlay.new()
	danger.name = "DangerOverlay"
	$UI/RootUI.add_child(danger)

	# Amélioration de tour (clic sur une tour posée)
	_setup_upgrade_button()
	_setup_charge_button()
	_setup_targeting_button()
	tower_manager.tower_selected.connect(_on_tower_selected)
	tower_manager.tower_deselected.connect(_on_tower_deselected)

	# ATELIER : pas de vagues, pas de compte à rebours — juste le terrain et un
	# panneau pour lâcher les mobs. On sort avant _opening_sequence, qui
	# lancerait la préparation de la vague 1.
	if Progress.current_level_id == AtelierPanel.LEVEL_ID:
		_build_allowed = true
		Player.add_caps(2000)   # de quoi tester des tours sans compter
		var atelier := AtelierPanel.new()
		atelier.name = "AtelierPanel"
		add_child(atelier)
		atelier.setup(path, wave_manager, enemy_manager)
		tower_cards_container.modulate.a = 1.0
		refresh_hand_ui()
		return

	# Niveau tutoriel : le TutorialDirector pilote tout. Sinon, flux normal.
	if scripted_tutorial:
		_build_allowed = true  # le tutoriel gère le placement par étape lui-même
		tutorial_director.run.call_deferred(self)
	else:
		_opening_sequence.call_deferred()


## Remplace la courbe du chemin par celle tracée dans la scène du niveau.
##
## On remet aussi le décalage du Path2D à zéro : la scène de jeu le posait à
## (70, 129), ce qui aurait décalé de 70 px à gauche et 129 px en haut un tracé
## dessiné, lui, en coordonnées d'écran.
func _apply_level_path() -> void:
	var scene: PackedScene = LEVEL_PATH_SCENES.get(Progress.current_level_id)
	if scene == null:
		return

	var root := scene.instantiate()
	var source := root.get_node_or_null("Chemin") as Path2D
	if source == null or source.curve == null:
		push_error("Scène de chemin sans nœud Path2D nommé « Chemin » : niveau %d"
			% Progress.current_level_id)
		root.free()
		return

	path.position = Vector2.ZERO
	# duplicate() : sans copie, la courbe reste partagée avec la ressource du
	# disque, et toute modification en jeu s'écrirait dans le fichier .tscn.
	path.curve = source.curve.duplicate()
	root.free()

	# WorldDraw peint le chemin en lisant la courbe : sans ça, il garderait
	# l'ancien tracé à l'écran alors que les mobs suivraient le nouveau.
	var drawer := world.get_node_or_null("WorldDraw")
	if drawer:
		drawer.queue_redraw()


## Met le fond à l'échelle de l'écran SANS le déformer.
##
## ── LE BUG QUE ÇA CORRIGE ─────────────────────────────────────────────────
## La scène portait scale = (1.25, 1.0547) : deux facteurs différents, calculés
## à la main pour faire entrer une image 1536×1024 (3:2) dans un écran
## 1920×1080 (16:9). Le fond était donc étiré de 18,5 % de plus en largeur
## qu'en hauteur. Sur un décor isométrique, ça écrase les toits et fausse
## l'angle à 45° de tout le décor — l'erreur est invisible tant qu'on ne la
## cherche pas, et elle contredit les sprites, eux non déformés.
##
## On couvre l'écran (« cover », pas « fit ») : mieux vaut perdre un peu de
## décor sur les bords que laisser des barres noires.
const SCREEN := Vector2(1920.0, 1080.0)

func _fit_background() -> void:
	if background == null or background.texture == null:
		return
	var size := background.texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var factor: float = maxf(SCREEN.x / size.x, SCREEN.y / size.y)
	background.scale = Vector2(factor, factor)
	background.position = SCREEN * 0.5


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

func _on_card_tapped(_card_data: CardData, card_ui: TowerCardUI):

	if mulligan_mode:
		_handle_mulligan_tap(card_ui)
		return

	# Le CONSUME a été retiré : taper une carte Tour ne fait rien (la pose se
	# fait par drag). Le tap servira au futur système de Sorts.


func _deselect_card():

	if selected_card_ui:
		selected_card_ui.set_selected(false)
		selected_card_ui = null

	card_action_panel.hide_panel()

	if placement.is_placing():
		placement.cancel_placement()


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

	# Idem pour le bouton DÉCLENCHER : sans ça, le clic désélectionne la tour
	# AVANT que le bouton ne réagisse → le déclenchement ne se fait jamais.
	if _charge_button and _charge_button.visible \
			and event is InputEventMouseButton and event.pressed \
			and _charge_button.get_global_rect().has_point(event.position):
		return

	if _targeting_button and _targeting_button.visible 			and event is InputEventMouseButton and event.pressed 			and _targeting_button.get_global_rect().has_point(event.position):
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
			# Un sort se lâche là où on vise, exactement comme une tour se pose.
			if placement.selected_spell != null:
				placement.try_cast_spell(mouse_world)
			elif placement.selected_upgrade_card != null:
				placement.try_cast_upgrade(mouse_world)
			else:
				placement.try_place_tower(mouse_world)
			refresh_hand_ui()
			get_viewport().set_input_as_handled()
			return

	# ── Mode VISÉE de sort (tap, sans drag) ─────────────
	if placement.selected_spell != null and event is InputEventMouseButton \
			and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		placement.try_cast_spell(mouse_world)
		refresh_hand_ui()
		get_viewport().set_input_as_handled()
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
	if placement.is_placing() or _is_dragging_card:
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
	if _targeting_button and _targeting_button.visible:
		_reposition_targeting_button()
	# La jauge se remplit pendant la vague → réévalue l'état "prête" en continu.
	var sel: BaseTower = tower_manager.selected_tower
	if sel and sel.is_signature and not sel.charge_auto:
		_refresh_charge_button()


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
	_refresh_charge_button()
	_refresh_targeting_button()

func _on_tower_deselected() -> void:
	if _upgrade_button:
		_upgrade_button.visible = false
	if _charge_button:
		_charge_button.visible = false
	if _targeting_button:
		_targeting_button.visible = false

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
		_upgrade_button.disabled = Player.caps < t.upgrade_price()

	_upgrade_button.visible = true
	_reposition_upgrade_button()

func _reposition_upgrade_button() -> void:
	var t: BaseTower = tower_manager.selected_tower
	if t == null or _upgrade_button == null or not _upgrade_button.visible:
		return
	var screen_pos := t.get_global_transform_with_canvas().origin
	_upgrade_button.reset_size()
	_upgrade_button.position = screen_pos - Vector2(_upgrade_button.size.x * 0.5, 95.0)


# ==============================
#   DÉCLENCHEMENT DE CHARGE
# ==============================

var _charge_button: Button
var _targeting_button: Button

func _setup_charge_button() -> void:
	_charge_button = Button.new()
	_charge_button.visible = false
	_charge_button.focus_mode = Control.FOCUS_NONE
	_charge_button.z_index = 100
	$UI/RootUI.add_child(_charge_button)
	_charge_button.pressed.connect(_on_charge_pressed)

## Bouton de PRIORITÉ DE CIBLAGE — visible dès qu'une tour est sélectionnée.
##
## Contrairement à AMÉLIORER et DÉCLENCHER, il ne coûte rien et n'a pas de
## condition : c'est un réglage, pas une dépense. Il reste donc toujours
## disponible, y compris pendant la vague — c'est justement là qu'il sert.
func _setup_targeting_button() -> void:
	_targeting_button = Button.new()
	_targeting_button.visible = false
	_targeting_button.focus_mode = Control.FOCUS_NONE
	_targeting_button.z_index = 100
	$UI/RootUI.add_child(_targeting_button)
	_targeting_button.pressed.connect(_on_targeting_pressed)


func _on_targeting_pressed() -> void:
	var t: BaseTower = tower_manager.selected_tower
	if t == null:
		return
	t.cycle_targeting()
	Audio.ui_click()
	_refresh_targeting_button()


func _refresh_targeting_button() -> void:
	if _targeting_button == null:
		return
	var t: BaseTower = tower_manager.selected_tower
	if t == null:
		_targeting_button.visible = false
		return
	_targeting_button.text = "🎯 %s" % t.targeting_label()
	_targeting_button.visible = true
	_reposition_targeting_button()


func _reposition_targeting_button() -> void:
	var t: BaseTower = tower_manager.selected_tower
	if t == null or _targeting_button == null or not _targeting_button.visible:
		return
	var screen_pos := t.get_global_transform_with_canvas().origin
	_targeting_button.reset_size()
	# Sous la tour : les deux autres boutons sont au-dessus, celui-ci ne doit
	# jamais leur voler le clic.
	_targeting_button.position = screen_pos - Vector2(_targeting_button.size.x * 0.5, -60.0)


func _on_charge_pressed() -> void:
	var t: BaseTower = tower_manager.selected_tower
	if t == null or not t.is_charge_ready():
		return
	if t.trigger_charge():
		Audio.ui_click()
		_refresh_charge_button()

func _refresh_charge_button() -> void:
	if _charge_button == null:
		return
	var t: BaseTower = tower_manager.selected_tower
	# charge_auto : la tour se déclenche seule, proposer un bouton serait un
	# mensonge — il n'y a rien à décider.
	if t == null or not t.is_signature or t.charge_auto or not t.is_charge_ready():
		_charge_button.visible = false
		return
	_charge_button.text = "⚡ DÉCLENCHER"
	_charge_button.visible = true
	_reposition_charge_button()

func _reposition_charge_button() -> void:
	var t: BaseTower = tower_manager.selected_tower
	if t == null or _charge_button == null or not _charge_button.visible:
		return
	var screen_pos := t.get_global_transform_with_canvas().origin
	_charge_button.reset_size()
	_charge_button.position = screen_pos - Vector2(_charge_button.size.x * 0.5, 145.0)


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
			# Pivot au centre le temps du zoom d'arrivee seulement : setup()
			# a pose HOVER_PIVOT, qu'il faut rendre avant le premier survol.
			card_ui.pivot_offset = card_ui.size * 0.5
			var t := card_ui.create_tween()
			t.set_parallel(true)
			t.tween_property(card_ui, "modulate:a", 1.0, 0.25).set_delay(delay).set_trans(Tween.TRANS_SINE)
			t.tween_property(card_ui, "scale", Vector2(1.0, 1.0), 0.30).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.chain().tween_callback(
				func(): card_ui.pivot_offset = TowerCardUI.HOVER_PIVOT
			)
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
