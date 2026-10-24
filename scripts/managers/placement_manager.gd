class_name PlacementManager
extends Node


@onready var card_manager: CardManager = $"../CardManager"

## Plus de plafond arbitraire : ce sont les EMPLACEMENTS constructibles
## (la bande autour du chemin) qui limitent le nombre de tours — modèle
## Kingdom Rush, où la carte dicte la contrainte, pas un chiffre caché.

var selected_tower_scene: PackedScene = null
var ghost_tower: Node2D = null
var enemy_manager: EnemyManager
var tower_manager: TowerManager
const VALID_COLOR = Color(0, 1, 0, 0.5)
const INVALID_COLOR = Color(1, 0, 0, 0.5)
var grid: GridManager
var tower_container: Node2D
var current_mouse_world := Vector2.ZERO
var path: Path2D
var selected_card : CardData = null

# Tutoriel : si actif, la pose n'est autorisée QUE sur cette case.
var forced_cell_active := false
var forced_cell := Vector2i.ZERO


func _process(_delta):

	if not grid:
		return

	update_ghost(grid, current_mouse_world)


func is_placing() -> bool:

	return ghost_tower != null or selected_spell != null or selected_upgrade_card != null


# ══════════════════════════════════════════════════════
#                        SORTS
# ══════════════════════════════════════════════════════
#
# Un sort se vise comme une tour se pose : on suit la souris, on clique, ça
# part. Réutiliser ce flux plutôt que d'en créer un second garantit que le
# joueur n'a rien de nouveau à apprendre — et que le mode "je vise" reste
# exclusif (on ne peut pas viser un sort en posant une tour).

## Sort en cours de visée, et la carte qui le porte (pour la défausser).
var selected_spell: SpellData = null
var selected_spell_card: CardData = null


func start_spell_targeting(spell: SpellData, card: CardData) -> void:
	clear_placement()
	selected_spell = spell
	selected_spell_card = card


## Carte UPGRADE en cours de visée : on désigne la TOUR à améliorer.
var selected_upgrade_card: CardData = null


func start_upgrade_targeting(card: CardData) -> void:
	clear_placement()
	selected_upgrade_card = card


## Améliore gratuitement la tour la plus proche du point visé.
## Retourne true si l'amélioration a eu lieu.
func try_cast_upgrade(world_pos: Vector2) -> bool:
	if selected_upgrade_card == null:
		return false

	var best: BaseTower = null
	var best_dist := 90.0        # tolérance de visée : on ne rate pas au pixel
	for t in tower_manager.get_all_towers():
		if not is_instance_valid(t) or not t.can_upgrade():
			continue
		var d := t.global_position.distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best = t

	if best == null:
		# Rien d'améliorable ici : on REMBOURSE plutôt que de gâcher la carte.
		# Une carte perdue sur un clic à côté serait une punition injuste.
		Player.add_caps(selected_upgrade_card.mana_cost)
		if card_manager:
			card_manager.alert_no_target()
		return false

	best.upgrade_level += 1
	best.recalculate_stats()
	if best.timer:
		best.timer.wait_time = best.fire_rate
	best._play_upgrade_feedback()

	# Effets secondaires de la carte (ex : Atelier Mobile pioche aussi).
	if card_manager:
		if selected_upgrade_card.draw_cards > 0:
			card_manager.draw_to_hand(selected_upgrade_card.draw_cards)
		card_manager.discard_card(selected_upgrade_card)
		get_tree().current_scene.refresh_hand_ui()
	selected_upgrade_card = null
	return true


## Lance le sort au point visé. Retourne true si le sort est parti.
func try_cast_spell(world_pos: Vector2) -> bool:
	if selected_spell == null:
		return false

	var card := selected_spell_card
	# On débite SEULEMENT au lancement : viser puis annuler ne coûte rien.
	if card != null and not Player.spend_caps(card.mana_cost):
		if card_manager:
			card_manager.alert_not_enough_caps()
		return false

	_apply_spell(selected_spell, world_pos)

	if card_manager and card != null:
		card_manager.discard_card(card)

	selected_spell = null
	selected_spell_card = null
	selected_upgrade_card = null
	return true


func cancel_spell() -> void:
	selected_spell = null
	selected_spell_card = null


func _apply_spell(spell: SpellData, world_pos: Vector2) -> void:
	var scene := get_tree().current_scene

	match spell.effect:
		SpellData.Effect.DAMAGE:
			for e in _enemies_in(world_pos, spell.radius):
				e.take_damage(spell.damage, "normal", spell.element)

		SpellData.Effect.STUN:
			for e in _enemies_in(world_pos, spell.radius):
				e.apply_slow(0.0, spell.duration)
				e.add_status(StatusIds.STUNNED, spell.duration)
				if spell.damage > 0:
					e.take_damage(spell.damage, "normal", spell.element)

		SpellData.Effect.PHENOMENON:
			var pm := scene.get_node_or_null("PhenomenonManager") as PhenomenonManager
			if pm:
				pm.spawn_phenomenon(spell.phenomenon, world_pos, spell.radius, spell.duration)

		SpellData.Effect.TOWER_BUFF:
			for t in tower_manager.get_all_towers():
				if not is_instance_valid(t):
					continue
				if t.global_position.distance_to(world_pos) > spell.radius:
					continue
				t.apply_temp_buff(spell.buff_damage_mult, spell.buff_fire_rate_mult, spell.duration)

	# Ralentissement optionnel, cumulable avec n'importe quel effet.
	if spell.slow_multiplier < 1.0:
		for e in _enemies_in(world_pos, spell.radius):
			if e.slow_multiplier > spell.slow_multiplier:
				e.apply_slow(spell.slow_multiplier, spell.duration)

	if spell.cast_label != "":
		FloatingTextService.spawn(scene, world_pos + Vector2(0, -40),
			spell.cast_label, spell.cast_color, 1.3)
	if spell.shake > 0.0:
		Juice.shake(spell.shake, 0.25)


func _enemies_in(center: Vector2, radius: float) -> Array:
	var result := []
	if enemy_manager == null:
		return result
	for e in enemy_manager.get_all_enemies():
		if is_instance_valid(e) and e.global_position.distance_to(center) <= radius:
			result.append(e)
	return result

func handle_input(event, mouse_world: Vector2) -> bool:

	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_RIGHT:

			return handle_right_click()

		if event.button_index == MOUSE_BUTTON_LEFT:

			return handle_left_click(mouse_world)

	return false

func setup(
	new_grid: GridManager,
	new_tower_container: Node2D,
	new_path: Path2D,
	new_enemy_manager: EnemyManager,
	new_tower_manager: TowerManager
	
):
	
	tower_manager = new_tower_manager
	grid = new_grid
	tower_container = new_tower_container
	path = new_path
	enemy_manager = new_enemy_manager

func block_path_cells():

	if not path or not path.curve:
		return

	grid.blocked_cells.clear()

	var curve = path.curve
	var length = curve.get_baked_length()

	var step = 4.0
	var d := 0.0

	while d <= length:

		var local_point = curve.sample_baked(d)

		var world_point = path.to_global(local_point)

		var cell = grid.world_to_cell(world_point)

		grid.blocked_cells[cell] = true

		d += step

func handle_right_click() -> bool:

	if ghost_tower:

		cancel_placement()

		return true

	return false
	
	
func try_place_tower(mouse_world: Vector2):

	if not selected_tower_scene:
		return

	var cell = grid.world_to_cell(mouse_world)

	# Tutoriel : pose interdite hors de la case imposée.
	if forced_cell_active and cell != forced_cell:
		return

	if not grid.can_place(cell):
		return

	# Plafond de tours signature sur le terrain. Sans lui, un deck riche en
	# signatures finit avec 6-8 jauges pleines en même temps : "DÉCLENCHER"
	# devient du clic de routine au lieu d'un moment de décision. En limitant à
	# MAX_SIGNATURE_TOWERS, la Charge reste un pouvoir rare — et le joueur doit
	# CHOISIR quelles signatures il pose, ce qui donne du sens à la composition.
	if not _can_place_signature():
		_alert_signature_limit()
		return

	if selected_card:

		if not Player.spend_caps(selected_card.mana_cost):
			if card_manager:
				card_manager.alert_not_enough_caps()
			return

	var final_tower = tower_manager.create_tower(
		selected_tower_scene,
		grid.cell_to_world(cell),
		enemy_manager
	)


	final_tower.grid_cell = cell

	# Carte ★ : la tour posée est une version renforcée. Les multiplicateurs
	# vivent sur la CARTE et non sur la scène, pour qu'une même scène de tour
	# serve aux deux versions — sinon il faudrait dupliquer les 9 .tscn.
	if selected_card != null and selected_card.upgraded:
		final_tower.apply_card_upgrade(
			selected_card.up_damage_mult,
			selected_card.up_fire_rate_mult,
			selected_card.up_range_mult,
			selected_card.up_charge_bonus
		)

	tower_manager.notify_towers_changed()

	if final_tower.has_method("update_aura"):
		final_tower.update_aura()

	grid.occupy_cell(cell, final_tower)

	card_manager.discard_card(selected_card)
	get_tree().current_scene.refresh_hand_ui()

	clear_placement()

## Nombre max de tours signature (celles qui portent une jauge de Charge)
## posables simultanément. 3 = de quoi faire une vraie combo à déclencher,
## sans transformer l'écran en tableau de bord.
const MAX_SIGNATURE_TOWERS := 3


## La scène à poser est-elle une signature ? On l'instancie pas pour rien :
## on lit la propriété exportée sur l'état initial de la scène.
var _signature_scene_cache := {}

func _scene_is_signature(scene: PackedScene) -> bool:
	if scene == null:
		return false
	if _signature_scene_cache.has(scene):
		return _signature_scene_cache[scene]
	var result := _probe_signature(scene)
	_signature_scene_cache[scene] = result
	return result


## Une tour compte dans le plafond seulement si elle porte une Charge MANUELLE.
## Les tours à Charge automatique ont beau avoir une jauge, elles ne demandent
## rien au joueur : les plafonner n'aurait aucun sens, le plafond protège son
## attention, pas la puissance brute.
func _probe_signature(scene: PackedScene) -> bool:
	var sig := false
	var auto := false
	var state := scene.get_state()
	var found_sig := false
	var found_auto := false
	for i in state.get_node_property_count(0):
		var pname := state.get_node_property_name(0, i)
		if pname == "is_signature":
			sig = bool(state.get_node_property_value(0, i))
			found_sig = true
		elif pname == "charge_auto":
			auto = bool(state.get_node_property_value(0, i))
			found_auto = true

	# Propriétés non surchargées dans la .tscn : on lit les valeurs du script.
	if not found_sig or not found_auto:
		var probe := scene.instantiate()
		if probe is BaseTower:
			if not found_sig:
				sig = probe.is_signature
			if not found_auto:
				auto = probe.charge_auto
		probe.free()

	return sig and not auto


func _signature_count() -> int:
	var n := 0
	for t in tower_manager.get_all_towers():
		if t and t.is_signature and not t.charge_auto:
			n += 1
	return n


func _can_place_signature() -> bool:
	if not _scene_is_signature(selected_tower_scene):
		return true
	return _signature_count() < MAX_SIGNATURE_TOWERS


func _alert_signature_limit() -> void:
	Audio.error()
	var scene := get_tree().current_scene
	if scene is Node2D:
		FloatingTextService.spawn(
			scene,
			scene.get_global_mouse_position() + Vector2(0, -40),
			"MAX %d TOURS SIGNATURE !" % MAX_SIGNATURE_TOWERS,
			Color(1, 0.5, 0.2),
			1.6
		)


func update_ghost(grid_ref: GridManager, mouse_world: Vector2):

	if ghost_tower == null:
		return

	var cell = grid_ref.world_to_cell(mouse_world)
	ghost_tower.global_position = grid_ref.cell_to_world(cell)

	# Tutoriel : seul l'emplacement imposé apparaît valide.
	if forced_cell_active:
		ghost_tower.modulate = VALID_COLOR if (cell == forced_cell and grid_ref.can_place(cell)) else INVALID_COLOR
		return

	if grid_ref.can_place(cell):
		ghost_tower.modulate = VALID_COLOR
	else:
		ghost_tower.modulate = INVALID_COLOR

func start_tower_placement(
	scene: PackedScene,
	card: CardData,
	container: Node2D
):

	selected_tower_scene = scene
	selected_card = card

	create_ghost(scene, container)

	block_path_cells()
	_disable_ghost_behaviors()

func _disable_ghost_behaviors():

	if ghost_tower and ghost_tower is BaseTower:

		ghost_tower.is_ghost = true
		ghost_tower.disable_behaviors()

func cancel_placement():

	clear_placement()

func clear_placement():

	if ghost_tower:
		ghost_tower.queue_free()
		
	selected_card = null
	ghost_tower = null
	selected_tower_scene = null
	# Annuler une visée de sort ne coûte rien : les Caps ne partent qu'au
	# lancement effectif.
	selected_spell = null
	selected_spell_card = null

func handle_left_click(mouse_world: Vector2) -> bool:

	if ghost_tower:

		try_place_tower(mouse_world)

		return true

	return false

func create_ghost(scene: PackedScene, parent: Node):
	
	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = scene.instantiate()
	
	parent.add_child(ghost_tower)

	ghost_tower.z_index = 999
	ghost_tower.modulate = Color(0, 1, 0, 0.5)
