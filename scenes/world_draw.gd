extends Node2D

@onready var path: Path2D = $Path2D
@onready var tilemap: TileMapLayer = $TileMapLayer


func _ready():
	z_index = 5  # Au-dessus du tilemap
	await get_tree().process_frame
	queue_redraw()
	set_process(true)


func _process(_delta):
	queue_redraw()


func _draw():
	# ==============================
	# DRAW PATH
	# ==============================
	if path and path.curve:
		var curve = path.curve
		var length = curve.get_baked_length()
		var step = 10.0
		
		var prev: Vector2 = Vector2.ZERO
		var has_prev := false
		
		var d := 0.0
		while d <= length:
			var point = path.position + curve.sample_baked(d)
			
			if has_prev:
				draw_line(prev, point, Color(0.9, 0.4, 0.1, 0.5), 35.0)
			
			prev = point
			has_prev = true
			d += step

	# ==============================
	# DRAW BUILD GRID (CORRECTED)
	# ==============================
	if tilemap == null or tilemap.tile_set == null:
		return

	var used_rect := tilemap.get_used_rect()
	var tile_size: Vector2 = tilemap.tile_set.tile_size

	for x in range(used_rect.position.x, used_rect.position.x + used_rect.size.x):
		for y in range(used_rect.position.y, used_rect.position.y + used_rect.size.y):
			var cell := Vector2i(x, y)

			# On ne dessine que les cellules réellement utilisées
			if tilemap.get_cell_source_id(cell) != -1:

				# IMPORTANT :
				# map_to_local() retourne le CENTRE en Godot 4
				var center_local: Vector2 = tilemap.map_to_local(cell)

				# On calcule le coin haut gauche
				var top_left_local: Vector2 = center_local - tile_size * 0.5

				# Conversion en monde
				var top_left_world: Vector2 = tilemap.to_global(top_left_local)

				var rect := Rect2(top_left_world, tile_size)

				# Dessin propre de la case
				draw_rect(
					rect.grow(-2),
					Color(0.2, 0.9, 0.4, 0.35),
					false,
					2.0
				)
