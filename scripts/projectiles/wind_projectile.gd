extends BaseProjectile
class_name WindProjectile

# ── Paramètres de knockback ───────────────────────────
@export var knockback_force := 40.0   # pixels reculés sur le chemin

# ── Visuels rafale de vent ────────────────────────────
var _age := 0.0
const LIFETIME := 0.35


func _ready():
	# Pas de sprite à cacher, tout est dessiné en code
	_regenerate()


func _regenerate():
	queue_redraw()


func _process(delta):
	super._process(delta)
	_age += delta
	queue_redraw()


func _draw():
	var t: float = _age / LIFETIME   # 0→1 pendant la vie

	# 3 arcs de vent en éventail, de plus en plus transparents avec l'âge
	var arcs := [
		{"offset": -18.0, "len": 38.0, "w": 4.0},
		{"offset":   0.0, "len": 48.0, "w": 6.0},
		{"offset":  18.0, "len": 38.0, "w": 4.0},
	]

	for arc_def in arcs:
		var pts := PackedVector2Array()
		var segs := 8
		for i in segs + 1:
			var s: float = float(i) / segs
			# Arc courbé vers l'avant (axe X = direction du tir)
			var x: float = lerp(0.0, arc_def["len"], s)
			var y: float = arc_def["offset"] * sin(s * PI)
			# Légère ondulation secondaire
			y += sin(s * TAU * 2.0 + _age * 12.0) * 4.0
			pts.append(Vector2(x, y))

		var alpha: float = lerp(0.85, 0.0, t)
		# Halo extérieur bleu clair
		draw_polyline(pts, Color(0.6, 0.88, 1.0, alpha * 0.5), arc_def["w"] + 4.0, true)
		# Filet principal blanc-bleu
		draw_polyline(pts, Color(0.85, 0.97, 1.0, alpha), arc_def["w"], true)
		# Cœur blanc
		draw_polyline(pts, Color(1.0, 1.0, 1.0, alpha * 0.7), arc_def["w"] * 0.4, true)

	# Petites particules qui s'envolent
	var particle_count := 5
	for i in particle_count:
		var s: float = float(i) / particle_count
		var px: float = lerp(8.0, 50.0, s) * (1.0 - t * 0.3)
		var py: float = sin(s * TAU + _age * 8.0) * 14.0
		var pr: float = lerp(4.0, 1.5, t)
		var pa: float = lerp(0.7, 0.0, t) * (1.0 - abs(s - 0.5) * 1.5)
		draw_circle(Vector2(px, py), pr, Color(0.8, 0.95, 1.0, pa))


func on_hit(target):
	target.take_damage(damage)
	if target is EnemyBase:
		target.add_status(StatusIds.WINDMARK, 1.5)
		target.apply_slow(0.35, 1.5)   # Ralentissement 65% — pas de knockback

	_spawn_wind_hit(target.global_position)


func _spawn_wind_hit(hit_pos: Vector2):
	var root := Node2D.new()
	get_parent().add_child(root)
	root.global_position = hit_pos
	root.z_index = 30

	# ── Lignes de vent qui filent vers la gauche (recul) ──
	var streak_count := 6
	for i in streak_count:
		var streak := Node2D.new()
		root.add_child(streak)
		streak.position = Vector2(
			randf_range(-10.0, 20.0),
			randf_range(-28.0, 28.0)
		)

		var length: float = randf_range(30.0, 70.0)
		var draw := Node2D.new()
		streak.add_child(draw)
		var c := Color(0.75, 0.95, 1.0, randf_range(0.6, 0.9))
		draw.draw.connect(func():
			# Ligne principale
			draw.draw_line(Vector2(0, 0), Vector2(-length, 0), c, 2.5)
			# Halo
			draw.draw_line(Vector2(0, 0), Vector2(-length * 0.7, 0),
				Color(c.r, c.g, c.b, c.a * 0.3), 6.0)
		)
		draw.queue_redraw()

		var travel: float = randf_range(18.0, 40.0)
		var lifetime: float = randf_range(0.2, 0.38)
		var delay_val: float = randf_range(0.0, 0.08)

		var tween := streak.create_tween()
		tween.set_parallel(true)
		tween.tween_property(streak, "position:x", streak.position.x - travel, lifetime)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_delay(delay_val)
		tween.tween_property(streak, "modulate:a", 0.0, lifetime * 0.7).set_delay(delay_val + lifetime * 0.3)
		tween.chain().tween_callback(streak.queue_free)

	# ── Anneau de souffle ──────────────────────────────
	var ring := Node2D.new()
	root.add_child(ring)
	ring.scale = Vector2(0.1, 0.1)

	var rdraw := Node2D.new()
	ring.add_child(rdraw)
	rdraw.draw.connect(func():
		rdraw.draw_arc(Vector2.ZERO, 32.0, -PI * 0.7, PI * 0.7, 24,
			Color(0.6, 0.9, 1.0, 0.8), 3.5)
	)
	rdraw.queue_redraw()

	var rtween := ring.create_tween()
	rtween.set_parallel(true)
	rtween.tween_property(ring, "scale", Vector2(1.5, 0.8), 0.28)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	rtween.tween_property(ring, "modulate:a", 0.0, 0.28)
	rtween.chain().tween_callback(ring.queue_free)

	# Auto-free
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_callback(root.queue_free)
