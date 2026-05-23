extends Node2D

# ==============================
#            NODES
# ==============================

@onready var world = $World
@onready var path: Path2D = $World/Path2D
@onready var tower_container: Node2D = $World/TowerContainer
@onready var tower_card_fire = $UI/RootUI/TowerCards/PanelFire/TowerCardFire
@onready var upgrade_button = $UI/RootUI/UpgradeButton
@onready var path_follow_template: PathFollow2D = $World/Path2D/PathFollow2D
@onready var wave_timer_label = $UI/RootUI/WaveTimerLabel
@onready var grid: GridManager = $GridManager
@onready var placement: PlacementManager = $PlacementManager

# ==============================
#            STATE
# ==============================

const ENEMY_SCENE = preload("res://scenes/enemies/SimpleMob.tscn")
const TOWER_FIRE = preload("res://scenes/towers/TowerFire.tscn")
const TOWER_CANNON = preload("res://scenes/towers/TowerCannon.tscn")
var selected_tower: Node2D = null
var prep_time := 2
var wave_started := false

# ==============================
#            READY
# ==============================

func _ready():

	start_prep_phase()
	
func start_prep_phase():

	wave_started = false

	for i in range(prep_time, 0, -1):

		wave_timer_label.text = "Wave in: " + str(i)

		await get_tree().create_timer(1.0).timeout

	wave_timer_label.text = "WAVE !"

	start_wave()

func start_wave():

	if wave_started:
		return

	wave_started = true

	spawn_wave(20, 1.5, 70.0)

func start_placing_tower(scene: PackedScene):

	print("START PLACING")

	placement.selected_tower_scene

	if placement.ghost_tower:
		placement.ghost_tower.queue_free()

	placement.ghost_tower = scene.instantiate()

	print(placement.ghost_tower)

	tower_container.add_child(placement.ghost_tower)

	placement.ghost_tower.z_index = 999
	placement.ghost_tower.modulate = Color(0, 1, 0, 0.5)

	_disable_ghost_behaviors()

	block_path_cells()


func _disable_ghost_behaviors():

	if placement.ghost_tower and placement.ghost_tower is BaseTower:

		placement.ghost_tower.is_ghost = true
		placement.ghost_tower.disable_behaviors()


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

# ==============================
#            PROCESS
# ==============================

func _process(_delta):

	if placement.ghost_tower == null:
		return

	var mouse_world = get_global_mouse_position()
	var cell = grid.world_to_cell(mouse_world)

	placement.ghost_tower.global_position = grid.cell_to_world(cell)

	if not grid.can_place(cell):
		placement.ghost_tower.modulate = Color(1, 0, 0, 0.5)
	else:
		placement.ghost_tower.modulate = Color(0, 1, 0, 0.5)

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

						# deselect ancienne
						if selected_tower:
							selected_tower.set_selected(false)

						# nouvelle sélection
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

			try_place_tower(mouse_world)

func try_place_tower(mouse_world: Vector2):

	if not placement.ghost_tower or not placement.selected_tower_scene:
		return

	print("TRY PLACE")

	var cell = grid.world_to_cell(mouse_world)

	if not grid.can_place(cell):
		return

	var final_tower = placement.selected_tower_scene.instantiate()

	print("TOWER CREATED")

	tower_container.add_child(final_tower)

	print("TOWER ADDED")

	final_tower.global_position = grid.cell_to_world(cell)

	print(final_tower.global_position)

	final_tower.modulate = Color(1,1,1,1)
	final_tower.z_index = 100

	print("PLACED:", final_tower.global_position)

	grid.occupy_cell(cell, final_tower)

	placement.ghost_tower.queue_free()
	placement.ghost_tower = null
	placement.selected_tower_scene = null

# ==============================
#        ENEMY SPAWN
# ==============================

func _spawn_enemy_instance() -> PathFollow2D:

	if not path_follow_template:
		return null

	var pf: PathFollow2D = path_follow_template.duplicate()

	pf.visible = true
	pf.set_process(true)
	pf.set_physics_process(true)

	# Supprime ancien ennemi
	for child in pf.get_children():
		child.queue_free()

	# Nouveau monstre
	var enemy = ENEMY_SCENE.instantiate()
	pf.add_child(enemy)

	return pf

func spawn_wave(count: int, interval: float, speed_override: float = -1.0):

	if not path:
		return

	for i in range(count):

		var pf = _spawn_enemy_instance()

		if pf:
			if speed_override > 0:
				pf.speed = speed_override

			path.add_child(pf)
			pf.progress = 0

		await get_tree().create_timer(interval).timeout


func _on_tower_card_fire_pressed():

	print("CARD FIRE CLICKED")

	start_placing_tower(TOWER_FIRE)
