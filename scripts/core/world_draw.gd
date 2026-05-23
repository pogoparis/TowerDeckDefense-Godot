extends Node2D

@onready var path: Path2D = $"../Path2D"
@onready var level = get_parent().get_parent()

const RANGE_FILL_COLOR = Color(1, 0.6, 0, 0.15)
const RANGE_BORDER_COLOR = Color(1, 0.6, 0, 0.8)
const INVALID_FILL_COLOR = Color(1, 0, 0, 0.2)
const INVALID_BORDER_COLOR = Color(1, 0, 0, 0.8)

func _process(_delta):
	queue_redraw()

func _draw():

	# =========================
	# DESSIN DU PATH
	# =========================
	if path and path.curve:
		var curve = path.curve
		var length = curve.get_baked_length()
		var step = 10.0

		var prev = null
		var d = 0.0

		while d <= length:
			var local_point = curve.sample_baked(d)
			var world_point = path.to_global(local_point)
			var point = to_local(world_point)

			if prev != null:
				draw_line(prev, point, Color(0.8, 0.3, 0.1, 0.7), 28.0)

			prev = point
			d += step


		# =========================
		# GRID VISUELLE 64x64
		# =========================
	var cell_size = 64
	var viewport_size = get_viewport_rect().size
	var grid_width = int(viewport_size.x / cell_size)
	var grid_height = int(viewport_size.y / cell_size)

	for x in range(grid_width):
		for y in range(grid_height):
			var top_left = Vector2(x * cell_size, y * cell_size)
			draw_rect(
				Rect2(top_left, Vector2(cell_size, cell_size)),
				Color(0, 1, 0, 0.15),
				false,
				1.0
			)


	# =========================
	# PORTEE DU GHOST
	# =========================
	if level.placement.ghost_tower and level.placement.ghost_tower is TowerFire:

		var ghost = level.placement.ghost_tower
		var attack_range = ghost.attack_range

		var world_pos = ghost.global_position
		var pos = to_local(world_pos)
		var fill_color
		var border_color
		var mouse_world = get_global_mouse_position()
		var cell = level.grid.world_to_cell(mouse_world)

		if level.grid.blocked_cells.has(cell):
			fill_color = INVALID_FILL_COLOR
			border_color = INVALID_BORDER_COLOR
		else:
			fill_color = RANGE_FILL_COLOR
			border_color = RANGE_BORDER_COLOR

		draw_circle(pos, attack_range, fill_color)
		draw_arc(pos, attack_range, 0, TAU, 64, border_color, 2.0)


	# =========================
	# PORTEE TOUR SELECTIONNEE
	# =========================
	if level.selected_tower and level.selected_tower is TowerFire:

		var tower = level.selected_tower
		var attack_range = tower.attack_range

		var world_pos = tower.global_position
		var pos = to_local(world_pos)

		draw_circle(pos, attack_range, Color(1, 0.6, 0, 0.15))
		draw_arc(pos, attack_range, 0, TAU, 64, Color(1, 0.6, 0, 0.8), 2.0)
