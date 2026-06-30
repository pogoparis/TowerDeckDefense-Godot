extends Node2D
class_name WindHitEffect

func _ready() -> void:
	z_index = 30
	_spawn_streaks()
	_spawn_ring()
	# auto-free quand tout est fini
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_callback(queue_free)


func _spawn_streaks() -> void:
	var streak_count := 6
	for i in streak_count:
		var length: float = randf_range(30.0, 70.0)
		var col := Color(0.75, 0.95, 1.0, randf_range(0.6, 0.9))
		var travel: float  = randf_range(18.0, 40.0)
		var lifetime: float = randf_range(0.2, 0.38)
		var delay_val: float = randf_range(0.0, 0.08)

		var streak := WindStreak.new(length, col)
		streak.position = Vector2(randf_range(-10.0, 20.0), randf_range(-28.0, 28.0))
		add_child(streak)

		var tween := streak.create_tween()
		tween.set_parallel(true)
		tween.tween_property(streak, "position:x", streak.position.x - travel, lifetime) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_delay(delay_val)
		tween.tween_property(streak, "modulate:a", 0.0, lifetime * 0.7) \
			.set_delay(delay_val + lifetime * 0.3)
		tween.chain().tween_callback(streak.queue_free)


func _spawn_ring() -> void:
	var ring := WindRing.new()
	ring.scale = Vector2(0.1, 0.1)
	add_child(ring)

	var rtween := ring.create_tween()
	rtween.set_parallel(true)
	rtween.tween_property(ring, "scale", Vector2(1.5, 0.8), 0.28) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	rtween.tween_property(ring, "modulate:a", 0.0, 0.28)
	rtween.chain().tween_callback(ring.queue_free)


# ── Nœuds de dessin internes ──────────────────────────

class WindStreak extends Node2D:
	var _length: float
	var _col: Color

	func _init(length: float, col: Color) -> void:
		_length = length
		_col = col

	func _draw() -> void:
		draw_line(Vector2.ZERO, Vector2(-_length, 0), _col, 2.5)
		draw_line(Vector2.ZERO, Vector2(-_length * 0.7, 0),
			Color(_col.r, _col.g, _col.b, _col.a * 0.3), 6.0)


class WindRing extends Node2D:
	func _draw() -> void:
		draw_arc(Vector2.ZERO, 32.0, -PI * 0.7, PI * 0.7, 24,
			Color(0.6, 0.9, 1.0, 0.8), 3.5)
