extends Node2D

@onready var path: Path2D = $"../Path2D"
@onready var level := get_parent().get_parent()

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
				draw_line(prev, point, Color(0.9, 0.4, 0.1, 0.5), 20.0)

			prev = point
			d += step


	# =========================
	# GRID VISUELLE 64x64
	# =========================
	var grid_width = 20
	var grid_height = 12
	var cell_size = 64

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
	if level.ghost_tower and level.ghost_tower is TowerFire:

		var ghost = level.ghost_tower
		var range = ghost.attack_range

		var world_pos = ghost.global_position
		var pos = to_local(world_pos)

		var cell = level.world_to_cell(world_pos)

		var fill_color
		var border_color

		if level.blocked_cells.has(cell):
			fill_color = Color(1, 0, 0, 0.2)
			border_color = Color(1, 0, 0, 0.8)
		else:
			fill_color = Color(1, 0.6, 0, 0.15)
			border_color = Color(1, 0.6, 0, 0.8)

		draw_circle(pos, range, fill_color)
		draw_arc(pos, range, 0, TAU, 64, border_color, 2.0)


	# =========================
	# PORTEE TOUR SELECTIONNEE
	# =========================
	if level.selected_tower and level.selected_tower is TowerFire:

		var tower = level.selected_tower
		var range = tower.attack_range

		var world_pos = tower.global_position
		var pos = to_local(world_pos)

		draw_circle(pos, range, Color(0, 0.8, 1, 0.15))
		draw_arc(pos, range, 0, TAU, 64, Color(0, 0.8, 1, 0.9), 2.0)
