class_name GridManager
extends Node

const CELL_SIZE := 96

var blocked_cells := {}
var occupied_cells := {}
var buildable_cells := {}

func setup_buildable_cells():

	buildable_cells.clear()

	for x in range(10):
		for y in range(5):

			buildable_cells[
				Vector2i(x + 1, y + 1)
			] = true

	print("BUILD CELLS :", buildable_cells.size())


func world_to_cell(pos: Vector2) -> Vector2i:

	return Vector2i(
		floor(pos.x / CELL_SIZE),
		floor(pos.y / CELL_SIZE)
	)


func cell_to_world(cell: Vector2i) -> Vector2:

	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE * 0.5,
		cell.y * CELL_SIZE + CELL_SIZE * 0.5
	)


func is_cell_blocked(cell: Vector2i) -> bool:

	return blocked_cells.has(cell)


func is_cell_occupied(cell: Vector2i) -> bool:

	return occupied_cells.has(cell)


func can_place(cell: Vector2i) -> bool:

	return (
		buildable_cells.has(cell)
		and not is_cell_blocked(cell)
		and not is_cell_occupied(cell)
	)


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
