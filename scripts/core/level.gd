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
	wave_manager.path = path
	wave_manager.wave_timer_label = wave_timer_label
	wave_manager.enemy_manager = enemy_manager
	placement.enemy_manager = enemy_manager
	placement.grid = grid
	placement.tower_container = tower_container
	placement.path = path
	tower_manager.tower_container = tower_container
	
	wave_manager.start_prep_phase()

# ==============================
#         INPUT HANDLING
# ==============================

func _input(event):
	
	placement.current_mouse_world = get_global_mouse_position()
	
	if event is InputEventMouseButton and event.pressed:

		var mouse_world = get_global_mouse_position()

		# ==============================
		# CLICK DROIT = DESELECT
		# ==============================

		if event.button_index == MOUSE_BUTTON_RIGHT:

			if placement.handle_right_click():
				return

			tower_manager.handle_right_click()

			return

		# ==============================
		# CLICK GAUCHE
		# ==============================

		if event.button_index == MOUSE_BUTTON_LEFT:

			if placement.handle_left_click(mouse_world):
				return

			if tower_manager.handle_left_click(mouse_world):
				return

			if tower_manager.try_select_tower(mouse_world):
				return

			# ==============================
			# CLICK VIDE = DESELECT
			# ==============================

			tower_manager.deselect_current_tower()

			# ==============================
			# TRY PLACE TOWER
			# ==============================

			placement.handle_left_click(mouse_world)

func _physics_process(_delta):

	placement.current_mouse_world = get_global_mouse_position()

func _on_tower_card_fire_pressed():

	placement.start_tower_placement(
	TOWER_FIRE_SCENE,
	tower_container
)
