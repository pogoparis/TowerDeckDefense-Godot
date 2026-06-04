extends Node
class_name ReactionManager

@onready var phenomenon_manager: PhenomenonManager = $"../PhenomenonManager"

const REACTION_DISTANCE := 64.0

var active_pairs := {}

func _process(_delta):

	check_electrocution()


func check_electrocution():

	var phenomena = phenomenon_manager.get_active_phenomena()

	for water in phenomena:

		if not is_instance_valid(water):
			continue

		if water.phenomenon_type != PhenomenonType.Type.WATER_POOL:
			continue

		for electric in phenomena:

			if not is_instance_valid(electric):
				continue

			if electric == water:
				continue

			if electric.phenomenon_type != PhenomenonType.Type.ELECTRIC_FIELD:
				continue
			var distance_between = water.global_position.distance_to(
				electric.global_position
			)

			if distance_between > REACTION_DISTANCE:
				continue

			var pair_id := str(
				water.get_instance_id(),
				"_",
				electric.get_instance_id()
			)

			if active_pairs.has(pair_id):
				continue

			active_pairs[pair_id] = true

			trigger_electrocution(
				water,
				electric
			)


func trigger_electrocution(
	water: Phenomenon,
	electric: Phenomenon
):

	var center := (
		water.global_position +
		electric.global_position
	) * 0.5

	print(
		"ELECTROCUTION TRIGGERED AT ",
		center
	)
