class_name PlacementManager
extends Node

var selected_tower_scene: PackedScene = null
var ghost_tower: Node2D = null
var enemy_manager: EnemyManager
var tower_manager: TowerManager
const VALID_COLOR = Color(0, 1, 0, 0.5)
const INVALID_COLOR = Color(1, 0, 0, 0.5)
var grid: GridManager
var tower_container: Node2D
var current_mouse_world := Vector2.ZERO
var path: Path2D
var selected_card : CardData = null

func _process(_delta):

	if not grid:
		return

	update_ghost(grid, current_mouse_world)


func is_placing() -> bool:

	return ghost_tower != null

func handle_input(event, mouse_world: Vector2) -> bool:

	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_RIGHT:

			return handle_right_click()

		if event.button_index == MOUSE_BUTTON_LEFT:

			return handle_left_click(mouse_world)

	return false

func setup(
	new_grid: GridManager,
	new_tower_container: Node2D,
	new_path: Path2D,
	new_enemy_manager: EnemyManager,
	new_tower_manager: TowerManager
	
):
	
	tower_manager = new_tower_manager
	grid = new_grid
	tower_container = new_tower_container
	path = new_path
	enemy_manager = new_enemy_manager

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
	
	
func try_place_tower(mouse_world: Vector2):

	print("TRY PLACE")

	if not selected_tower_scene:
		print("NO SCENE")
		return

	var cell = grid.world_to_cell(mouse_world)

	print("CELL :", cell)

	if not grid.can_place(cell):
		print("CANNOT PLACE")
		return

	print("CAN PLACE")

	if selected_card:

		print("CARD :", selected_card.card_name)
		print("COST :", selected_card.mana_cost)

		if not Player.spend_caps(selected_card.mana_cost):

			print("NOT ENOUGH Caps")
			return

		print("GOLD PAID")

	var final_tower = tower_manager.create_tower(
		selected_tower_scene,
		grid.cell_to_world(cell),
		enemy_manager
	)

	print("TOWER CREATED")

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

func start_tower_placement(
	scene: PackedScene,
	card: CardData,
	tower_container: Node2D
):
	
	selected_tower_scene = scene
	selected_card = card

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
		
	selected_card = null
	ghost_tower = null
	selected_tower_scene = null

func handle_left_click(mouse_world: Vector2) -> bool:

	if ghost_tower:

		try_place_tower(mouse_world)

		return true

	return false

	if ghost_tower:
		try_place_tower(mouse_world)

func create_ghost(scene: PackedScene, parent: Node):
	
	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = scene.instantiate()
	
	parent.add_child(ghost_tower)

	ghost_tower.z_index = 999
	ghost_tower.modulate = Color(0, 1, 0, 0.5)
