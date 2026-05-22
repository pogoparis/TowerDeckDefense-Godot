extends Node2D

# ==============================
#            NODES
# ==============================

@onready var world = $World
@onready var path: Path2D = $World/Path2D
@onready var tower_container: Node2D = $World/TowerContainer
@onready var tower_card_fire = $UI/RootUI/TowerCards/PanelFire/TowerCardFire
@onready var tower_card_cannon = $UI/RootUI/TowerCards/PanelCannon/TowerCardCannon
@onready var upgrade_button = $UI/RootUI/UpgradeButton
@onready var path_follow_template: PathFollow2D = $World/Path2D/PathFollow2D
@onready var wave_timer_label = $UI/RootUI/WaveTimerLabel

# ==============================
#            STATE
# ==============================

const ENEMY_SCENE = preload("res://scenes/enemies/SimpleMob.tscn")
const CELL_SIZE := 64
const TOWER_FIRE = preload("res://scenes/towers/TowerFire.tscn")
const TOWER_CANNON = preload("res://scenes/towers/TowerCannon.tscn")
var selected_tower_scene: PackedScene = null
var ghost_tower: Node2D = null
var selected_tower: Node2D = null
var blocked_cells := {}
var prep_time := 2
var wave_started := false

# ==============================
#            READY
# ==============================

func _ready():

	start_prep_phase()
	
	# Connexions
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	if path_follow_template:
		path_follow_template.visible = false
		path_follow_template.set_physics_process(false)
		path_follow_template.set_process(false)

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

	selected_tower_scene = scene

	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = scene.instantiate()
	ghost_tower.modulate = Color(1,1,1,0.5)

	world.add_child(ghost_tower)
	_disable_ghost_behaviors()

	# Désactive template enemy
	if path_follow_template:
		path_follow_template.process_mode = Node.PROCESS_MODE_DISABLED
		path_follow_template.set_process(false)

	block_path_cells()

# ==============================
#        GRID HELPERS
# ==============================

func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(pos.x / CELL_SIZE),
		floor(pos.y / CELL_SIZE)
	)

func cell_to_world_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE * 0.5,
		cell.y * CELL_SIZE + CELL_SIZE * 0.5
	)



# ==============================
#       BLOCK PATH CELLS
# ==============================

func block_path_cells():

	if not path or not path.curve:
		return

	blocked_cells.clear()

	var curve = path.curve
	var length = curve.get_baked_length()
	var step = 4.0
	var d := 0.0

	while d <= length:

		var local_point = curve.sample_baked(d)
		var world_point = path.to_global(local_point)

		var cell = world_to_cell(world_point)
		blocked_cells[cell] = true

		d += step

# ==============================
#            PROCESS
# ==============================

func _process(_delta):

	if ghost_tower:
		var mouse_world = get_global_mouse_position()
		var cell = world_to_cell(mouse_world)

		ghost_tower.global_position = cell_to_world_center(cell)
		print("CELL:", cell)
		print("BLOCKED:", blocked_cells.has(cell))
		if blocked_cells.has(cell):
			ghost_tower.modulate = Color(1, 0, 0, 0.5)
		else:
			ghost_tower.modulate = Color(0, 1, 0, 0.5)

# ==============================
#         INPUT HANDLING
# ==============================

func _input(event):

	if event is InputEventMouseButton and event.pressed:

		# CLICK DROIT → Annule
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_ghost()
			return

		# CLICK GAUCHE
		if event.button_index == MOUSE_BUTTON_LEFT:

			var mouse_world = get_global_mouse_position()
			# ==============================
			#     SELECT EXISTING TOWER
			# ==============================

			for tower in get_children():

				if tower is base_tower:

					if mouse_world.distance_to(tower.global_position) < 48:

						if selected_tower:
							selected_tower.set_selected(false)

						selected_tower = tower
						selected_tower.set_selected(true)

						_show_upgrade_button()
						return
			# Placement nouvelle tour
			if ghost_tower and selected_tower_scene:

				var cell = world_to_cell(mouse_world)

				if blocked_cells.has(cell):
					return

				var final_tower = selected_tower_scene.instantiate()

				add_child(final_tower)

				final_tower.global_position = cell_to_world_center(cell)
				final_tower.modulate = Color(1,1,1,1)
				final_tower.z_index = 100

				print("PLACED:", final_tower.global_position)

				blocked_cells[cell] = true

				ghost_tower.queue_free()
				ghost_tower = null
				selected_tower_scene = null


# ==============================
#        UPGRADE
# ==============================

func _on_upgrade_pressed():

	if not selected_tower:
		return

	if selected_tower.upgrade():
		_show_upgrade_button()
	else:
		upgrade_button.visible = false

func _show_upgrade_button():

	if not selected_tower:
		return

	if selected_tower.level >= selected_tower.max_level:
		upgrade_button.visible = false
		return

	var next_level = selected_tower.level + 1
	var data = selected_tower.upgrade_data.get(next_level)

	if not data:
		upgrade_button.visible = false
		return

	var cost = data.get("cost", 0)

	if GameManager.gold < cost:
		upgrade_button.visible = false
		return

	upgrade_button.text = "Upgrade (" + str(cost) + "g)"
	upgrade_button.visible = true
	upgrade_button.position = selected_tower.position + Vector2(40, -40)

# ==============================
#        GHOST CLEAN
# ==============================

func _cancel_ghost():

	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = null
	selected_tower_scene = null

	if selected_tower:
		selected_tower.set_selected(false)

	selected_tower = null

	upgrade_button.visible = false

func _disable_ghost_behaviors():

	if ghost_tower and ghost_tower is base_tower:

		ghost_tower.is_ghost = true
		ghost_tower.disable_behaviors()

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
