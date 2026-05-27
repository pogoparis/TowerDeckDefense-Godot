extends Node2D

# ==============================
#            NODES
# ==============================

@onready var enemy_manager = $EnemyManager
@onready var wave_manager = $WaveManager
@onready var world = $World
@onready var path: Path2D = $World/Path2D
@onready var tower_container: Node2D = $World/TowerContainer
@onready var tower_card_fire = $UI/RootUI/TowerCards/PanelFire/TowerCardFire
@onready var upgrade_button = $UI/RootUI/UpgradeButton
@onready var wave_timer_label = $UI/RootUI/WaveTimerLabel
@onready var grid: GridManager = $GridManager
@onready var placement: PlacementManager = $PlacementManager
@onready var tower_manager = $TowerManager

# ==============================
#            STATE
# ==============================
const PATH_FOLLOW_SCRIPT = preload("res://scripts/core/path_follow_2d.gd")
const ENEMY_SCENE = preload("res://scenes/enemies/SimpleMob.tscn")
const TOWER_FIRE_SCENE = preload("res://scenes/towers/TowerFire.tscn")


# ==============================
#            READY
# ==============================

func _ready():

	wave_manager.setup(
		path,
		wave_timer_label,
		enemy_manager,
		tower_manager
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

	wave_manager.start_prep_phase()

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

func _on_tower_card_fire_pressed():

	placement.start_tower_placement(
	TOWER_FIRE_SCENE,
	tower_container
)
