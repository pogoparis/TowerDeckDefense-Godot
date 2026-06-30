extends Node2D
class_name LightningFlash

var _pts: PackedVector2Array

func _ready() -> void:
	z_index = 30
	_generate_bolt()
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)


func _generate_bolt() -> void:
	_pts = PackedVector2Array()
	var steps := 8
	for i in steps + 1:
		var t: float = float(i) / steps
		var x: float = randf_range(-12.0, 12.0) * (1.0 - t)
		var y: float = lerp(-80.0, 20.0, t)
		_pts.append(Vector2(x, y))


func _draw() -> void:
	draw_polyline(_pts, Color(0.5, 0.8,  1.0, 0.5),  12.0, true)
	draw_polyline(_pts, Color(0.85, 0.95, 1.0, 1.0),   4.0, true)
	draw_polyline(_pts, Color(1.0,  1.0,  1.0, 0.9),   1.5, true)
	draw_circle(Vector2.ZERO, 30.0, Color(0.6, 0.85, 1.0, 0.45))
