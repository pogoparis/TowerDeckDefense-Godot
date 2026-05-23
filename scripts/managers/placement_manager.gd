class_name PlacementManager
extends Node

var selected_tower_scene: PackedScene = null
var ghost_tower: Node2D = null
const VALID_COLOR = Color(0, 1, 0, 0.5)
const INVALID_COLOR = Color(1, 0, 0, 0.5)

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

func start_placing_tower(scene: PackedScene):

	selected_tower_scene = scene
	

func clear_placement():

	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = null
	selected_tower_scene = null

func create_ghost(scene: PackedScene, parent: Node):

	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = scene.instantiate()

	parent.add_child(ghost_tower)

	ghost_tower.z_index = 999
	ghost_tower.modulate = Color(0, 1, 0, 0.5)
