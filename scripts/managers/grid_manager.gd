class_name GridManager
extends Node

@export var current_map: MapData

const GRID_WIDTH := 10
const GRID_HEIGHT := 5
const CELL_SIZE := 128
const GRID_OFFSET_PIXELS = Vector2(250, 200)

var blocked_cells := {}
var occupied_cells := {}
var buildable_cells: Array[Vector2i] = []


func setup_buildable_cells():

	if current_map == null:
		push_error("No MapData assigned to GridManager")
		return

	blocked_cells.clear()
	buildable_cells.clear()

	for cell in current_map.blocked_cells:
		blocked_cells[cell] = true

	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):

			var cell = Vector2i(x, y)

			if blocked_cells.has(cell):
				continue

			buildable_cells.append(cell)


func world_to_cell(pos: Vector2) -> Vector2i:

	pos -= GRID_OFFSET_PIXELS

	var cell = Vector2i(
		floor(pos.x / CELL_SIZE),
		floor(pos.y / CELL_SIZE)
	)

	return cell


func cell_to_world(cell: Vector2i) -> Vector2:

	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE * 0.5,
		cell.y * CELL_SIZE + CELL_SIZE * 0.5
	) + GRID_OFFSET_PIXELS

func is_cell_blocked(cell: Vector2i) -> bool:

	return blocked_cells.has(cell)


func is_cell_occupied(cell: Vector2i) -> bool:

	return occupied_cells.has(cell)


func can_place(cell: Vector2i) -> bool:

	# Hors de la zone constructible
	if not buildable_cells.has(cell):
		return false

	# Route / décor bloqué
	if blocked_cells.has(cell):
		return false

	# Une tour est déjà présente
	if occupied_cells.has(cell):
		return false

	return true

func occupy_cell(cell: Vector2i, tower: Node2D):

	occupied_cells[cell] = tower


func free_cell(cell: Vector2i):

	occupied_cells.erase(cell)


func get_neighbors(cell: Vector2i) -> Array:

	var neighbors := []

	var directions = [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN
	]

	for dir in directions:

		var neighbor_cell = cell + dir

		if occupied_cells.has(neighbor_cell):

			neighbors.append(
				occupied_cells[neighbor_cell]
			)

	return neighbors
