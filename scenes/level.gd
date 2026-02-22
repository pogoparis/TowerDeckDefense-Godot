extends Node2D

# === NODES ===
@onready var world := $World
@onready var path: Path2D = $World/Path2D
@onready var tower_card := $UI/TowerCardFire
@onready var path_follow_template: PathFollow2D = $World/Path2D/PathFollow2D

# === STATE ===
var selected_tower_scene: PackedScene = null
var ghost_tower: Node2D = null
const CELL_SIZE := 64
var blocked_cells := {}
var selected_tower: Node2D = null

# === READY ===
func _ready():
	tower_card.tower_selected.connect(_on_tower_selected)

	if path_follow_template:
		path_follow_template.process_mode = Node.PROCESS_MODE_DISABLED
		path_follow_template.set_process(false)

	spawn_wave(6, 3.2, 70.0)
	block_path_cells()
		
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
	
func block_path_cells():
	if path == null or path.curve == null:
		return

	var curve = path.curve
	var length = curve.get_baked_length()
	var step = 8.0

	var d := 0.0
	while d <= length:
		var local_point = curve.sample_baked(d)
		var world_point = path.to_global(local_point)
		var cell = world_to_cell(world_point)

		blocked_cells[cell] = true

		d += step	
	
# === TOWER SELECTION ===
func _on_tower_selected(scene: PackedScene):
	selected_tower_scene = scene

	if ghost_tower:
		ghost_tower.queue_free()
		ghost_tower = null

	await get_tree().process_frame

	ghost_tower = scene.instantiate()
	ghost_tower.modulate.a = 0.5
	world.add_child(ghost_tower)

	await get_tree().process_frame
	_disable_ghost_behaviors()
	_update_ghost_position()


# === GHOST UPDATE ===
func _process(_delta):
	if ghost_tower:
		_update_ghost_position()
		queue_redraw()


func _update_ghost_position():
	var mouse_world = get_global_mouse_position()
	var cell = world_to_cell(mouse_world)

	ghost_tower.global_position = cell_to_world_center(cell)

	if blocked_cells.has(cell):
		ghost_tower.modulate = Color(1,0,0,0.5)
	else:
		ghost_tower.modulate = Color(0,1,0,0.5)

func _unhandled_input(event):

	if event is InputEventMouseButton and event.pressed:

		var mouse_pos = get_global_mouse_position()

		# =============================
		# CLICK DROIT → annule ghost
		# =============================
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_ghost()
			selected_tower = null
			get_viewport().set_input_as_handled()
			return


		# =============================
		# CLICK GAUCHE
		# =============================
		if event.button_index == MOUSE_BUTTON_LEFT:

			# ---------------------------------
			# Sélection d'une tour existante
			# ---------------------------------
			for tower in $World/TowerContainer.get_children():
				if tower is TowerFire:
					if mouse_pos.distance_to(tower.global_position) < 32:
						selected_tower = tower
						_cancel_ghost()
						get_viewport().set_input_as_handled()
						return

			# Si on clique ailleurs → désélection
			selected_tower = null


			# ---------------------------------
			# 2️⃣ Placement d'une nouvelle tour
			# ---------------------------------
			if ghost_tower and selected_tower_scene:

				var cell = world_to_cell(ghost_tower.global_position)

				if blocked_cells.has(cell):
					get_viewport().set_input_as_handled()
					return

				var final_tower = selected_tower_scene.instantiate()
				final_tower.global_position = cell_to_world_center(cell)

				$World/TowerContainer.add_child(final_tower)

				blocked_cells[cell] = true

				ghost_tower.queue_free()
				ghost_tower = null
				selected_tower_scene = null

				get_viewport().set_input_as_handled()
				await get_tree().create_timer(0.1).timeout
				tower_card.reset()

func _cancel_ghost():
	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = null
	selected_tower_scene = null
	tower_card.reset()


# === GHOST CLEAN ===
func _disable_ghost_behaviors():
	if not ghost_tower:
		return

	if ghost_tower is TowerFire:
		ghost_tower.disable_behaviors()


# === ENEMY SPAWN ===
func _spawn_enemy_instance() -> PathFollow2D:
	if not path_follow_template:
		return null

	var pf: PathFollow2D = path_follow_template.duplicate()
	pf.process_mode = Node.PROCESS_MODE_INHERIT
	pf.set_process(true)
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
