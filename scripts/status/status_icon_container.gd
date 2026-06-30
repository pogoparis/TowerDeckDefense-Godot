extends Node2D
class_name StatusIconContainer

var icons := {}

func update_statuses(status_effects: Dictionary):

	for child in get_children():
		child.queue_free()

	icons.clear()

	var index := 0

	for status_id in status_effects.keys():

		var info := get_icon_info(status_id)
		if info.texture == null:
			continue

		var sprite := Sprite2D.new()
		sprite.texture = info.texture
		sprite.modulate = info.color
		sprite.scale = Vector2.ONE * 0.35
		sprite.position = Vector2(index * 22, 0)

		add_child(sprite)
		index += 1


func get_icon_info(status_id: String) -> Dictionary:
	match status_id:
		StatusIds.WET:
			return { texture = load("res://assets/status/WaterIcon64.png"),    color = Color.WHITE }
		StatusIds.CHARGED:
			return { texture = load("res://assets/status/ThunderIcon64.png"),  color = Color(1.0, 0.95, 0.2) }
		StatusIds.STUNNED:
			return { texture = load("res://assets/status/WindIcon64.png"),     color = Color(0.6, 0.8, 1.0) }
		StatusIds.BURNING:
			return { texture = load("res://assets/status/FireIcon64.png"),     color = Color.WHITE }
		StatusIds.ROOTED:
			return { texture = load("res://assets/status/NatureIcon64.png"),   color = Color.WHITE }
		StatusIds.WINDMARK:
			return { texture = load("res://assets/status/WindIcon64.png"),     color = Color.WHITE }
	return { texture = null, color = Color.WHITE }
