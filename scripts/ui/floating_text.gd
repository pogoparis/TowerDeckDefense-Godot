extends Node2D

@export var lifetime := 1.8
@export var rise_distance := 50.0

@onready var text_label: RichTextLabel = $RichTextLabel

func setup(
	text: String,
	color: Color = Color.WHITE,
	text_scale: float = 1.2
) -> void:

	text_label.text = text

	modulate = color
	scale = Vector2(text_scale, text_scale)

	var tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		self,
		"position:y",
		position.y - rise_distance,
		lifetime
	)

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		lifetime
	)

	await tween.finished

	queue_free()
