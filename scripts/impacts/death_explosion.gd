extends Node2D
class_name DeathExplosion

# Taille de l'explosion (rayon de base)
@export var size := 1.0


func _ready():
	z_index = 20
	_spawn_flash()
	_spawn_fireball()
	_spawn_shockwave()
	_spawn_sparks()
	_spawn_smoke()
	_auto_free()


# ─────────────────────────────────────────
# FLASH — éclair blanc instantané
# ─────────────────────────────────────────
func _spawn_flash():
	var flash := ColorRect.new()
	add_child(flash)

	var r := 80.0 * size
	flash.size = Vector2(r * 2, r * 2)
	flash.position = Vector2(-r, -r)
	flash.color = Color(1.0, 0.95, 0.7, 0.9)

	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.08)
	tween.tween_callback(flash.queue_free)


# ─────────────────────────────────────────
# BOULE DE FEU — cercle qui s'étend
# ─────────────────────────────────────────
func _spawn_fireball():
	var ball := Node2D.new()
	add_child(ball)
	ball.scale = Vector2(0.2, 0.2) * size

	# Plusieurs anneaux colorés pour donner du volume
	var layers := [
		[Color(1.0, 1.0, 0.5, 0.9),  52.0 * size],
		[Color(1.0, 0.5, 0.0, 0.85), 64.0 * size],
		[Color(0.8, 0.15, 0.0, 0.8), 72.0 * size],
		[Color(0.15, 0.1, 0.1, 0.6), 80.0 * size],
	]

	for layer in layers:
		var circle := _make_circle_node(layer[0], layer[1])
		ball.add_child(circle)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ball, "scale", Vector2(size, size), 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(ball, "modulate:a", 0.0, 0.45).set_delay(0.1)
	tween.chain().tween_callback(ball.queue_free)


# ─────────────────────────────────────────
# ANNEAU DE CHOC — cercle qui se dilate
# ─────────────────────────────────────────
func _spawn_shockwave():
	var ring := Node2D.new()
	add_child(ring)
	ring.scale = Vector2(0.1, 0.1)

	var draw := Node2D.new()
	ring.add_child(draw)
	var ring_radius := 90.0 * size
	var ring_color := Color(1.0, 0.8, 0.4, 0.7)
	draw.draw.connect(func():
		draw.draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 64, ring_color, 6.0)
	)
	draw.queue_redraw()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(size * 1.4, size * 1.4), 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.4).set_delay(0.05)
	tween.chain().tween_callback(ring.queue_free)


# ─────────────────────────────────────────
# ÉTINCELLES — particules qui partent en étoile
# ─────────────────────────────────────────
func _spawn_sparks():
	var count := int(12 * size)

	for i in count:
		var spark := Node2D.new()
		add_child(spark)

		var angle := (TAU / count) * i + randf_range(-0.3, 0.3)
		var speed := randf_range(180.0, 380.0) * size
		var vel := Vector2(cos(angle), sin(angle)) * speed
		var lifetime := randf_range(0.35, 0.6)

		var dot := ColorRect.new()
		dot.size = Vector2(6, 6) * randf_range(0.6, 1.4)
		dot.position = -dot.size / 2.0
		dot.color = Color(1.0, randf_range(0.4, 0.9), 0.0, 1.0)
		spark.add_child(dot)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "position", vel * lifetime, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "modulate:a", 0.0, lifetime).set_delay(lifetime * 0.4)
		tween.chain().tween_callback(spark.queue_free)


# ─────────────────────────────────────────
# FUMÉE — cercles sombres qui montent
# ─────────────────────────────────────────
func _spawn_smoke():
	var count := int(6 * size)

	for i in count:
		var puff := Node2D.new()
		add_child(puff)

		puff.position = Vector2(
			randf_range(-40.0, 40.0) * size,
			randf_range(-20.0, 20.0) * size
		)
		puff.scale = Vector2.ONE * randf_range(0.3, 0.7) * size

		var r := randf_range(30.0, 55.0)
		var grey := randf_range(0.1, 0.3)
		var circle := _make_circle_node(Color(grey, grey, grey, 0.55), r)
		puff.add_child(circle)

		var rise := randf_range(60.0, 120.0) * size
		var lifetime := randf_range(0.5, 0.9)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(puff, "position:y", puff.position.y - rise, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(puff, "scale", puff.scale * 2.2, lifetime)
		tween.tween_property(puff, "modulate:a", 0.0, lifetime).set_delay(lifetime * 0.3)
		tween.chain().tween_callback(puff.queue_free)


# ─────────────────────────────────────────
# UTILITAIRE — cercle dessiné
# ─────────────────────────────────────────
func _make_circle_node(color: Color, radius: float) -> Node2D:
	var node := Node2D.new()
	node.draw.connect(func():
		node.draw_circle(Vector2.ZERO, radius, color)
	)
	node.queue_redraw()
	return node


# ─────────────────────────────────────────
# AUTO DESTROY après la durée max
# ─────────────────────────────────────────
func _auto_free():
	await get_tree().create_timer(1.2).timeout
	queue_free()
