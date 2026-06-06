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
@onready var reward_panel = $UI/RootUI/RewardPanel
@onready var reward_container = $UI/RootUI/RewardPanel/RewardContainer
@onready var synergy_manager: SynergyManager = $SynergyManager
@onready var tower_cards_container = $UI/RootUI/TowerCards
@onready var deck_debug_label = $UI/RootUI/DeckDebugLabel
@onready var start_wave_button = $UI/RootUI/StartWaveButton
	
	
# ==============================
#            STATE
# ==============================
const PATH_FOLLOW_SCRIPT = preload("res://scripts/core/path_follow_2d.gd")
const ENEMY_SCENE = preload("res://scenes/enemies/SimpleMob.tscn")
const TOWER_FIRE_SCENE = preload("res://scenes/towers/TowerFire.tscn")
const GRUMBOLT_CARD = preload("res://resources/cards/grumbolt_card.tres")
const FROSTWICK_CARD = preload("res://resources/cards/frostwick_card.tres")
const MAMA_COG_CARD = preload("res://resources/cards/mama_cog_card.tres")
const VEGA_CARD = preload("res://resources/cards/vega_card.tres")
const TOWER_CARD_SCENE = preload(
	"res://scenes/ui/tower_card.tscn"
)
const IRONCLAD_STARTER = preload(
	"res://resources/decks/ironclad_starter.tres"
)

# ==============================
#            READY
# ==============================

func _ready():

	start_wave_button.pressed.connect(
	wave_manager.force_start_wave
	)
	
	var floating_text = preload("res://scenes/ui/floating_text.tscn").instantiate()
	add_child(floating_text)

	floating_text.global_position = Vector2(300, 300)

# floating_text.setup("TEST")
	RewardManager.reward_panel = reward_panel
	RewardManager.reward_container = reward_container
	
	card_manager.setup_starting_deck(
		IRONCLAD_STARTER.cards
	)

	refresh_hand_ui()

	wave_manager.setup(
			path,
			wave_timer_label,
			enemy_manager,
			tower_manager
		)

	card_manager.setup(
		placement,
		tower_container
		)

	placement.setup(
	grid,
		tower_container,
		path,
		enemy_manager,
		tower_manager
	)

	tower_manager.setup(
		tower_container
	)
	
	grid.setup_buildable_cells()
	Player.caps_changed.connect(_on_caps_changed)
	Player.base_hp_changed.connect(_on_base_hp_changed)
	Player.wave_changed.connect(_on_wave_changed)

	_on_wave_changed(Player.current_wave)

	_on_caps_changed(Player.caps)
	_on_base_hp_changed(Player.base_hp)
	wave_manager.start_prep_phase()

	tower_manager.towers_changed.connect(
			synergy_manager.recalculate_synergies
		)

func refresh_hand_ui():

	for child in tower_cards_container.get_children():
		child.queue_free()

	for card_data in card_manager.hand:

		var card_ui = TOWER_CARD_SCENE.instantiate()

		tower_cards_container.add_child(card_ui)

		card_ui.setup(card_data)

		card_ui.card_clicked.connect(
			_on_dynamic_card_clicked
		)

	update_deck_debug()

func _on_towers_changed():

	for tower in tower_manager.get_all_towers():

		if tower.has_method("update_aura"):
			tower.update_aura()

func _on_wave_changed(value:int):

	$UI/RootUI/TopBar/WaveLabel.text = "Wave : %d" % value

func _on_grumbolt_pressed():

	card_manager.play_card(GRUMBOLT_CARD)
	
func _on_frostwick_pressed():

	card_manager.play_card(FROSTWICK_CARD)

func _on_mama_cog_pressed():

	card_manager.play_card(MAMA_COG_CARD)

# ==============================
#         INPUT HANDLING
# ==============================
func _input(event):

	var mouse_world = get_global_mouse_position()

	if placement.handle_input(event, mouse_world):
		return

	if tower_manager.handle_input(event, mouse_world):
		return

func _physics_process(_delta):

	placement.current_mouse_world = get_global_mouse_position()


func _on_caps_changed(value:int):

	$UI/RootUI/TopBar/CapsLabel.text = "Caps : %d" % value


func _on_base_hp_changed(value:int):

	$UI/RootUI/TopBar/BaseHpLabel.text = "Base : %d" % value
	

func _on_dynamic_card_clicked(card_data: CardData):

	card_manager.play_card(card_data)

func update_deck_debug():

	var total = (
		card_manager.draw_pile.size()
		+ card_manager.hand.size()
	)

	deck_debug_label.text = (
		"Deck: %d\nHand: %d\nTotal: %d"
		% [
			card_manager.draw_pile.size(),
			card_manager.hand.size(),
			total
		]
	)
	
