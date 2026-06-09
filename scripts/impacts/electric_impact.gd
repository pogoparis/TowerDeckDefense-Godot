extends Node2D
class_name ElectricImpact

func _ready():
	z_index = 20
	_spawn_flash()
	_spawn_arcs()
	_spawn_ring()
	_auto_free()


# ── Flash instantané ───────────────────────────────────
func _spawn_flash():
	var flash := Node2D.new()
	add_child(flash)

	var draw := Node2D.new()
	flash.add_child(draw)
	draw.draw.connect(func():
		draw.draw_circle(Vector2.ZERO, 30.0, Color(0.9, 1.0, 0.5, 0.9))
		draw.draw_circle(Vector2.ZERO, 16.0, Color(1.0, 1.0, 0.8, 1.0))
		draw.draw_circle(Vector2.ZERO, 7.0,  Color(1.0, 1.0, 1.0, 1.0))
	)
	draw.queue_redraw()

	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.1)
	tween.tween_callback(flash.queue_free)


# ── Arcs électriques rayonnants ────────────────────────
func _spawn_arcs():
	var arc_count := 6

	for i in arc_count:
		var arc_node := Node2D.new()
		add_child(arc_node)

		var base_angle: float = (TAU / arc_count) * i
		var length: float = randf_range(28.0, 52.0)
		var segments := 6

		var points := PackedVector2Array()
		for s in segments + 1:
			var t: float = float(s) / segments
			var r: float = t * length
			var deviation: float = randf_range(-8.0, 8.0) * sin(t * PI)
			var angle: float = base_angle + deg_to_rad(deviation * 0.5)
			points.append(Vector2(cos(angle) * r, sin(angle) * r))

		var draw := Node2D.new()
		arc_node.add_child(draw)
		draw.draw.connect(func():
			draw.draw_polyline(points, Color(0.4, 0.7, 1.0, 0.4), 5.0, true)
			draw.draw_polyline(points, Color(0.9, 1.0, 0.4, 0.9), 2.0, true)
			draw.draw_polyline(points, Color(1.0, 1.0, 1.0, 0.7), 0.8, true)
		)
		draw.queue_redraw()

		var delay: float = randf_range(0.0, 0.06)
		var lifetime: float = randf_range(0.12, 0.22)

		var tween := create_tween()
		tween.tween_property(arc_node, "modulate:a", 0.0, lifetime).set_delay(delay)
		tween.tween_callback(arc_node.queue_free)


# ── Anneau de choc rapide ──────────────────────────────
func _spawn_ring():
	var ring := Node2D.new()
	add_child(ring)
	ring.scale = Vector2(0.1, 0.1)

	var draw := Node2D.new()
	ring.add_child(draw)
	draw.draw.connect(func():
		draw.draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 48, Color(0.8, 1.0, 0.3, 0.8), 3.0)
	)
	draw.queue_redraw()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.6, 1.6), 0.2)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(ring.queue_free)


func _auto_free():
	await get_tree().create_timer(0.4).timeout
	queue_free()
