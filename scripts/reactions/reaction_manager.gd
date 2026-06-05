extends Node
class_name ReactionManager

@onready var phenomenon_manager: PhenomenonManager = $"../PhenomenonManager"
@onready var enemy_manager: EnemyManager = $"../EnemyManager"
@onready var effects_container: Node2D = $"../World/EffectsContainer"

var processed_pairs := {}

const MINI_SHOCK_DAMAGE := 1
const MINI_SHOCK_COOLDOWN := 1.0

var mini_shock_cooldowns := {}

func _process(delta):

	update_cooldowns(delta)

	check_electrocution()

	check_contamination_reactions()


func update_cooldowns(delta):

	var expired := []

	for enemy_id in mini_shock_cooldowns.keys():

		mini_shock_cooldowns[enemy_id] -= delta

		if mini_shock_cooldowns[enemy_id] <= 0.0:
			expired.append(enemy_id)

	for enemy_id in expired:

		mini_shock_cooldowns.erase(enemy_id)

func check_contamination_reactions():

	for enemy in enemy_manager.get_all_enemies():

		if not is_instance_valid(enemy):
			continue

		check_wet_charged(enemy)

func check_wet_charged(enemy: EnemyBase):

	if not enemy.has_status(StatusIds.WET):
		return

	if not enemy.has_status(StatusIds.CHARGED):
		return

	var enemy_id := enemy.get_instance_id()

	if mini_shock_cooldowns.has(enemy_id):
		return

	trigger_mini_shock(enemy)

func trigger_mini_shock(enemy: EnemyBase):

	enemy.take_damage(MINI_SHOCK_DAMAGE)
	FloatingTextService.spawn(
		get_tree().current_scene,
		enemy.global_position + Vector2(0, -40),
		"⚡1",
		Color.YELLOW,
		1.2
	)
	enemy.remove_status(StatusIds.CHARGED)

	mini_shock_cooldowns[enemy.get_instance_id()] = MINI_SHOCK_COOLDOWN

# =====================================================
# TERRAIN REACTIONS
# =====================================================

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

			if water.age < water.min_reaction_age:
				continue

			if electric.age < electric.min_reaction_age:
				continue

			var max_distance: float = water.radius + electric.radius

			var distance_between: float = water.global_position.distance_to(
				electric.global_position
			)

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
