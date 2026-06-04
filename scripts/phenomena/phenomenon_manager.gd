extends Node
class_name PhenomenonManager

var active_phenomena: Array[Phenomenon] = []

func spawn_phenomenon(
	type: PhenomenonType.Type,
	world_position: Vector2,
	radius := 64.0,
	duration := 5.0
):

	var phenomenon := Phenomenon.new()

	phenomenon.phenomenon_type = type
	phenomenon.global_position = world_position
	phenomenon.radius = radius
	phenomenon.duration = duration

	add_child(phenomenon)

	active_phenomena.append(phenomenon)

	print(
		"PHENOMENON:",
		type,
		" AT ",
		world_position
	)

func get_active_phenomena() -> Array[Phenomenon]:

	active_phenomena = active_phenomena.filter(
		func(p): return is_instance_valid(p)
	)

	return active_phenomena
