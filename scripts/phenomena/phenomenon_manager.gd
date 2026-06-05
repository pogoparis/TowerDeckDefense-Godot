extends Node
class_name PhenomenonManager

const MERGE_DISTANCE := 96.0

var active_phenomena: Array[Phenomenon] = []

func spawn_phenomenon(
	type: PhenomenonType.Type,
	world_position: Vector2,
	radius := 64.0,
	duration := 5.0
):

	for existing in active_phenomena:

		if not is_instance_valid(existing):
			continue

		if existing.phenomenon_type != type:
			continue

		var dist = existing.global_position.distance_to(
			world_position
		)

		if dist > MERGE_DISTANCE:
			continue

		existing.refresh()

		print(
			"PHENOMENON MERGED : ",
			type,
			" POWER=",
			existing.power
		)

		return

	var phenomenon := Phenomenon.new()

	phenomenon.phenomenon_type = type
	phenomenon.global_position = world_position
	phenomenon.radius = radius
	phenomenon.duration = duration

	add_child(phenomenon)

	active_phenomena.append(phenomenon)


func remove_phenomenon(
	phenomenon: Phenomenon
):

	active_phenomena.erase(phenomenon)

	if is_instance_valid(phenomenon):
		phenomenon.queue_free()


func get_active_phenomena() -> Array[Phenomenon]:

	active_phenomena = active_phenomena.filter(
		func(p): return is_instance_valid(p)
	)

	return active_phenomena
