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
@export var tesla_cell := Vector2i(3, 2)
@export var water_cell := Vector2i(2, 2)

@export_group("Zone des phénomènes")
## Case-cible (centre) où le joueur doit lâcher les phénomènes.
@export var phenomenon_cell := Vector2i(3, 1)
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

# Verrouillage des actions (lu par le level avant build/consume).
var _await_tower_id := ""
var _await_consume_tower_id := ""

# Surlignages visuels.
var _highlight_cell_active := false
var _highlight_cell := Vector2i.ZERO
var _highlight_zone_active := false
var _highlight_zone_center := Vector2.ZERO
var _pulse := 0.0


func _process(delta: float) -> void:
	if _highlight_cell_active or _highlight_zone_active:
		_pulse += delta
		queue_redraw()


# ── API lue par le level pour bloquer les actions interdites ─
func can_build_card(card_data) -> bool:
	if not active:
		return true
	return _await_tower_id != "" and card_data.tower_id == _await_tower_id


func can_consume_card(card_data) -> bool:
	if not active:
		return true
	return _await_consume_tower_id != "" and card_data.tower_id == _await_consume_tower_id


# ── Déroulé complet du tutoriel ──────────────────────────────
func run(level: Node) -> void:
	active = true
	_level = level
	z_index = 2

	# Tutoriel guidé : 1 SEUL PV (zéro fuite tolérée) + caps dosés pile poil
	# étape par étape → le joueur ne peut faire QUE ce qu'on lui demande.
	Player.invulnerable = false
	Player.set_base_hp(1)

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
		"⚠️ Ton squat n'a qu'UN SEUL PV : si un ennemi atteint la base, c'est PERDU !\n\nPose ta première défense : l'OURS ÉCLAIR — ses ARCS ÉLECTRIQUES sautent d'ennemi en ennemi.\n\nGlisse la carte sur la case qui clignote.",
		"⚡ Glisse l'OURS ÉCLAIR sur la case surlignée"
	)
	if not is_inside_tree(): return
	await _run_simple_wave(4, 85.0, wave1_mob_hp)
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

	# ÉTAPE 3 — Tanks : un phénomène imposé dans l'angle.
	_set_wave_hud(3, 4)
	_deal_tutorial_hand()   # 2 élec + 1 eau
	await _explain(
		"LES TANKS ARRIVENT !",
		"Tes tours seules ne suffiront pas.\n\nLâche un CHAMP ÉLECTRIQUE dans l'angle, à portée de tes deux tours : ça les détruira tous !"
	)
	if not is_inside_tree(): return
	_level.wave_manager.wave_started = true
	_level.wave_manager.spawn_wave_data(_make_wave(TANK_MOB, 3, 4.0, 80.0, null, tank_hp))
	Player.set_caps(2)   # pile de quoi consommer un phénomène
	await _require_consume(
		tesla_tower_id, phenomenon_cell,
		"",
		"",
		"⚡ Tape la carte OURS ÉCLAIR → CONSOMMER → clique dans la zone surlignée"
	)
	if not is_inside_tree(): return
	await _wait_wave_clear()
	if not is_inside_tree(): return

	# ÉTAPE 4 — Miniboss : deux phénomènes superposés (électrocution).
	_set_wave_hud(4, 4)
	_deal_tutorial_hand()   # 2 élec + 1 eau
	await _explain(
		"LE MINIBOSS !",
		"Il encaisse les tirs. SUPERPOSE une FLAQUE D'EAU et un CHAMP ÉLECTRIQUE au même endroit quand il approche de tes tours → ÉLECTROCUTION !"
	)
	if not is_inside_tree(): return
	_level.wave_manager.wave_started = true
	_level.wave_manager.spawn_wave_data(_make_wave(SIMPLE_MOB, 2, 2.0, 120.0, MINI_BOSS))
	_weaken_boss(tutorial_boss_hp)  # détaché : réduit les PV du boss à son arrivée
	Player.set_caps(4)   # pile de quoi superposer flaque + champ → électrocution

	# N'affiche la consigne/zone QUE quand le miniboss approche de la zone.
	await _wait_for_boss_near(phenomenon_cell, phenomenon_radius + 80.0)
	if not is_inside_tree(): return

	await _require_consume(
		water_tower_id, phenomenon_cell,
		"",
		"",
		"🌊 1/2 — Lâche la FLAQUE D'EAU près de tes tours"
	)
	if not is_inside_tree(): return
	await _require_consume(
		tesla_tower_id, phenomenon_cell,
		"",
		"",
		"⚡ 2/2 — Lâche le CHAMP ÉLECTRIQUE au MÊME endroit !"
	)
	if not is_inside_tree(): return
	await _wait_wave_clear()
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


## Impose la consommation d'une carte précise dans une zone précise.
func _require_consume(tower_id: String, cell: Vector2i, title: String, body: String, banner: String) -> void:
	await _explain(title, body)
	if not is_inside_tree(): return

	var center: Vector2 = _level.grid.cell_to_world(cell)
	_await_consume_tower_id = tower_id
	_level.card_manager.forced_consume_active = true
	_level.card_manager.forced_consume_center = center
	_level.card_manager.forced_consume_radius = phenomenon_radius
	_highlight_zone_active = true
	_highlight_zone_center = center
	_set_banner(banner)
	_highlight_card(tower_id)

	var done := [false]
	var cb := func(_c, _p): done[0] = true
	_level.card_manager.consume_resolved.connect(cb)

	while is_inside_tree() and not done[0]:
		await get_tree().process_frame

	if _level.card_manager.consume_resolved.is_connected(cb):
		_level.card_manager.consume_resolved.disconnect(cb)

	_await_consume_tower_id = ""
	_level.card_manager.forced_consume_active = false
	_highlight_zone_active = false
	_set_banner("")
	_clear_card_highlight()
	queue_redraw()


# ── Vagues ───────────────────────────────────────────────────

func _run_simple_wave(count: int, speed: float, hp := 0) -> void:
	await _level.wave_manager.tutorial_spawn_and_wait(
		_make_wave(SIMPLE_MOB, count, tuto_spawn_interval, speed, null, hp)
	)


func _wait_wave_clear() -> void:
	var em = _level.enemy_manager
	while is_inside_tree() and em.get_all_enemies().size() > 0:
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
	_await_consume_tower_id = ""
	_highlight_cell_active = false
	_highlight_zone_active = false
	if _level:
		_level.placement.forced_cell_active = false
		_level.card_manager.forced_consume_active = false
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
