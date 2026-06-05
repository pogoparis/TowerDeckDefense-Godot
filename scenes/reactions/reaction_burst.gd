extends Node2D

var _lifetime: float = 0.6
var _age: float = 0.0
var _reaction_id: String = ""
var _color: Color = Color.WHITE


func setup(reaction_id: String, color: Color) -> void:
	_reaction_id = reaction_id
	_color = color
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	if _age >= _lifetime:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := _age / _lifetime
	var radius := lerpf(12.0, 64.0, t)
	var alpha := 1.0 - t
	var fill := _color
	fill.a = 0.35 * alpha
	draw_circle(Vector2.ZERO, radius, fill)
	var ring := _color.lightened(0.4)
	ring.a = 0.9 * alpha
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, ring, 3.0)
	if _reaction_id == "electrocution":
		for i in range(4):
			var angle := i * TAU / 4.0 + _age * 10.0
			var end := Vector2(cos(angle), sin(angle)) * radius * 0.8
			draw_line(Vector2.ZERO, end, ring, 2.0)
