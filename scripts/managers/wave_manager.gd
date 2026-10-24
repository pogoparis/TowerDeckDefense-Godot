extends Node
class_name WaveManager

@export var prep_time := 20
@export var waves: Array[WaveData]

@onready var card_manager: CardManager = $"../CardManager"

var wave_started := false
var current_wave_index := 0
var prep_running := false

## Cartes débloquées par cette victoire (affichées sur l'écran de fin).
var _unlocked_this_run: Array[String] = []

# Vagues dont le tutoriel a déjà été montré (clé = index de vague).
var _tutorials_shown := {}

var path: Path2D
var top_hud: TopHUD
var enemy_manager: EnemyManager
var tower_manager: TowerManager

const PATH_FOLLOW_SCRIPT = preload("res://scripts/core/path_follow_2d.gd")
const ENEMY_SCENE = preload("res://scenes/enemies/SimpleMob.tscn")

func setup(
	new_path: Path2D,
	new_top_hud: TopHUD,
	new_enemy_manager: EnemyManager,
	new_tower_manager: TowerManager
):
	tower_manager = new_tower_manager
	path = new_path
	top_hud = new_top_hud
	enemy_manager = new_enemy_manager


func start_prep_phase(do_mulligan: bool = true):
	var level = get_tree().current_scene

	# Niveau tutoriel scripté ? (lecture sûre du flag sur le niveau)
	var scripted := false
	if level and "scripted_tutorial" in level:
		scripted = level.scripted_tutorial

	# Tutoriel data-driven : uniquement sur le niveau tutoriel, si la vague à
	# venir porte un texte, on l'affiche en pause (une seule fois par vague).
	if scripted and current_wave_index < waves.size() and level and level.has_method("show_tutorial"):
		var wave: WaveData = waves[current_wave_index]
		if wave.tutorial_text != "" and not _tutorials_shown.has(current_wave_index):
			_tutorials_shown[current_wave_index] = true
			await level.show_tutorial(wave.tutorial_title, wave.tutorial_text)
			if not is_inside_tree():
				return

	# Mulligan désactivé en tutoriel scripté (séquence de cartes imposée).
	if do_mulligan and not scripted and level and level.has_method("start_mulligan_phase"):
		var max_cards := 3 if current_wave_index == 0 else 1
		level.start_mulligan_phase(max_cards)

	if level and level.has_method("show_wave_preview") and current_wave_index < waves.size():
		level.show_wave_preview(current_wave_index, waves[current_wave_index])

	wave_started = false
	prep_running = true

	if top_hud:
		top_hud.set_wave(current_wave_index + 1, waves.size())
		top_hud.set_wave_total(0)

	for i in range(prep_time, 0, -1):
		if not prep_running:
			return
		if top_hud:
			top_hud.set_prep_countdown(i)
		if not is_inside_tree():
			return
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree():
			return

	if prep_running and Player.base_hp > 0:
		start_wave()


func force_start_wave():

	if not prep_running:
		return

	prep_running = false

	for i in range(5, 0, -1):
		if top_hud:
			top_hud.set_prep_countdown(i)
		if not is_inside_tree():
			return
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree():
			return

	start_wave()


func start_wave():

	if wave_started:
		return

	prep_running = false
	wave_started = true

	if top_hud:
		top_hud.set_wave_status("⚔  VAGUE EN COURS")

	var level := get_tree().current_scene
	if level and level.has_method("hide_wave_preview"):
		level.hide_wave_preview()

	if waves.is_empty():
		push_error("Aucune wave configurée")
		return

	if current_wave_index >= waves.size():
		if top_hud:
			top_hud.set_wave_status("— TOUTES LES VAGUES TERMINÉES —")
		return

	var wave_data = waves[current_wave_index]

	Player.set_wave(current_wave_index + 1)

	await spawn_wave_data(wave_data)
	if not is_inside_tree():
		return

	await wait_for_wave_clear()
	if not is_inside_tree():
		return

	# Revenus par vague : bonus de récompense + cartes ÉCONOMIE jouées.
	var caps_bonus := RunBonuses.get_caps_per_wave() + RunDeck.caps_per_wave
	if caps_bonus > 0:
		Player.add_caps(caps_bonus)
		FloatingTextService.spawn(
			get_tree().current_scene,
			Vector2(get_viewport().get_visible_rect().size / 2.0),
			"+" + str(caps_bonus) + " caps",
			Color(1.0, 0.85, 0.2),
			2.0
		)

	# Bonus Fouille des Décombres : pioche supplémentaire (max 4 cartes en main)
	var draw_bonus := RunBonuses.get_post_wave_draw_bonus()
	if draw_bonus > 0:
		var available_slots := card_manager.max_hand_size - card_manager.hand.size()
		if available_slots > 0:
			card_manager.draw_to_hand(min(draw_bonus, available_slots))
			get_tree().current_scene.refresh_hand_ui()

	# Annuler si game over (ex: miniboss passé)
	if Player.base_hp <= 0:
		return

	# Dernière vague : victoire
	if current_wave_index >= waves.size():
		_record_level_result()
		var lvl = get_tree().current_scene
		if lvl and lvl.has_method("show_victory"):
			lvl.show_victory()
		elif top_hud:
			top_hud.set_wave_status("VICTOIRE !")
		return

	RewardManager.show_rewards()

	while not RewardManager.reward_selected:
		if not is_inside_tree():
			return
		await get_tree().process_frame

	start_prep_phase()


## Attribue 1 à 3 étoiles selon les PV restants de la base :
## 3 si ≥ 90 %, 2 si ≥ 50 %, 1 sinon.
func _record_level_result() -> void:
	var ratio := float(Player.base_hp) / float(Player.MAX_BASE_HP)
	var stars := 1
	if ratio >= 0.9:
		stars = 3
	elif ratio >= 0.5:
		stars = 2
	Progress.complete_level(Progress.current_level_id, stars)
	# Déblocages : annoncés sur l'écran de victoire. Un déblocage silencieux
	# n'est pas une récompense — le joueur doit SAVOIR qu'il a gagné quelque
	# chose de durable, sinon la victoire ne promet rien pour la suite.
	_unlocked_this_run = Progress.unlock_for_level(Progress.current_level_id)


## Tutoriel : lance une vague et attend qu'elle soit nettoyée, SANS le flux
## normal (pas de mulligan, récompenses ni enchaînement). Piloté par le TutorialDirector.
func tutorial_spawn_and_wait(wave_data: WaveData) -> void:
	wave_started = true
	prep_running = false

	if top_hud:
		top_hud.set_wave_status("⚔  VAGUE EN COURS")

	await spawn_wave_data(wave_data)
	if not is_inside_tree():
		return

	while enemy_manager.get_all_enemies().size() > 0:
		if not is_inside_tree():
			return
		await get_tree().process_frame


func spawn_wave_data(wave_data: WaveData) -> void:
	var total := wave_data.total_count() + (1 if wave_data.boss_scene else 0)
	if top_hud:
		top_hud.set_wave_total(total)

	if wave_data.groups.size() > 0:
		# Vague mixée : on enchaîne chaque groupe (type/nombre propres).
		for g in wave_data.groups:
			if g == null or g.enemy_scene == null:
				continue
			await spawn_wave(g.count, g.spawn_interval, g.enemy_scene, g.hp_override, g.speed_override)
	else:
		# Vague mono-type (legacy).
		await spawn_wave(
			wave_data.enemy_count,
			wave_data.spawn_interval,
			wave_data.enemy_scene,
			wave_data.enemy_hp_override,
			wave_data.enemy_speed
		)

	if wave_data.boss_scene:
		await get_tree().create_timer(wave_data.boss_delay).timeout
		var pf := _spawn_enemy_instance(wave_data.boss_scene)
		if pf:
			path.add_child(pf)
			pf.progress = 0
			_apply_wave_scaling(pf)   # le boss monte aussi avec les vagues
			if top_hud:
				top_hud.on_enemy_spawned()
				top_hud.set_wave_status("⚠  MINIBOSS !")
			await get_tree().create_timer(1.5).timeout
			if top_hud:
				top_hud.set_wave_status("⚔  VAGUE EN COURS")


func spawn_wave(
	count: int,
	interval: float,
	enemy_scene: PackedScene,
	hp_override: int = 0,
	speed_override: float = 0.0
):

	if not path:
		return

	for i in range(count):

		var pf = _spawn_enemy_instance(enemy_scene)

		if pf:

			# Override de vitesse AVANT _ready : la vitesse vient de enemy.speed
			# (lue en direct par le PathFollow). 0 = on garde la vitesse de la scène.
			# Avant _ready pour que TankMob capture la bonne _base_speed.
			if speed_override > 0.0 and pf.get_child_count() > 0:
				var e0 = pf.get_child(0)
				if e0 is EnemyBase:
					e0.speed = speed_override

			path.add_child(pf)
			pf.progress = 0

			# Override des PV APRÈS _ready (qui fait hp = max_hp) pour être sûr.
			if hp_override > 0 and pf.get_child_count() > 0:
				var enemy = pf.get_child(0)
				if enemy is EnemyBase:
					enemy.max_hp = hp_override
					enemy.hp = hp_override
					enemy.update_hp_bar()

			# Montée en puissance de la vague (après l'override éventuel).
			_apply_wave_scaling(pf)

			if top_hud:
				top_hud.on_enemy_spawned()

		await get_tree().create_timer(interval).timeout


## Croissance des PV ennemis par vague. Sans ça, les vagues n'augmentent qu'en
## NOMBRE : une tour améliorée (×1.8 de DPS par palier) finit par one-shot les
## mobs, et la tension disparaît. Ici chaque vague les rend plus coriaces —
## c'est ce que fait BTD6 avec ses ballons de plus en plus résistants.
## ⚙ C'est LE réglage à tourner si le jeu est trop dur / trop facile.
## ⚠ Ce facteur se CUMULE à la montée des effectifs dans le plan de vagues.
## À 1.18 les ennemis gagnaient ×6.2 en PV sur 12 vagues, et les effectifs
## doublaient en parallèle : ×12 au total, contre ×8 côté joueur (plus de tours
## + améliorations). Résultat, le niveau devenait infaisable dès la V9 quel que
## soit le deck — 454 DPS requis pour un plafond de 289.
## 1.10 → V4 ×1.33, V8 ×1.95, V12 ×2.85. La courbe reste tendue sur la fin
## (V12 demande un peu plus que le plafond théorique : c'est une finale), mais
## elle redevient jouable.
@export var enemy_hp_growth := 1.10


## Multiplicateur de PV de la vague courante (vague 1 = ×1.0).
func _wave_hp_multiplier() -> float:
	return pow(enemy_hp_growth, float(current_wave_index))


## Applique la montée en PV de la vague à un ennemi déjà ajouté à l'arbre
## (donc après son _ready, qui a fait hp = max_hp).
func _apply_wave_scaling(pf: PathFollow2D) -> void:
	if pf == null or pf.get_child_count() == 0:
		return
	var enemy := pf.get_child(0) as EnemyBase
	if enemy == null:
		return
	var mult := _wave_hp_multiplier()
	# Mémorisé même à 1.0 : les enfants d'une scission en héritent.
	enemy.wave_scale = mult
	if mult <= 1.0:
		return
	enemy.max_hp = int(round(enemy.max_hp * mult))
	enemy.hp = enemy.max_hp
	enemy.update_hp_bar()


func _spawn_enemy_instance(enemy_scene: PackedScene) -> PathFollow2D:

	if not enemy_scene:

		push_error("enemy_scene est null")
		return null

	var pf := PathFollow2D.new()

	pf.set_script(PATH_FOLLOW_SCRIPT)

	pf.rotates = false
	pf.loop = false
	pf.visible = true

	var enemy := enemy_scene.instantiate() as EnemyBase

	if not enemy:

		push_error("Impossible d'instancier enemy_scene")
		return null

	pf.add_child(enemy)

	return pf


func wait_for_wave_clear():

	while enemy_manager.get_all_enemies().size() > 0:
		if not is_inside_tree():
			return
		await get_tree().process_frame

	if not is_inside_tree():
		return

	# Prime de fin de vague. Elle DOIT permettre de poser une tour de plus à
	# chaque vague, sinon le joueur reste bloqué sur sa pose de départ et la
	# partie n'a plus de courbe de progression (le "je construis ma machine"
	# de BTD6). Vague 1 → 12 caps, vague 6 → 22, vague 12 → 34.
	Player.add_caps(10 + 2 * current_wave_index)

	card_manager.draw_until_full_hand()

	get_tree().current_scene.refresh_hand_ui()

	current_wave_index += 1
