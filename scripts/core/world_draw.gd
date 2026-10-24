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
	# BUILD GRID
	# =========================

	var cell_size = level.grid.CELL_SIZE

	# Cases bloquées (rouges)
	for cell in level.grid.current_map.blocked_cells:

		var center = level.grid.cell_to_world(cell)

		var pos = center - Vector2(
			cell_size * 0.5,
			cell_size * 0.5
		)

		draw_rect(
			Rect2(
				pos,
				Vector2.ONE * cell_size
			),
			Color(1, 0, 0, 0.6)
		)
	for x in level.grid.GRID_WIDTH:
		for y in level.grid.GRID_HEIGHT:

			var cell = Vector2i(x, y)
			var center = level.grid.cell_to_world(cell)

			var pos = center - Vector2(
				cell_size * 0.5,
				cell_size * 0.5
			)

			draw_rect(
				Rect2(
					pos,
					Vector2.ONE * cell_size
				),
				Color(0, 1, 0, 0.1),
				false,
				2.0
			)
	# On dessine uniquement les blocked_cells
	for cell in level.grid.current_map.blocked_cells:

		var center = level.grid.cell_to_world(cell)

		var pos = center - Vector2(
			cell_size * 0.5,
			cell_size * 0.5
		)

		draw_rect(
			Rect2(
				pos,
				Vector2.ONE * cell_size
			),
			Color(0, 1, 0, 0.1),
			false,
			2.0
		)

	# =========================
	# PORTEE DU GHOST
	# =========================
	if level.placement.ghost_tower and level.placement.ghost_tower is BaseTower:

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
	# VISEE DE SORT
	# =========================
	# Sans ce retour, le joueur lance à l'aveugle et ne peut pas apprendre la
	# portée de ses sorts. Violet franc : ni l'orange de la sélection, ni le
	# vert/rouge de la pose de tour — c'est un troisième mode, il doit se lire
	# comme tel du premier coup d'œil.
	if level.placement.selected_spell != null:
		var spell: SpellData = level.placement.selected_spell
		var aim := to_local(get_global_mouse_position())
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)

		draw_circle(aim, spell.radius, Color(0.72, 0.35, 1.0, 0.16))
		draw_arc(aim, spell.radius, 0, TAU, 64, Color(0.85, 0.55, 1.0, 0.85), 2.5)
		# Anneau pulsant : signale que le jeu attend un clic.
		draw_arc(aim, spell.radius * (0.90 + 0.06 * pulse), 0, TAU, 48,
			Color(1.0, 0.8, 1.0, 0.35), 1.5)
		# Croix de visée au centre, pour placer précisément.
		draw_line(aim + Vector2(-14, 0), aim + Vector2(14, 0), Color(1, 1, 1, 0.8), 2.0)
		draw_line(aim + Vector2(0, -14), aim + Vector2(0, 14), Color(1, 1, 1, 0.8), 2.0)


	# =========================
	# PORTEE TOUR SELECTIONNEE
	# =========================
	if level.tower_manager.selected_tower and level.tower_manager.selected_tower is BaseTower:
		
		var tower = level.tower_manager.selected_tower
		var attack_range = tower.attack_range

		var world_pos = tower.global_position
		var pos = to_local(world_pos)

		draw_circle(pos, attack_range, Color(1, 0.6, 0, 0.15))
		draw_arc(pos, attack_range, 0, TAU, 64, Color(1, 0.6, 0, 0.8), 2.0)
