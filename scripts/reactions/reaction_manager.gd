extends Node
class_name ReactionManager

@onready var phenomenon_manager: PhenomenonManager = $"../PhenomenonManager"
@onready var enemy_manager: EnemyManager = $"../EnemyManager"

var processed_pairs := {}

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

			var max_distance: float = water.radius + electric.radius

			var distance_between: float = water.global_position.distance_to(
				electric.global_position
			)
			if water.age < water.min_reaction_age:
				continue

			if electric.age < electric.min_reaction_age:
				continue
			if distance_between > max_distance:
				continue

			var pair_id := str(
				water.get_instance_id(),
				"_",
				electric.get_instance_id()
			)

			if processed_pairs.has(pair_id):
				continue

			processed_pairs[pair_id] = true

			trigger_electrocution(
				water,
				electric
			)


func trigger_electrocution(
	water: Phenomenon,
	electric: Phenomenon
):

	var effect := ElectrocutionZone.new()

	effect.global_position = (
		water.global_position +
		electric.global_position
	) * 0.5

	effect.enemy_manager = enemy_manager

	get_parent().add_child(effect)

	phenomenon_manager.remove_phenomenon(water)
	phenomenon_manager.remove_phenomenon(electric)
