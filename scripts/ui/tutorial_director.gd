extends Node2D
class_name TutorialDirector
## Pilote le tutoriel scripté du niveau 1, 100 % dirigé.
##
## Séquence : pose Tesla (case imposée) → vague → pose Eau (case imposée) →
## vague → tanks + phénomène imposé dans l'angle → miniboss + 2 phénomènes.
##
## Le joueur ne peut faire QUE l'action demandée à chaque étape (cases et
## cartes verrouillées). Tout est réglable dans l'inspecteur.

# ── Configuration (réglable dans l'inspecteur) ───────────────
@export_group("Tours imposées")
## NB : Vector2i est indexé à partir de 0 (colonne 0 = tout à gauche, ligne 0 = tout en haut).
## Donc "colonne 4, ligne 3" en comptant à partir de 1 = Vector2i(3, 2).
@export var tesla_tower_id := "TowerTesla"
@export var water_tower_id := "TowerWaterCannon"
## Re-calées après le passage de la grille en 17x8 cases de 96 px : ces cases
## visent la même position à l'écran qu'avec l'ancienne grille 12x6 / 128 px.
@export var tesla_cell := Vector2i(5, 3)
@export var water_cell := Vector2i(3, 3)

@export_group("Zone des phénomènes")
## Case-cible (centre) où le joueur doit lâcher les phénomènes.
@export var phenomenon_cell := Vector2i(5, 2)
@export var phenomenon_radius := 150.0

@export_group("PV des ennemis")
## PV des petits ennemis de la vague 1 (la Tesla + arcs en chaîne les usent).
@export var wave1_mob_hp := 12
## PV des petits ennemis de la vague 2 (un poil plus que la vague 1).
@export var wave2_mob_hp := 35
## PV des tanks de la vague 3.
@export var tank_hp := 300
## PV du miniboss (vague 4) — assez haut pour qu'UN seul phénomène ne suffise
## pas : il faut l'ÉLECTROCUTION (flaque + champ superposés) pour le tuer.
@export var tutorial_boss_hp := 2000

@export_group("Confort")
## Caps offerts au début du tuto (en plus du reset) pour ne jamais bloquer.
@export var bonus_starting_caps := 8
## Intervalle de spawn des petites vagues (petit = mobs serrés → arcs en chaîne visibles).
@export var tuto_spawn_interval := 0.55

# ── Scènes d'ennemis (vagues construites en code) ────────────
const SIMPLE_MOB := preload("res://scenes/enemies/SimpleMob.tscn")
const TANK_MOB := preload("res://scenes/enemies/TankMob.tscn")
const MINI_BOSS := preload("res://scenes/enemies/MiniBoss.tscn")

# Cartes garanties à chaque étape (le tuto ne dépend pas du tirage).
const WATER_CARD := preload("res://resources/cards/water_cannon_card.tres")
const TESLA_CARD := preload("res://resources/cards/tesla_coil_card.tres")

# ── État ─────────────────────────────────────────────────────
var active := false
var _level: Node = null

# Verrouillage des actions (lu par le level avant build).
var _await_tower_id := ""

# Surlignages visuels.
var _highlight_cell_active := false
var _highlight_cell := Vector2i.ZERO
var _highlight_zone_active := false
var _highlight_zone_center := Vector2.ZERO
var _highlight_towers_active := false
var _pulse := 0.0


func _process(delta: float) -> void:
	if _highlight_cell_active or _highlight_zone_active or _highlight_towers_active:
		_pulse += delta
		queue_redraw()


# ── API lue par le level pour bloquer les actions interdites ─
func can_build_card(card_data) -> bool:
	if not active:
		return true
	return _await_tower_id != "" and card_data.tower_id == _await_tower_id


# ── Déroulé complet du tutoriel ──────────────────────────────
func run(level: Node) -> void:
	active = true
	_level = level
	z_index = 2

	# Tutoriel guidé : 1 SEUL PV (zéro fuite tolérée) + caps dosés pile poil
	# étape par étape → le joueur ne peut faire QUE ce qu'on lui demande.
	Player.invulnerable = false
	Player.set_base_hp(20)

	# Main de départ : 2 Tesla + 1 Eau (animée).
	if not is_inside_tree(): return
	_fill_tutorial_hand()
	await _level._deal_cards_animated()
	if not is_inside_tree(): return

	# ÉTAPE 1 — Tour Tesla imposée, puis vague de petits ennemis.
	_set_wave_hud(1, 4)
	Player.set_caps(2)   # pile de quoi poser la Tesla
	await _require_tower(
		tesla_tower_id, tesla_cell,
		"BIENVENUE !",
		"⚠️ Protège ton squat : chaque ennemi qui atteint la base te coûte des PV !\n\nPose ta première défense : l'OURS ÉCLAIR — ses ARCS ÉLECTRIQUES sautent d'ennemi en ennemi.\n\nGlisse la carte sur la case qui clignote.",
		"⚡ Glisse l'OURS ÉCLAIR sur la case surlignée"
	)
	if not is_inside_tree(): return
	_set_signature_charge_enabled(false)   # Charge verrouillée (pas de jauge) jusqu'à la vague 4
	await _run_simple_wave(4, 85.0, wave1_mob_hp, 1.1)   # intervalle large = ennemis bien espacés
	if not is_inside_tree(): return

	# ÉTAPE 2 — Tour Eau imposée, puis vague.
	_set_wave_hud(2, 4)
	_deal_tutorial_hand()   # remet 2 élec + 1 eau (remplace la Tesla posée)
	Player.set_caps(2)   # pile de quoi poser l'Eau
	await _require_tower(
		water_tower_id, water_cell,
		"AJOUTE UNE TOUR",
		"Pose le REQUIN juste à côté de l'Ours Éclair.\n\nIl inflige de GROS DÉGÂTS et RALENTIT légèrement les ennemis.\n\nRegarde l'effet combiné des deux tours : eau (WET) + électricité (CHARGED) créent des SHOCK qui infligent des dégâts supplémentaires aux mobs !",
		"💧 Glisse le REQUIN sur la case surlignée"
	)
	if not is_inside_tree(): return
	await _run_simple_wave(6, 130.0, wave2_mob_hp)
	if not is_inside_tree(): return

	# ÉTAPE 3 — Les blindés : on ENSEIGNE et on FORCE l'amélioration de tour.
	_set_wave_hud(3, 4)
	_deal_tutorial_hand()
	await _explain(
		"LES BLINDÉS ARRIVENT !",
		"Des blindés lourds approchent — tes tours de base ne suffiront pas.\n\nTu viens de récupérer de la FERRAILLE 🔧 : AMÉLIORE une de tes tours pour la renforcer (plus de dégâts, plus de portée)."
	)
	if not is_inside_tree(): return
	Player.add_caps(80)   # de quoi améliorer une tour
	await _require_upgrade("🔧 Tape une de tes tours → bouton AMÉLIORER")
	if not is_inside_tree(): return
	await _explain(
		"BIEN JOUÉ !",
		"Ta tour est renforcée. Maintenant, tiens la ligne face aux blindés !"
	)
	if not is_inside_tree(): return
	_level.wave_manager.wave_started = true
	_level.wave_manager.spawn_wave_data(_make_wave(TANK_MOB, 2, 4.0, 70.0, null, 90))
	await _wait_wave_clear()
	if not is_inside_tree(): return

	# ÉTAPE 4 — Miniboss : ENSEIGNE la CHARGE (déclencheur de la signature).
	_set_wave_hud(4, 4)
	_deal_tutorial_hand()
	await _explain(
		"LE MINIBOSS !",
		"Il encaisse énormément de tirs.\n\nTon OURS ÉCLAIR a accumulé de la CHARGE en combattant. Quand sa jauge est PLEINE (jaune, elle brille), tape la tour puis DÉCLENCHE une tempête électrique dévastatrice !"
	)
	if not is_inside_tree(): return
	# Ouvre la Charge (verrouillée depuis la vague 1) : la jauge APPARAÎT
	# maintenant et se remplit en tirant sur les mobs d'escorte du boss.
	_set_signature_charge_enabled(true)
	_level.wave_manager.wave_started = true
	# Escorte devant le boss → de quoi remplir la jauge avant qu'il arrive.
	_level.wave_manager.spawn_wave_data(_make_wave(SIMPLE_MOB, 4, 1.4, 120.0, MINI_BOSS))
	_weaken_boss(900)   # costaud : la Charge devient vraiment utile (pas de kill trivial)
	_set_banner("Ton OURS ÉCLAIR se charge en tirant… surveille sa jauge !")

	# Attend que la jauge soit PLEINE (remplie sur les mobs d'escorte).
	var charge_ready: bool = await _wait_signature_charge_ready()
	if not is_inside_tree(): return

	if charge_ready:
		_set_banner("")
		# UNE seule alerte : le modal met l'arbre en pause → le jeu est stoppé.
		await _explain(
			"JAUGE PLEINE !",
			"Ton OURS ÉCLAIR est chargé à bloc !\n\nFerme ce message, puis tape la tour et appuie sur DÉCLENCHER pour foudroyer le boss."
		)
		if not is_inside_tree(): return
		# Après le modal, le jeu RESTE gelé jusqu'au déclenchement du joueur.
		_freeze_gameplay(true)
		await _require_charge_trigger("Tape l'OURS ÉCLAIR puis DÉCLENCHER")
		# Déclenché → reprise du jeu : la tempête s'abat, le boss encaisse.
		_freeze_gameplay(false)
		if not is_inside_tree(): return

	await _wait_boss_dead()
	if not is_inside_tree(): return

	# VICTOIRE
	_clear_all_locks()
	_level.wave_manager._record_level_result()
	if _level.has_method("show_victory"):
		_level.show_victory()


# ── Étapes ───────────────────────────────────────────────────

## Affiche une explication en pause (réutilise le TutorialOverlay).
func _explain(title: String, body: String) -> void:
	if title == "":
		return
	await _level.tutorial_overlay.show_and_wait(title, body)


## Impose la pose d'une tour précise sur une case précise.
func _require_tower(tower_id: String, cell: Vector2i, title: String, body: String, banner: String) -> void:
	await _explain(title, body)
	if not is_inside_tree(): return

	_await_tower_id = tower_id
	_level.placement.forced_cell_active = true
	_level.placement.forced_cell = cell
	_highlight_cell_active = true
	_highlight_cell = cell
	_set_banner(banner)
	_highlight_card(tower_id)

	while is_inside_tree() and not _level.grid.is_cell_occupied(cell):
		await get_tree().process_frame

	_await_tower_id = ""
	_level.placement.forced_cell_active = false
	_highlight_cell_active = false
	_set_banner("")
	_clear_card_highlight()
	queue_redraw()


## Impose au joueur d'améliorer n'importe quelle tour (enseigne l'upgrade).
## Attend qu'au moins une tour posée atteigne le niveau d'amélioration 1.
func _require_upgrade(banner: String) -> void:
	_set_banner(banner)
	_highlight_towers_active = true
	while is_inside_tree() and not _all_towers_upgraded():
		await get_tree().process_frame
	_highlight_towers_active = false
	_set_banner("")
	queue_redraw()


## Vrai seulement quand TOUTES les tours posées ont été améliorées (niveau ≥ 1).
func _all_towers_upgraded() -> bool:
	var towers := get_tree().get_nodes_in_group("towers")
	var found := false
	for t in towers:
		if not is_instance_valid(t) or not ("upgrade_level" in t):
			continue
		found = true
		if t.upgrade_level < 1:
			return false
	return found


## Retourne la 1re tour signature posée (celle qui porte une Charge), ou null.
func _find_signature_tower() -> BaseTower:
	for t in get_tree().get_nodes_in_group("towers"):
		var bt := t as BaseTower
		if bt != null and bt.is_signature:
			return bt
	return null


## Active/désactive la Charge de la signature. Le tuto la garde VERROUILLÉE
## (pas de jauge, pas d'accumulation) jusqu'à la vague 4, où elle se remplira
## naturellement en tirant sur les mobs d'escorte du boss.
func _set_signature_charge_enabled(v: bool) -> void:
	var t := _find_signature_tower()
	if t == null:
		return
	t.charge_enabled = v
	if v:
		t.charge_current = 0
		t.charge_cooldown = 0.0
	t.queue_redraw()


## Vrai s'il reste un ennemi "boss" (gros PV) en jeu.
func _boss_present() -> bool:
	for e in _level.enemy_manager.get_all_enemies():
		if not is_instance_valid(e):
			continue
		var eb := e as EnemyBase
		if eb != null and eb.max_hp >= 200:
			return true
	return false


## Vrai si un ennemi "boss" est à moins de [param dist] de la case (test ponctuel).
func _boss_near(cell: Vector2i, dist: float) -> bool:
	var target: Vector2 = _level.grid.cell_to_world(cell)
	for e in _level.enemy_manager.get_all_enemies():
		if not is_instance_valid(e):
			continue
		var eb := e as EnemyBase
		if eb != null and eb.max_hp >= 200 \
				and eb.global_position.distance_to(target) <= dist:
			return true
	return false


## Demande au joueur de DÉCLENCHER la Charge de la signature.
## Se débloque au déclenchement (cooldown démarré) OU si le boss meurt entre
## temps (anti-soft-lock). Retourne true si le joueur a bien déclenché.
func _require_charge_trigger(banner: String) -> bool:
	_set_banner(banner)
	var t := _find_signature_tower()
	var triggered := false
	var boss_seen := false
	while is_inside_tree():
		if t == null or not is_instance_valid(t):
			t = _find_signature_tower()
		if t != null and is_instance_valid(t) and t.charge_cooldown > 0.0:
			triggered = true
			break
		# N'accepte "plus de boss" comme sortie QUE si le boss a déjà spawné
		# (sinon on sortirait avant même son arrivée).
		if _boss_present():
			boss_seen = true
		elif boss_seen:
			break   # boss apparu puis mort → anti-soft-lock
		await get_tree().process_frame
	_set_banner("")
	return triggered


## Attend que la jauge de la signature soit PLEINE (remplie en tirant).
## Retourne false si le boss est apparu puis mort avant (anti-soft-lock).
func _wait_signature_charge_ready() -> bool:
	var boss_seen := false
	while is_inside_tree():
		var t := _find_signature_tower()
		if t != null and is_instance_valid(t) and t.is_charge_ready():
			return true
		if _boss_present():
			boss_seen = true
		elif boss_seen:
			return false
		await get_tree().process_frame
	return false


## Noeuds de gameplay gardés en PAUSABLE (ils se figent avec la pause).
const _FREEZE_PAUSABLE := [
	"World", "EnemyManager", "WaveManager", "PhenomenonManager",
	"SynergyManager", "GridManager", "PlacementManager", "TowerManager", "CardManager"
]

## Gèle / dégèle le gameplay via une VRAIE pause de l'arbre, tout en gardant
## actifs l'input (level), l'UI (bouton DÉCLENCHER + bannière) et ce director,
## pour que le joueur puisse déclencher pile au bon moment.
func _freeze_gameplay(frozen: bool) -> void:
	if frozen:
		# Restent actifs pendant la pause :
		process_mode = Node.PROCESS_MODE_ALWAYS            # ce director (coroutine)
		_level.process_mode = Node.PROCESS_MODE_ALWAYS     # _input → tap sur la tour
		var ui := _level.get_node_or_null("UI")
		if ui:
			ui.process_mode = Node.PROCESS_MODE_ALWAYS     # bouton DÉCLENCHER + bannière
		# Contre le cascade ALWAYS : le gameplay lourd reste figé par la pause.
		for n in _FREEZE_PAUSABLE:
			var node := _level.get_node_or_null(n)
			if node:
				node.process_mode = Node.PROCESS_MODE_PAUSABLE
		get_tree().paused = true
	else:
		get_tree().paused = false
		process_mode = Node.PROCESS_MODE_INHERIT
		_level.process_mode = Node.PROCESS_MODE_INHERIT
		var ui := _level.get_node_or_null("UI")
		if ui:
			ui.process_mode = Node.PROCESS_MODE_INHERIT
		for n in _FREEZE_PAUSABLE:
			var node := _level.get_node_or_null(n)
			if node:
				node.process_mode = Node.PROCESS_MODE_INHERIT


# ── Vagues ───────────────────────────────────────────────────

func _run_simple_wave(count: int, speed: float, hp := 0, interval := -1.0) -> void:
	var itv: float = interval if interval > 0.0 else tuto_spawn_interval
	await _level.wave_manager.tutorial_spawn_and_wait(
		_make_wave(SIMPLE_MOB, count, itv, speed, null, hp)
	)


func _wait_wave_clear() -> void:
	var em = _level.enemy_manager
	while is_inside_tree() and em.get_all_enemies().size() > 0:
		await get_tree().process_frame


## Attend que le BOSS (gros PV) soit mort. Plus robuste que _wait_wave_clear
## pour la vague finale : un mob d'escorte bloqué ne doit pas figer la Victoire.
func _wait_boss_dead() -> void:
	# Attend que le boss soit APPARU puis mort (ne renvoie pas la victoire tant
	# que le boss n'a pas spawné, même si la liste d'ennemis est vide un instant).
	var boss_seen := false
	while is_inside_tree():
		if _boss_present():
			boss_seen = true
		elif boss_seen:
			return
		await get_tree().process_frame


## Attend que le miniboss (gros PV) soit à moins de [param dist] de la case.
func _wait_for_boss_near(cell: Vector2i, dist: float) -> void:
	var target: Vector2 = _level.grid.cell_to_world(cell)
	while is_inside_tree():
		for e in _level.enemy_manager.get_all_enemies():
			if is_instance_valid(e) and e.max_hp >= 200 \
					and e.global_position.distance_to(target) <= dist:
				return
		await get_tree().process_frame


## Met en surbrillance la carte à jouer (celle dont le tower_id correspond).
func _highlight_card(tower_id: String) -> void:
	for c in _level.tower_cards_container.get_children():
		if c is TowerCardUI and c.card_data != null:
			c.set_tutorial_highlight(c.card_data.tower_id == tower_id)


func _clear_card_highlight() -> void:
	for c in _level.tower_cards_container.get_children():
		if c is TowerCardUI:
			c.set_tutorial_highlight(false)


func _make_wave(scene: PackedScene, count: int, interval: float, speed: float, boss: PackedScene = null, hp := 0) -> WaveData:
	var w := WaveData.new()
	w.enemy_scene = scene
	w.enemy_count = count
	w.spawn_interval = interval
	w.enemy_speed = speed
	w.boss_scene = boss
	w.enemy_hp_override = hp
	return w


## Remplit la main avec 2 cartes Tesla + 1 Eau, dans un ordre aléatoire
## (impression de hasard). Données uniquement — n'actualise pas l'UI.
func _fill_tutorial_hand() -> void:
	var cm = _level.card_manager
	cm.hand.clear()
	cm.hand.append(TESLA_CARD)
	cm.hand.append(TESLA_CARD)
	cm.hand.append(WATER_CARD)
	cm.hand.shuffle()


## Redistribue la main tuto (2 élec + 1 eau) et rafraîchit l'affichage.
func _deal_tutorial_hand() -> void:
	_fill_tutorial_hand()
	_level.refresh_hand_ui(true)


## Réduit les PV du miniboss dès son apparition (tuto gagnable avec 2 tours).
func _weaken_boss(target_hp: int) -> void:
	var em = _level.enemy_manager
	for _i in range(900):
		if not is_inside_tree():
			return
		for e in em.get_all_enemies():
			if is_instance_valid(e) and e.max_hp >= 200:
				e.max_hp = target_hp
				e.hp = mini(e.hp, target_hp)
				e.update_hp_bar()
				return
		await get_tree().process_frame


# ── Helpers UI ───────────────────────────────────────────────

func _set_wave_hud(current: int, total: int) -> void:
	if _level.top_hud:
		_level.top_hud.set_wave(current, total)


func _set_banner(text: String) -> void:
	if _level and "tutorial_banner" in _level and _level.tutorial_banner:
		_level.tutorial_banner.text = text
		_level.tutorial_banner.visible = text != ""


func _clear_all_locks() -> void:
	_await_tower_id = ""
	_highlight_cell_active = false
	_highlight_zone_active = false
	_highlight_towers_active = false
	if _level:
		_level.placement.forced_cell_active = false
	_set_banner("")
	queue_redraw()


# ── Surlignage visuel ────────────────────────────────────────

func _draw() -> void:
	var a := 0.45 + 0.30 * sin(_pulse * 4.5)

	if _highlight_cell_active and _level:
		var c: Vector2 = _level.grid.cell_to_world(_highlight_cell)
		var s := float(GridManager.CELL_SIZE)
		var rect := Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s))
		draw_rect(rect, Color(1.0, 0.9, 0.2, a * 0.25), true)
		draw_rect(rect, Color(1.0, 0.9, 0.2, a), false, 6.0)

	if _highlight_zone_active:
		draw_circle(_highlight_zone_center, phenomenon_radius, Color(0.3, 0.7, 1.0, a * 0.25))
		draw_arc(_highlight_zone_center, phenomenon_radius, 0.0, TAU, 56, Color(0.4, 0.9, 1.0, a), 6.0)

	# Surbrillance des tours posées PAS ENCORE améliorées (étape « améliore »).
	if _highlight_towers_active:
		for t in get_tree().get_nodes_in_group("towers"):
			if not is_instance_valid(t):
				continue
			if "upgrade_level" in t and t.upgrade_level >= 1:
				continue  # déjà améliorée → plus de halo
			var p: Vector2 = t.global_position - Vector2(0, 20)
			var r := 72.0
			draw_circle(p, r, Color(1.0, 0.85, 0.2, a * 0.18))
			draw_arc(p, r, 0.0, TAU, 48, Color(1.0, 0.9, 0.25, a), 6.0)
