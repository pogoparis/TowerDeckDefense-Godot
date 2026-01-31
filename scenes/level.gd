extends Node2D

# === NODES ===
@onready var world := $World
@onready var tilemap: TileMapLayer = $World/TileMapLayer
@onready var path: Path2D = $World/Path2D
@onready var tower_card := $UI/TowerCardFire

# === STATE ===
var selected_tower_scene: PackedScene = null
var ghost_tower: Node2D = null
var unbuildable_cells := {} # dictionnaire utilisé comme Set


# === READY ===
func _ready():
	compute_path_cells(1) # largeur du chemin (1 = 3 tiles)
	tower_card.tower_selected.connect(_on_tower_selected)
	queue_redraw()


# === TOWER SELECTION ===
func _on_tower_selected(scene: PackedScene):
	selected_tower_scene = scene

	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = scene.instantiate()
	ghost_tower.modulate.a = 0.5
	world.add_child(ghost_tower)

	_update_ghost_position()


# === GHOST UPDATE ===
func _process(_delta):
	if ghost_tower:
		_update_ghost_position()


func _update_ghost_position():
	var mouse_world: Vector2 = get_global_mouse_position()
	var local_pos: Vector2 = tilemap.to_local(mouse_world)
	var cell: Vector2i = tilemap.local_to_map(local_pos)
	var snapped_local: Vector2 = tilemap.map_to_local(cell)

	ghost_tower.global_position = tilemap.to_global(snapped_local)


# === INPUT ===
func _input(event):
	if not ghost_tower:
		return

	# ESC = annuler
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_ghost()
		return

	if event is InputEventMouseButton and event.pressed:

		# clic droit = annuler
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_ghost()
			return

		# clic gauche = tenter de poser
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_world: Vector2 = get_global_mouse_position()
			var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(mouse_world))

			# interdit sur le chemin
			if unbuildable_cells.has(cell):
				return

			var final_tower = selected_tower_scene.instantiate()
			final_tower.global_position = ghost_tower.global_position
			world.add_child(final_tower)

			_cancel_ghost()


func _cancel_ghost():
	if ghost_tower:
		ghost_tower.queue_free()
	ghost_tower = null
	selected_tower_scene = null


# === PATH → UNBUILDABLE CELLS ===
func compute_path_cells(path_width: int = 1) -> void:
	unbuildable_cells.clear()

	if path == null or path.curve == null:
		return

	var curve := path.curve
	var length := curve.get_baked_length()
	var tile_size: Vector2 = Vector2(tilemap.tile_set.tile_size)
	var step := tile_size.x * 0.5

	var d := 0.0
	while d < length:
		var world_pos: Vector2 = path.to_global(curve.sample_baked(d))
		var local_pos: Vector2 = tilemap.to_local(world_pos)
		var center_cell: Vector2i = tilemap.local_to_map(local_pos)

		for x in range(-path_width, path_width + 1):
			for y in range(-path_width, path_width + 1):
				unbuildable_cells[center_cell + Vector2i(x, y)] = true

		d += step


# === DEBUG DRAW ===
func _draw():
	if unbuildable_cells.is_empty():
		return

	var tile_size: Vector2 = Vector2(tilemap.tile_set.tile_size)

	for cell in unbuildable_cells.keys():
		var local_pos: Vector2 = tilemap.map_to_local(cell)
		draw_rect(
			Rect2(local_pos - tile_size / 2, tile_size),
			Color(1, 0, 1, 0.4)
		)
