extends Node2D

var _lifetime: float = 1.8
var _text: String = ""
var _color: Color = Color.WHITE
var _age: float = 0.0


func setup(text: String, color: Color) -> void:
	_text = text
	_color = color
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	position.y -= 28.0 * delta
	if _age >= _lifetime:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 - (_age / _lifetime)
	var font := ThemeDB.fallback_font
	var font_size := 18
	var c := _color
	c.a = alpha
	draw_string(font, Vector2(-40, 0), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, c)
