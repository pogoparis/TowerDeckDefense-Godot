extends Node
class_name ReactionManager

@onready var phenomenon_manager: PhenomenonManager = $"../PhenomenonManager"
@onready var enemy_manager: EnemyManager = $"../EnemyManager"
@onready var effects_container: Node2D = $"../World/EffectsContainer"

@export var lightning_flash_scene: PackedScene

var processed_pairs := {}

const MINI_SHOCK_DAMAGE_BASE := 8
const MINI_SHOCK_COOLDOWN_BASE := 1.0
const MINI_SHOCK_COOLDOWN_STUNNED := 2.0

var mini_shock_cooldowns := {}

func _process(delta):

	update_cooldowns(delta)

	check_electrocution()

	check_thunderstorm()

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

	var dmg: int = MINI_SHOCK_DAMAGE_BASE + RunBonuses.get_mini_shock_damage_bonus()

	# Si l'ennemi est déjà paralysé, le Shock est moins fréquent (cooldown doublé)
	var cooldown: float = MINI_SHOCK_COOLDOWN_STUNNED if enemy.has_status(StatusIds.STUNNED) \
		else MINI_SHOCK_COOLDOWN_BASE
	cooldown *= RunBonuses.get_mini_shock_cooldown_mult()

	enemy.take_damage(dmg, "tick")

	# SHOCK ! = réaction Mini Shock — passe par le throttle anti-surcharge.
	if enemy is EnemyBase:
		enemy.try_spawn_onomatopoeia("shock", 110.0)

	mini_shock_cooldowns[enemy.get_instance_id()] = cooldown


# =====================================================
# TERRAIN REACTIONS
# =====================================================

func check_electrocution():

	var phenomena: Array = phenomenon_manager.get_active_phenomena()

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


# =====================================================
# THUNDERSTORM — Electric Field + Wind Current
# =====================================================

const THUNDERSTORM_DAMAGE    := 60
const THUNDERSTORM_STUN      := 2.5
const THUNDERSTORM_STRIKES   := 5     # nombre d'éclairs aléatoires
const THUNDERSTORM_INTERVAL  := 0.3   # délai entre chaque éclair

func check_thunderstorm():
	var phenomena: Array = phenomenon_manager.get_active_phenomena()

	for electric in phenomena:
		if not is_instance_valid(electric):
			continue
		if electric.phenomenon_type != PhenomenonType.Type.ELECTRIC_FIELD:
			continue
		if electric.age < electric.min_reaction_age:
			continue

		for wind in phenomena:
			if not is_instance_valid(wind):
				continue
			if wind.phenomenon_type != PhenomenonType.Type.WIND_CURRENT:
				continue
			if wind.age < wind.min_reaction_age:
				continue

			var max_dist: float = electric.radius + wind.radius
			if electric.global_position.distance_to(wind.global_position) > max_dist:
				continue

			var pair_id := "thunder_" + str(electric.get_instance_id()) + "_" + str(wind.get_instance_id())
			if processed_pairs.has(pair_id):
				continue

			processed_pairs[pair_id] = true
			trigger_thunderstorm(electric, wind)


func trigger_thunderstorm(electric: Phenomenon, wind: Phenomenon):
	var center: Vector2 = (electric.global_position + wind.global_position) * 0.5
	var radius: float   = max(electric.radius, wind.radius)

	phenomenon_manager.remove_phenomenon(electric)
	phenomenon_manager.remove_phenomenon(wind)

	# Éclairs successifs avec délai
	for i in THUNDERSTORM_STRIKES:
		var delay := i * THUNDERSTORM_INTERVAL
		get_tree().create_timer(delay).timeout.connect(
			func(): _strike_thunderstorm(center, radius),
			CONNECT_ONE_SHOT
		)


func _strike_thunderstorm(center: Vector2, radius: float):
	var enemies: Array = enemy_manager.get_all_enemies()
	var hit: bool = false

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if center.distance_to(enemy.global_position) > radius:
			continue

		enemy.take_damage(THUNDERSTORM_DAMAGE, "silent")
		enemy.apply_slow(0.0, THUNDERSTORM_STUN)
		enemy.add_status(StatusIds.STUNNED, THUNDERSTORM_STUN)

		FloatingTextService.spawn(
			get_tree().current_scene,
			enemy.global_position + Vector2(randf_range(-20, 20), -60),
			"⚡ THUNDERSTORM !",
			Color(0.7, 0.9, 1.0),
			1.4
		)
		hit = true

	# Flash visuel même sans ennemi touché
	_spawn_lightning_flash(center)


func _spawn_lightning_flash(pos: Vector2):
	if lightning_flash_scene == null:
		return
	var fx := lightning_flash_scene.instantiate()
	effects_container.add_child(fx)
	fx.global_position = pos
	Audio.play_sfx(preload("res://assets/audio/sfx/lightning.wav"), -6.0, 0.1)
