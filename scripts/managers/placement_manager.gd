class_name PlacementManager
extends Node

var selected_tower_scene: PackedScene = null
var ghost_tower: Node2D = null
var enemy_manager: EnemyManager
const VALID_COLOR = Color(0, 1, 0, 0.5)
const INVALID_COLOR = Color(1, 0, 0, 0.5)
var grid: GridManager
var tower_container: Node2D
var current_mouse_world := Vector2.ZERO
var path: Path2D

func _process(_delta):

	if not grid:
		return

	update_ghost(grid, current_mouse_world)


func is_placing() -> bool:

	return ghost_tower != null

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

func handle_right_click() -> bool:

	if ghost_tower:

		cancel_placement()

		return true

	return false
	
	
func try_place_tower(
	grid: GridManager,
	tower_container: Node2D,
	mouse_world: Vector2
):

	if not ghost_tower or not selected_tower_scene:
		return

	var cell = grid.world_to_cell(mouse_world)

	if not grid.can_place(cell):
		return

	var final_tower = selected_tower_scene.instantiate()
	final_tower.is_ghost = false
	
	final_tower.enemy_manager = enemy_manager
	tower_container.add_child(final_tower)

	final_tower.global_position = grid.cell_to_world(cell)

	final_tower.modulate = Color(1,1,1,1)
	final_tower.z_index = 100

	grid.occupy_cell(cell, final_tower)

	clear_placement()

func update_ghost(grid: GridManager, mouse_world: Vector2):

	if ghost_tower == null:
		return

	var cell = grid.world_to_cell(mouse_world)

	ghost_tower.global_position = grid.cell_to_world(cell)

	if grid.can_place(cell):
		ghost_tower.modulate = VALID_COLOR
	else:
		ghost_tower.modulate = INVALID_COLOR

func start_tower_placement(scene: PackedScene, tower_container: Node2D):

	selected_tower_scene = scene

	create_ghost(scene, tower_container)
		
	block_path_cells()
	_disable_ghost_behaviors()

func _disable_ghost_behaviors():

	if ghost_tower and ghost_tower is BaseTower:

		ghost_tower.is_ghost = true
		ghost_tower.disable_behaviors()

func cancel_placement():

	clear_placement()

func clear_placement():

	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = null
	selected_tower_scene = null

func handle_left_click(mouse_world: Vector2) -> bool:

	if ghost_tower:

		try_place_tower(
			grid,
			tower_container,
			mouse_world
		)

		return true

	return false

	if ghost_tower:
		try_place_tower(
			grid,
			tower_container,
			mouse_world
		)

func create_ghost(scene: PackedScene, parent: Node):

	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = scene.instantiate()

	parent.add_child(ghost_tower)

	ghost_tower.z_index = 999
	ghost_tower.modulate = Color(0, 1, 0, 0.5)
