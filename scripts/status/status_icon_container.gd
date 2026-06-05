extends Node2D
class_name StatusIconContainer

const ICON_SIZE := 20.0

var icons := {}

func update_statuses(
	
	status_effects: Dictionary
):

	for child in get_children():
		child.queue_free()

	icons.clear()

	var index := 0

	for status_id in status_effects.keys():

		var texture := get_texture_for_status(
			status_id
		)

		if texture == null:
			continue

		var sprite := Sprite2D.new()

		sprite.texture = texture

		sprite.scale = Vector2.ONE * 0.35

		sprite.position = Vector2(
			index * 22,
			0
		)

		add_child(sprite)

		index += 1

func get_texture_for_status(
	status_id: String
) -> Texture2D:

	match status_id:

		StatusIds.WET:
			return load(
				"res://assets/status/WaterIcon64.png"
			)

		StatusIds.CHARGED:
			return load(
				"res://assets/status/ThunderIcon64.png"
			)

		StatusIds.BURNING:
			return load(
				"res://assets/status/FireIcon64.png"
			)

		StatusIds.ROOTED:
			return load(
				"res://assets/status/NatureIcon64.png"
			)

		StatusIds.WINDMARK:
			return load(
				"res://assets/status/WindIcon64.png"
			)

	return null
