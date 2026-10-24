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

	# Cooldowns des réactions à effet (Cryogénisation, Tempête de Sable).
	for dict in [_cryo_cooldowns, _sandstorm_cooldowns, _spores_cooldowns]:
		var done := []
		for id in dict.keys():
			dict[id] -= delta
			if dict[id] <= 0.0:
				done.append(id)
		for id in done:
			dict.erase(id)


func check_contamination_reactions():

	for enemy in enemy_manager.get_all_enemies():

		if not is_instance_valid(enemy):
			continue

		check_wet_charged(enemy)

		# Réactions à effet : elles ont leur propre fonction parce qu'elles
		# changent l'ÉTAT de l'ennemi, pas seulement ses PV.
		check_vapeur(enemy)
		check_surchauffe(enemy)
		check_attise(enemy)
		check_decharge(enemy)
		check_eclaboussure(enemy)
		check_cryogenisation(enemy)
		check_sandstorm(enemy)
		check_spores(enemy)

		# ── Complément de la matrice CONTRÔLE × DÉGÂTS ────────────────
		# La règle du jeu tient en une phrase : « un élément de contrôle plus
		# un élément de dégâts font une réaction ». Elle n'était vraie qu'à
		# moitié — la Glace n'en avait aucune, donc le Pingouin ralentissait
		# sans que rien n'exploite ce ralentissement.
		check_boue(enemy)
		check_infusion(enemy)
		check_choc_thermique(enemy)
		check_supraconducteur(enemy)
		check_brisure(enemy)
		check_gangrene(enemy)


## Autorise une réaction NOMMÉE sur cet ennemi, avec son propre cooldown.
##
## Toutes les réactions à effet suivent le même patron — vérifier deux statuts,
## respecter un cooldown, afficher un texte. Ce helper évite d'en recopier la
## mécanique à chaque nouvelle réaction : il ne reste plus que l'EFFET à écrire,
## ce qui rend l'ajout d'une réaction quasi gratuit.
func _try_react(
	enemy: EnemyBase, a: String, b: String, id: String,
	label: String, color: Color, cooldown: float
) -> bool:
	if not (enemy.has_status(a) and enemy.has_status(b)):
		return false

	var key := str(enemy.get_instance_id(), "_", id)
	if _contam_cooldowns.has(key):
		return false
	_contam_cooldowns[key] = cooldown

	FloatingTextService.spawn(
		get_tree().current_scene,
		enemy.global_position + Vector2(randf_range(-12, 12), -50),
		label, color, 1.2
	)
	return true


# ══════════════════════════════════════════════════════
#   LES CINQ PLUS ANCIENNES, REFONDUES
# ══════════════════════════════════════════════════════
#
# Elles faisaient toutes la même chose : 6 à 8 dégâts et un texte flottant.
# Une réaction qui fait « encore des dégâts » n'apprend RIEN sur les deux
# éléments qui l'ont produite — et à côté des six nouvelles, qui ont chacune un
# effet propre, elles passaient pour du bruit. Chacune a maintenant une
# identité mécanique.

# ── VAPEUR — 💧 Eau + 🔥 Feu ───────────────────────────────
# L'eau qui bout AVEUGLE : le nuage brûle sur la durée et se voit de loin.
# C'est du dégât ÉTALÉ, à l'opposé du Choc Thermique qui est un burst.
func check_vapeur(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.WET, StatusIds.BURNING, "vapeur",
			"VAPEUR !", Color(0.85, 0.92, 0.98), 4.0):
		return
	enemy.take_damage(12, "tick", ElementType.Type.FIRE)
	enemy.extend_status(StatusIds.BURNING, 6.0)
	# L'eau s'évapore : c'est ce qui empêche la boucle infinie Eau↔Feu.
	enemy.remove_status(StatusIds.WET)


# ── SURCHAUFFE — 🔥 Feu + ⚡ Électricité ───────────────────
# Deux éléments de DÉGÂTS ensemble : le seul cas où la réaction fait
# simplement très mal. Elle EXPLOSE en zone — c'est la récompense du joueur
# qui a tout misé sur l'offensive et n'a aucun contrôle.
const SURCHAUFFE_RADIUS := 120.0

func check_surchauffe(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.BURNING, StatusIds.CHARGED, "surchauffe",
			"SURCHAUFFE !", Color(1.0, 0.4, 1.0), 5.0):
		return
	for e in _enemies_in_radius(enemy.global_position, SURCHAUFFE_RADIUS):
		e.take_damage(26 if e == enemy else 14, "tick", ElementType.Type.FIRE)
	Juice.shake(9.0, 0.18)


# ── ATTISÉ — 🌪 Air + 🔥 Feu ───────────────────────────────
# Le vent PROPAGE l'incendie : les voisins prennent feu. Le pendant "foule" du
# Choc Thermique, qui lui est mono-cible.
const ATTISE_RADIUS := 140.0

func check_attise(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.WINDMARK, StatusIds.BURNING, "attise",
			"ATTISÉ !", Color(1.0, 0.55, 0.1), 5.0):
		return
	enemy.take_damage(10, "tick", ElementType.Type.FIRE)
	for e in _enemies_in_radius(enemy.global_position, ATTISE_RADIUS):
		if e != enemy:
			e.add_status(StatusIds.BURNING, 4.0)
	enemy.remove_status(StatusIds.WINDMARK)


# ── DÉCHARGE — 🌪 Air + ⚡ Électricité ─────────────────────
# L'air ionisé conduit : la décharge REJETTE l'ennemi en arrière sur le chemin.
# Elle achète de la distance, pas des dégâts — c'est le rôle de l'Air.
func check_decharge(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.WINDMARK, StatusIds.CHARGED, "decharge",
			"DÉCHARGE !", Color(0.5, 0.8, 1.0), 5.0):
		return
	enemy.take_damage(14, "tick", ElementType.Type.ELECTRIC)
	enemy.apply_knockback(90.0)
	enemy.add_status(StatusIds.STUNNED, 1.0)
	enemy.apply_slow(0.0, 1.0)


# ── ÉCLABOUSSURE — 💧 Eau + 🌪 Air ─────────────────────────
# La bourrasque disperse l'eau : elle TREMPE tous les voisins. Aucun dégât —
# c'est un multiplicateur d'installation, qui prépare Vapeur ou Électrocution
# sur un groupe entier.
const ECLABOUSSURE_RADIUS := 150.0

func check_eclaboussure(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.WET, StatusIds.WINDMARK, "eclaboussure",
			"ÉCLABOUSSURE !", Color(0.6, 0.85, 1.0), 5.0):
		return
	for e in _enemies_in_radius(enemy.global_position, ECLABOUSSURE_RADIUS):
		if e != enemy:
			e.add_status(StatusIds.WET, 5.0)
	enemy.remove_status(StatusIds.WINDMARK)


# ══════════════════════════════════════════════════════
#   MATRICE CONTRÔLE × DÉGÂTS — les six réactions manquantes
# ══════════════════════════════════════════════════════
#
# Chacune a un EFFET distinct, jamais « encore des dégâts » : une réaction doit
# apprendre quelque chose au joueur sur les deux éléments qui l'ont produite.

# ── BOUE — 💧 Eau + 🪨 Terre ───────────────────────────────
# La terre détrempée devient un bourbier : le sol lui-même ralentit.
func check_boue(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.WET, StatusIds.DUSTY, "boue",
			"BOUE !", Color(0.62, 0.5, 0.32), 5.0):
		return
	enemy.apply_slow(0.35, 4.0)
	enemy.take_damage(6, "tick", ElementType.Type.EARTH)


# ── INFUSION — 💧 Eau + 🌿 Nature ──────────────────────────
# L'eau dilue le poison dans l'organisme : le DoT du Panda fait mal d'un coup.
# Frappe en % des PV max, donc c'est LA réponse aux très gros ennemis.
func check_infusion(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.WET, StatusIds.POISONED, "infusion",
			"INFUSION !", Color(0.5, 0.9, 0.55), 5.0):
		return
	enemy.take_damage(int(round(enemy.max_hp * 0.08)), "tick", ElementType.Type.NATURE)


# ── CHOC THERMIQUE — ❄ Glace + 🔥 Feu ──────────────────────
# Le chaud sur le gelé fait éclater : gros burst, mais le givre est consommé.
# C'est un arbitrage — on échange son ralentissement contre des dégâts.
func check_choc_thermique(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.CHILLED, StatusIds.BURNING, "choc",
			"CHOC THERMIQUE !", Color(1.0, 0.7, 0.85), 6.0):
		return
	enemy.take_damage(45 + int(enemy.max_hp * 0.06), "silent", ElementType.Type.FIRE)
	enemy.chill_multiplier = 1.0
	enemy.chill_timer = 0.0
	enemy.remove_status(StatusIds.CHILLED)
	Juice.shake(8.0, 0.18)


# ── SUPRACONDUCTEUR — ❄ Glace + ⚡ Électricité ─────────────
# Le froid abaisse la résistance : la décharge se propage à tous les GELÉS
# alentour. Récompense d'avoir gelé un groupe entier avant de le foudroyer.
const SUPRA_RADIUS := 170.0

func check_supraconducteur(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.CHILLED, StatusIds.CHARGED, "supra",
			"SUPRACONDUCTEUR !", Color(0.6, 0.95, 1.0), 6.0):
		return
	enemy.take_damage(30, "silent", ElementType.Type.ELECTRIC)
	for e in _enemies_in_radius(enemy.global_position, SUPRA_RADIUS):
		if e == enemy or not e.has_status(StatusIds.CHILLED):
			continue
		e.take_damage(22, "tick", ElementType.Type.ELECTRIC)
		e.add_status(StatusIds.CHARGED, 3.0)


# ── BRISURE — ❄ Glace + 🪨 Terre ───────────────────────────
# Le givre rend cassant, le rocher brise. Les dégâts montent avec la PROFONDEUR
# du gel : geler longtemps avant de frapper est récompensé.
func check_brisure(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.CHILLED, StatusIds.DUSTY, "brisure",
			"BRISURE !", Color(0.8, 0.92, 1.0), 6.0):
		return
	var depth: float = 1.0 - enemy.chill_multiplier     # 0 → 0.6 au plancher
	enemy.take_damage(35 + int(90.0 * depth), "silent", ElementType.Type.EARTH)
	enemy.chill_multiplier = 1.0
	enemy.chill_timer = 0.0
	enemy.remove_status(StatusIds.CHILLED)
	Juice.shake(11.0, 0.22)


# ── GANGRÈNE — ❄ Glace + 🌿 Nature ─────────────────────────
# Le froid ralentit le métabolisme : le poison s'installe pour bien plus
# longtemps. Pas de dégâts immédiats — c'est de la DURÉE qu'on achète.
func check_gangrene(enemy: EnemyBase) -> void:
	if not _try_react(enemy, StatusIds.CHILLED, StatusIds.POISONED, "gangrene",
			"GANGRÈNE !", Color(0.45, 0.75, 0.5), 8.0):
		return
	enemy.extend_status(StatusIds.POISONED, 12.0)


# ── CRYOGÉNISATION — 💧 Eau + ❄ Glace ─────────────────────
# L'eau sur un corps déjà givré prend en masse : l'ennemi se fige NET.
# C'est la réponse du deck Roche aux ennemis rapides — plutôt que des dégâts,
# elle achète du temps, ce qui vaut bien plus contre un Drone à 195 px/s.
const CRYO_COOLDOWN := 6.0
const CRYO_FREEZE_DURATION := 2.0
const CRYO_DAMAGE := 14

var _cryo_cooldowns := {}


func check_cryogenisation(enemy: EnemyBase) -> void:
	if not (enemy.has_status(StatusIds.WET) and enemy.has_status(StatusIds.CHILLED)):
		return

	var id := enemy.get_instance_id()
	if _cryo_cooldowns.has(id):
		return
	_cryo_cooldowns[id] = CRYO_COOLDOWN

	# Arrêt complet, pas un simple ralentissement : c'est ce qui rend la
	# réaction spectaculaire et lisible sans lire un chiffre.
	enemy.take_damage(CRYO_DAMAGE, "silent", ElementType.Type.ICE)
	enemy.apply_slow(0.0, CRYO_FREEZE_DURATION)
	enemy.add_status(StatusIds.STUNNED, CRYO_FREEZE_DURATION)
	# La glace consomme l'humidité : sans ça la réaction se relancerait en
	# boucle sur le même ennemi et le figerait en permanence.
	enemy.remove_status(StatusIds.WET)

	FloatingTextService.spawn(
		get_tree().current_scene,
		enemy.global_position + Vector2(randf_range(-12, 12), -50),
		"CRYOGÉNISATION !", Color(0.65, 0.95, 1.0), 1.25
	)
	Juice.shake(7.0, 0.15)


# ── TEMPÊTE DE SABLE — 🪨 Terre + 🌪 Air ───────────────────
# La bourrasque soulève la poussière de roche : ça mord sur une ZONE, pas sur
# une cible. Le pendant "dégâts de masse" de la Cryogénisation, pour un deck
# Roche qui manquait de réponse aux nuées.
const SANDSTORM_COOLDOWN := 5.0
const SANDSTORM_RADIUS := 130.0
const SANDSTORM_DAMAGE := 16
const SANDSTORM_SLOW := 0.6
const SANDSTORM_SLOW_TIME := 2.5

var _sandstorm_cooldowns := {}


func check_sandstorm(enemy: EnemyBase) -> void:
	if not (enemy.has_status(StatusIds.DUSTY) and enemy.has_status(StatusIds.WINDMARK)):
		return

	var id := enemy.get_instance_id()
	if _sandstorm_cooldowns.has(id):
		return
	_sandstorm_cooldowns[id] = SANDSTORM_COOLDOWN

	for e in _enemies_in_radius(enemy.global_position, SANDSTORM_RADIUS):
		e.take_damage(SANDSTORM_DAMAGE, "tick", ElementType.Type.EARTH)
		if e.slow_multiplier > SANDSTORM_SLOW:
			e.apply_slow(SANDSTORM_SLOW, SANDSTORM_SLOW_TIME)

	enemy.remove_status(StatusIds.DUSTY)

	FloatingTextService.spawn(
		get_tree().current_scene,
		enemy.global_position + Vector2(randf_range(-12, 12), -50),
		"TEMPÊTE DE SABLE !", Color(0.88, 0.75, 0.45), 1.25
	)
	Juice.shake(9.0, 0.2)


# ── SPORES — 🌿 Nature + 🌪 Air ────────────────────────────
# La bourrasque emporte les spores : le poison se PROPAGE aux voisins.
# Le Panda seul ne peut empoisonner qu'une cible à la fois (son ciblage évite
# même les cibles déjà infectées) ; avec du vent, il contamine un groupe.
# C'est ce qui le fait passer de tueur de gros à menace de zone.
const SPORES_COOLDOWN := 4.0
const SPORES_RADIUS := 150.0
const SPORES_DURATION := 4.0

var _spores_cooldowns := {}


func check_spores(enemy: EnemyBase) -> void:
	if not (enemy.has_status(StatusIds.POISONED) and enemy.has_status(StatusIds.WINDMARK)):
		return

	var id := enemy.get_instance_id()
	if _spores_cooldowns.has(id):
		return
	_spores_cooldowns[id] = SPORES_COOLDOWN

	var spread := 0
	for e in _enemies_in_radius(enemy.global_position, SPORES_RADIUS):
		if e == enemy or e.has_status(StatusIds.POISONED):
			continue
		e.add_status(StatusIds.POISONED, SPORES_DURATION)
		spread += 1

	# La marque de vent est consommée : sans ça, un seul ennemi venté au milieu
	# d'une nuée relancerait la propagation à chaque cooldown, et le poison
	# deviendrait permanent sur toute la vague sans effort.
	enemy.remove_status(StatusIds.WINDMARK)

	if spread > 0:
		FloatingTextService.spawn(
			get_tree().current_scene,
			enemy.global_position + Vector2(randf_range(-12, 12), -50),
			"SPORES ! ×%d" % spread, Color(0.6, 1.0, 0.4), 1.2
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
