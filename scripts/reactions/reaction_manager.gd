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

# Réactions auto entre statuts (mix d'éléments posés en tours).
# Volontairement FAIBLES : un coup de pouce qui récompense le mix, PAS un
# remplaçant des phénomènes (qui restent les gros plays du CONSUME).
const CONTAM_COOLDOWN := 1.6
var _contam_cooldowns := {}

func _process(delta):

	update_cooldowns(delta)

	check_electrocution()

	check_thunderstorm()

	# Nouvelles réactions de superposition de phénomènes (matrice complète)
	_check_pair_reaction(PhenomenonType.Type.WATER_POOL, PhenomenonType.Type.FIRE_ZONE, _trigger_vapeur)
	_check_pair_reaction(PhenomenonType.Type.FIRE_ZONE, PhenomenonType.Type.WIND_CURRENT, _trigger_tornade)
	_check_pair_reaction(PhenomenonType.Type.WATER_POOL, PhenomenonType.Type.WIND_CURRENT, _trigger_tempete)
	_check_pair_reaction(PhenomenonType.Type.ELECTRIC_FIELD, PhenomenonType.Type.FIRE_ZONE, _trigger_surcharge)

	check_contamination_reactions()


func update_cooldowns(delta):

	var expired := []

	for enemy_id in mini_shock_cooldowns.keys():

		mini_shock_cooldowns[enemy_id] -= delta

		if mini_shock_cooldowns[enemy_id] <= 0.0:
			expired.append(enemy_id)

	for enemy_id in expired:

		mini_shock_cooldowns.erase(enemy_id)

	# Cooldowns des réactions de contamination (couples de statuts)
	var contam_expired := []
	for key in _contam_cooldowns.keys():
		_contam_cooldowns[key] -= delta
		if _contam_cooldowns[key] <= 0.0:
			contam_expired.append(key)
	for key in contam_expired:
		_contam_cooldowns.erase(key)


func check_contamination_reactions():

	for enemy in enemy_manager.get_all_enemies():

		if not is_instance_valid(enemy):
			continue

		check_wet_charged(enemy)

		# Synergies passives entre éléments posés en tours (couples de statuts).
		_check_contam(enemy, StatusIds.WET, StatusIds.BURNING, 8, "VAPEUR", Color(0.85, 0.92, 0.98))
		_check_contam(enemy, StatusIds.BURNING, StatusIds.CHARGED, 8, "SURCHAUFFE", Color(1.0, 0.4, 1.0))
		_check_contam(enemy, StatusIds.WINDMARK, StatusIds.BURNING, 7, "ATTISÉ", Color(1.0, 0.55, 0.1))
		_check_contam(enemy, StatusIds.WINDMARK, StatusIds.CHARGED, 7, "DÉCHARGE", Color(0.5, 0.8, 1.0))
		_check_contam(enemy, StatusIds.WET, StatusIds.WINDMARK, 6, "ÉCLABOUSSURE", Color(0.6, 0.85, 1.0))


## Réaction auto quand un ennemi porte deux statuts élémentaires (mix de tours).
func _check_contam(enemy: EnemyBase, a: String, b: String, dmg: int, label: String, color: Color) -> void:
	if not (enemy.has_status(a) and enemy.has_status(b)):
		return
	var key := str(enemy.get_instance_id(), "_", a, b)
	if _contam_cooldowns.has(key):
		return
	_contam_cooldowns[key] = CONTAM_COOLDOWN
	enemy.take_damage(dmg, "tick")
	FloatingTextService.spawn(
		get_tree().current_scene,
		enemy.global_position + Vector2(randf_range(-12, 12), -45),
		label, color, 1.0
	)


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


# =====================================================
# RÉACTIONS DE SUPERPOSITION (matrice complète)
# Détecteur générique : deux phénomènes de types donnés qui se chevauchent
# déclenchent la réaction (une seule fois), puis sont consommés.
# =====================================================

func _check_pair_reaction(type_a: int, type_b: int, trigger: Callable) -> void:
	var phenomena: Array = phenomenon_manager.get_active_phenomena()
	for a in phenomena:
		if not is_instance_valid(a) or a.phenomenon_type != type_a:
			continue
		if a.age < a.min_reaction_age:
			continue
		for b in phenomena:
			if not is_instance_valid(b) or b == a or b.phenomenon_type != type_b:
				continue
			if b.age < b.min_reaction_age:
				continue
			if a.global_position.distance_to(b.global_position) > a.radius + b.radius:
				continue
			var pair_id := str(a.get_instance_id(), "_", b.get_instance_id())
			if processed_pairs.has(pair_id):
				continue
			processed_pairs[pair_id] = true
			trigger.call(a, b)


## Ennemis dans un cercle (centre + rayon).
func _enemies_in_radius(center: Vector2, radius: float) -> Array:
	var result: Array = []
	for e in enemy_manager.get_all_enemies():
		if is_instance_valid(e) and e.global_position.distance_to(center) <= radius:
			result.append(e)
	return result


## Texte flottant + consomme les deux phénomènes (fin de réaction).
func _finish_reaction(a, b, center: Vector2, label: String, color: Color) -> void:
	FloatingTextService.spawn(get_tree().current_scene, center + Vector2(0, -40), label, color, 1.5)
	Juice.shake(14.0, 0.3)
	phenomenon_manager.remove_phenomenon(a)
	phenomenon_manager.remove_phenomenon(b)


# ── VAPEUR : Flaque d'Eau + Zone de Feu ──────────────
# Choc thermique : burst modéré + gros ralentissement, nettoie le feu.
func _trigger_vapeur(a, b) -> void:
	var center: Vector2 = (a.global_position + b.global_position) * 0.5
	var radius: float = maxf(a.radius, b.radius) + 40.0
	for e in _enemies_in_radius(center, radius):
		# Choc thermique : burst fixe + % des PV max (efficace même sur les tanks)
		e.take_damage(80 + int(e.max_hp * 0.15), "silent")
		e.apply_slow(0.2, 5.0)   # ralentissement fort et long → tes tours finissent le travail
		e.remove_status(StatusIds.BURNING)
	_finish_reaction(a, b, center, "VAPEUR !", Color(0.85, 0.92, 0.98))


# ── TORNADE DE FEU : Zone de Feu + Bourrasque ────────
# Gros vortex : applique BURNING long + burst sur large zone.
func _trigger_tornade(a, b) -> void:
	var center: Vector2 = (a.global_position + b.global_position) * 0.5
	var radius: float = a.radius + b.radius
	for e in _enemies_in_radius(center, radius):
		e.take_damage(60 + int(e.max_hp * 0.12), "silent")
		e.add_status(StatusIds.BURNING, 5.0)
	_finish_reaction(a, b, center, "TORNADE DE FEU !", Color(1.0, 0.5, 0.1))


# ── TEMPÊTE : Flaque d'Eau + Bourrasque ──────────────
# Applique WET en masse + repousse (prépare l'électrocution).
func _trigger_tempete(a, b) -> void:
	var center: Vector2 = (a.global_position + b.global_position) * 0.5
	var radius: float = a.radius + b.radius
	for e in _enemies_in_radius(center, radius):
		e.take_damage(20, "silent")
		e.add_status(StatusIds.WET, 4.0)
		if e.has_method("apply_knockback"):
			e.apply_knockback(40.0)
	_finish_reaction(a, b, center, "TEMPÊTE !", Color(0.4, 0.8, 1.0))


# ── SURCHARGE : Champ Électrique + Zone de Feu ───────
# Explosion plasma : gros burst + stun.
func _trigger_surcharge(a, b) -> void:
	var center: Vector2 = (a.global_position + b.global_position) * 0.5
	var radius: float = maxf(a.radius, b.radius) + 30.0
	var stun: float = 2.0 + RunBonuses.get_stun_duration_bonus()
	for e in _enemies_in_radius(center, radius):
		e.take_damage(120 + int(e.max_hp * 0.15), "silent")
		e.apply_slow(0.0, stun)
		e.add_status(StatusIds.STUNNED, stun)
	_finish_reaction(a, b, center, "SURCHARGE !", Color(1.0, 0.3, 1.0))
