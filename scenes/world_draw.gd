extends Node2D

@onready var path: Path2D = $"../Path2D"
@onready var level := get_parent().get_parent()

const CELL_SIZE := 64


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
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

	var grid_width = 20
	var grid_height = 12
	for x in range(grid_width):
		for y in range(grid_height):
			var top_left = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			draw_rect(
				Rect2(top_left, Vector2(CELL_SIZE, CELL_SIZE)),
				Color(0, 1, 0, 0.15),
				false,
				1.0
			)

	_draw_tower_range(level.ghost_tower if level else null, true)
	_draw_tower_range(level.selected_tower if level else null, false)


func _draw_tower_range(tower: Node2D, is_ghost: bool) -> void:
	if not tower:
		return

	var attack_range := 60.0
	if tower is TowerBase and (tower as TowerBase).data:
		attack_range = (tower as TowerBase).data.attack_range
	elif "attack_range" in tower:
		attack_range = tower.attack_range

	var world_pos = tower.global_position
	var pos = to_local(world_pos)
	var cell: Vector2i = level.world_to_cell(world_pos) if level else Vector2i.ZERO

	var fill_color: Color
	var border_color: Color

	if is_ghost:
		if level and level.blocked_cells.has(cell):
			fill_color = Color(1, 0, 0, 0.2)
			border_color = Color(1, 0, 0, 0.8)
		else:
			fill_color = Color(1, 0.6, 0, 0.15)
			border_color = Color(1, 0.6, 0, 0.8)
	else:
		fill_color = Color(0, 0.8, 1, 0.15)
		border_color = Color(0, 0.8, 1, 0.9)

	draw_circle(pos, attack_range, fill_color)
	draw_arc(pos, attack_range, 0, TAU, 64, border_color, 2.0)
