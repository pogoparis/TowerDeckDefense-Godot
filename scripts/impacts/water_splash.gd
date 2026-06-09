extends Node2D
class_name WaterSplash

func _ready():
	z_index = 20
	_spawn_ring()
	_spawn_droplets()
	_spawn_center_burst()
	_auto_free()


# ── Anneau d'onde qui s'étend ──────────────────────────
func _spawn_ring():
	var ring := Node2D.new()
	add_child(ring)
	ring.scale = Vector2(0.1, 0.1)

	var draw := Node2D.new()
	ring.add_child(draw)
	var color := Color(0.3, 0.75, 1.0, 0.8)
	draw.draw.connect(func():
		draw.draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 48, color, 4.0)
	)
	draw.queue_redraw()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(2.2, 0.6), 0.4)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.4).set_delay(0.1)
	tween.chain().tween_callback(ring.queue_free)


# ── Gouttelettes qui s'envolent et retombent ──────────
func _spawn_droplets():
	var count := 10

	for i in count:
		var drop := Node2D.new()
		add_child(drop)

		var angle: float = (TAU / count) * i + randf_range(-0.3, 0.3)
		var speed: float = randf_range(60.0, 160.0)
		var gravity: float = randf_range(180.0, 280.0)
		var lifetime: float = randf_range(0.3, 0.55)

		var vel := Vector2(cos(angle) * speed, sin(angle) * speed - randf_range(80.0, 140.0))

		var size: float = randf_range(3.0, 7.0)
		var draw := Node2D.new()
		drop.add_child(draw)
		var c := Color(randf_range(0.1, 0.3), randf_range(0.6, 0.9), 1.0, 0.9)
		draw.draw.connect(func(): draw.draw_circle(Vector2.ZERO, size, c))
		draw.queue_redraw()

		# Simule la gravité via deux tweens enchaînés
		var tween := drop.create_tween()
		tween.set_parallel(true)
		tween.tween_property(drop, "position",
			Vector2(vel.x * lifetime, vel.y * lifetime + 0.5 * gravity * lifetime * lifetime),
			lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(drop, "modulate:a", 0.0, lifetime).set_delay(lifetime * 0.5)
		tween.chain().tween_callback(drop.queue_free)


# ── Éclaboussure centrale ──────────────────────────────
func _spawn_center_burst():
	var burst := Node2D.new()
	add_child(burst)
	burst.scale = Vector2(0.3, 0.3)

	var draw := Node2D.new()
	burst.add_child(draw)
	draw.draw.connect(func():
		draw.draw_circle(Vector2.ZERO, 22.0, Color(0.5, 0.85, 1.0, 0.7))
		draw.draw_circle(Vector2.ZERO, 13.0, Color(0.8, 0.95, 1.0, 0.9))
		draw.draw_circle(Vector2.ZERO, 6.0,  Color(1.0, 1.0,  1.0, 1.0))
	)
	draw.queue_redraw()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2(1.2, 1.2), 0.2)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(burst.queue_free)


func _auto_free():
	await get_tree().create_timer(0.7).timeout
	queue_free()
