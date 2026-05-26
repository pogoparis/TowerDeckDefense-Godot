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

# ==============================
#            STATE
# ==============================
const PATH_FOLLOW_SCRIPT = preload("res://scripts/core/path_follow_2d.gd")
const ENEMY_SCENE = preload("res://scenes/enemies/SimpleMob.tscn")
const TOWER_FIRE_SCENE = preload("res://scenes/towers/TowerFire.tscn")
var selected_tower: Node2D = null

# ==============================
#            READY
# ==============================

func _ready():
	wave_manager.path = path
	wave_manager.wave_timer_label = wave_timer_label
	wave_manager.enemy_manager = enemy_manager
	placement.enemy_manager = enemy_manager

	wave_manager.start_prep_phase()

# ==============================
#       BLOCK PATH CELLS
# ==============================

func block_path_cells():

	if not path or not path.curve:
		return

	grid.blocked_cells.clear()

	var curve = path.curve
	var length = curve.get_baked_length()
	var step = 4.0
	var d := 0.0

	while d <= length:

		var local_point = curve.sample_baked(d)
		var world_point = path.to_global(local_point)
		var cell = grid.world_to_cell(world_point)
		
		grid.blocked_cells[cell] = true

		d += step
		
func _process(_delta):

	placement.update_ghost(grid, get_global_mouse_position())

# ==============================
#         INPUT HANDLING
# ==============================

func _input(event):

	if event is InputEventMouseButton and event.pressed:

		var mouse_world = get_global_mouse_position()

		# ==============================
		# CLICK DROIT = DESELECT
		# ==============================

		if event.button_index == MOUSE_BUTTON_RIGHT:

			if selected_tower:
				selected_tower.set_selected(false)
				selected_tower = null

			return

		# ==============================
		# CLICK GAUCHE
		# ==============================

		if event.button_index == MOUSE_BUTTON_LEFT:

			# ==============================
			# SELECT EXISTING TOWER
			# ==============================

			for tower in tower_container.get_children():

				if tower is BaseTower:

					if tower.is_ghost:
						continue

					if mouse_world.distance_to(tower.global_position) < 48:

						if selected_tower:
							selected_tower.set_selected(false)

						selected_tower = tower
						selected_tower.set_selected(true)

						return

			# ==============================
			# CLICK VIDE = DESELECT
			# ==============================

			if selected_tower:
				selected_tower.set_selected(false)
				selected_tower = null

			# ==============================
			# TRY PLACE TOWER
			# ==============================

			placement.try_place_tower(
				grid,
				tower_container,
				mouse_world
			)


func _on_tower_card_fire_pressed():

	placement.start_tower_placement(
	TOWER_FIRE_SCENE,
	tower_container
)
