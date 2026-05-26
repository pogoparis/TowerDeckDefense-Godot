extends Node2D

func _ready():

	var tween = create_tween()

	tween.tween_property(
		self,
		"scale",
		scale * 1.4,
		0.12
	)

	tween.parallel().tween_property(
		self,
		"modulate:a",
		0.0,
		0.12
	)

	await tween.finished

	queue_free()
