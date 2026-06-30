extends Node2D
class_name ExplosionChain

const RING_RADIUS := 120.0

func _ready() -> void:
	z_index = 50
	queue_redraw()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.25) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	draw_arc(Vector2.ZERO, RING_RADIUS, 0.0, TAU, 48, Color(1.0, 0.5, 0.1, 0.7), 5.0)
	draw_circle(Vector2.ZERO, 35.0, Color(1.0, 0.65, 0.1, 0.8))
	draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.9,  0.4, 0.9))
	draw_circle(Vector2.ZERO,  8.0, Color(1.0, 1.0,  1.0, 1.0))
