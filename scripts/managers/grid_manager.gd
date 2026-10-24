class_name GridManager
extends Node

@export var current_map: MapData

## Grille fine à la BTD6 : beaucoup de petites cases plutôt que peu de grosses.
## 17x8 cases de 96 px = 1632x768 px, soit à peu près la MÊME surface de jeu
## qu'avant (12x6 de 128) mais 136 emplacements au lieu de 72. Le joueur a de la
## place pour composer une vraie "machine" de tours au lieu de saturer 5 cases.
## ⚠ Si on retouche CELL_SIZE, il faut retoucher `display_height` des tours
## (scenes/towers/*.tscn) dans le même rapport, sinon les sprites débordent.
const GRID_WIDTH := 17
const GRID_HEIGHT := 8
const CELL_SIZE := 96
const GRID_OFFSET_PIXELS = Vector2(200, 200)

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


## Restreint la zone constructible à une BANDE autour du chemin : ne garde que
## les cases constructibles situées à <= [param radius] cases d'une case de
## chemin. Supprime le placement loin dans les coins → placement stratégique.
func restrict_to_path_band(path: Path2D, radius: int = 1) -> void:
	if path == null or path.curve == null:
		return

	# Cases traversées par le chemin (échantillonnage de la courbe).
	var path_cells := {}
	var length := path.curve.get_baked_length()
	var d := 0.0
	while d <= length:
		var wpos: Vector2 = path.to_global(path.curve.sample_baked(d))
		path_cells[world_to_cell(wpos)] = true
		d += CELL_SIZE * 0.4

	# Garde uniquement les cases constructibles proches d'une case de chemin.
	var band: Array[Vector2i] = []
	for c in buildable_cells:
		var near := false
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if path_cells.has(c + Vector2i(dx, dy)):
					near = true
					break
			if near:
				break
		if near:
			band.append(c)
	buildable_cells = band


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
