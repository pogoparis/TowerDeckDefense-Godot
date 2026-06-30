extends Node2D
class_name Phenomenon

@export var phenomenon_type: PhenomenonType.Type
@export var radius := 64.0
@export var duration := 5.0
@export var min_reaction_age := 1.5

const WATER_POOL_SCENE := preload("res://scenes/phenomena/water_pool.tscn")

# Contamination (statut)
var contamination_timer := 0.0
const CONTAMINATION_INTERVAL := 0.5

# Dégâts directs (Electric Field uniquement)
var damage_timer := 0.0
const ELECTRIC_DAMAGE_INTERVAL := 0.25
const ELECTRIC_TICK_DAMAGE     := 5

# Knockback (Wind Current uniquement)
const WIND_KNOCKBACK_FORCE    := 55.0   # pixels reculés
const WIND_KNOCKBACK_INTERVAL := 3.0    # secondes entre deux poussées
var _wind_knockback_timer := 0.0

var power := 1
var age   := 0.0
var visual: Node2D = null

# Arcs animés (Electric Field)
var _arcs: Array = []
var _arc_timer := 0.0
const ARC_FLICKER := 0.07


func _ready():
	create_visual()
	if phenomenon_type == PhenomenonType.Type.ELECTRIC_FIELD:
		duration = max(duration, 7.0)
		_spawn_entry_flash()
		# Frappe immédiate : pas d'attente du premier tick
		apply_contamination()
		_apply_electric_damage()


func create_visual():
	match phenomenon_type:
		PhenomenonType.Type.WATER_POOL:
			visual = WATER_POOL_SCENE.instantiate()
			add_child(visual)
			visual.scale = Vector2.ONE
			update_visual_scale()


func update_visual_scale():
	if visual == null:
		return
	visual.scale = Vector2.ONE * (1.0 + (power - 1) * 0.15)


func refresh():
	age = 0.0
	power    = min(power + 1, 5)
	radius   = min(radius + 4.0, 96.0)
	duration = min(duration + 0.5, 8.0)
	update_visual_scale()


func _process(delta):
	age += delta

	# ── Cooldowns cross-shock par ennemi ──────────────
	for key in _cross_shock_timers.keys():
		_cross_shock_timers[key] -= delta
		if _cross_shock_timers[key] <= 0.0:
			_cross_shock_timers.erase(key)

	# ── Contamination (statut sur ennemis) ────────────
	contamination_timer -= delta
	if contamination_timer <= 0.0:
		contamination_timer = CONTAMINATION_INTERVAL
		apply_contamination()

	# ── Dégâts Electric Field ─────────────────────────
	if phenomenon_type == PhenomenonType.Type.ELECTRIC_FIELD:
		damage_timer -= delta
		if damage_timer <= 0.0:
			damage_timer = ELECTRIC_DAMAGE_INTERVAL
			_apply_electric_damage()

		# Re-générer les arcs visuels
		_arc_timer -= delta
		if _arc_timer <= 0.0:
			_arc_timer = ARC_FLICKER
			_regenerate_arcs()

	# ── Knockback Wind Current ────────────────────────
	if phenomenon_type == PhenomenonType.Type.WIND_CURRENT:
		_wind_knockback_timer -= delta
		if _wind_knockback_timer <= 0.0:
			_wind_knockback_timer = WIND_KNOCKBACK_INTERVAL
			_apply_wind_knockback()

	queue_redraw()

	if age >= duration:
		queue_free()


# ══════════════════════════════════════════════════════
# CONTAMINATION — applique le statut
# ══════════════════════════════════════════════════════
func get_status_id() -> String:
	match phenomenon_type:
		PhenomenonType.Type.WATER_POOL:     return StatusIds.WET
		PhenomenonType.Type.ELECTRIC_FIELD: return StatusIds.CHARGED
		PhenomenonType.Type.FIRE_ZONE:      return StatusIds.BURNING
		PhenomenonType.Type.THORN_PATCH:    return StatusIds.ROOTED
		PhenomenonType.Type.WIND_CURRENT:   return StatusIds.WINDMARK
	return ""


func apply_contamination():
	var enemy_manager := get_tree().get_first_node_in_group("enemy_manager")
	if enemy_manager == null:
		return
	var status_id := get_status_id()
	if status_id == "":
		return
	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > radius:
			continue

		# Renouvelle le statut à chaque tick (pas seulement à la première application)
		enemy.add_status(status_id, 3.0)

		# Water Pool : ralentit fortement les ennemis dans la flaque
		if phenomenon_type == PhenomenonType.Type.WATER_POOL:
			enemy.apply_slow(0.25, CONTAMINATION_INTERVAL + 0.1)

		# Réaction croisée : Water Pool + CHARGED → électrocution immédiate
		if phenomenon_type == PhenomenonType.Type.WATER_POOL and enemy.has_status(StatusIds.CHARGED):
			_trigger_cross_electrocution(enemy)


# ══════════════════════════════════════════════════════
# ELECTRIC FIELD — dégâts + texte flottant
# ══════════════════════════════════════════════════════
func _apply_electric_damage():
	var enemy_manager := get_tree().get_first_node_in_group("enemy_manager")
	if enemy_manager == null:
		return
	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > radius:
			continue
		enemy.take_damage(ELECTRIC_TICK_DAMAGE, "tick")

		# Si l'ennemi est WET : stun 2 secondes + texte spécial (affiché une seule fois)
		if enemy.has_status(StatusIds.WET):
			var was_stunned: bool = enemy.has_status(StatusIds.STUNNED)
			enemy.apply_slow(0.0, 2.0)
			enemy.add_status(StatusIds.STUNNED, 2.0)
			if not was_stunned:
				FloatingTextService.spawn(
					get_tree().current_scene,
					enemy.global_position + Vector2(randf_range(-15, 15), -55),
					"⚡ PARALYSÉ !",
					Color(1.0, 1.0, 0.0),
					1.2
				)


# ══════════════════════════════════════════════════════
# VISUELS — arcs électriques internes
# ══════════════════════════════════════════════════════
func _regenerate_arcs():
	_arcs.clear()
	var count := int(randf_range(3.0, 6.0))
	for i in count:
		var a1: float = randf_range(0.0, TAU)
		var r1: float = randf_range(0.0, radius * 0.8)
		var a2: float = a1 + randf_range(-1.2, 1.2)
		var r2: float = randf_range(0.0, radius * 0.85)
		var mid := Vector2(
			randf_range(-radius * 0.5, radius * 0.5),
			randf_range(-radius * 0.5, radius * 0.5)
		)
		_arcs.append({
			"from":  Vector2(cos(a1) * r1, sin(a1) * r1),
			"to":    Vector2(cos(a2) * r2, sin(a2) * r2),
			"mid":   mid,
			"alpha": randf_range(0.4, 1.0)
		})


func _draw():
	var t := age / duration    # 0→1 (fade vers la fin)
	var pulse := 1.0 + sin(age * 5.0) * 0.05

	match phenomenon_type:

		PhenomenonType.Type.WATER_POOL:
			draw_circle(Vector2.ZERO, radius, Color(0.15, 0.45, 1.0, 0.30))
			draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 48,
				Color(0.3, 0.7, 1.0, 0.85), 3.0)

		PhenomenonType.Type.ELECTRIC_FIELD:
			var life: float = lerp(1.0, 0.3, t)

			# Fond jaune-bleu
			draw_circle(Vector2.ZERO, radius, Color(0.2, 0.3, 0.9, 0.20 * life))
			draw_circle(Vector2.ZERO, radius * 0.5, Color(0.8, 0.9, 0.2, 0.12 * life))

			# Anneau externe pulsant
			draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 64,
				Color(1.0, 1.0, 0.2, 0.85 * life), 3.0)
			# Anneau interne
			draw_arc(Vector2.ZERO, radius * 0.5 * pulse, 0.0, TAU, 40,
				Color(0.6, 0.8, 1.0, 0.5 * life), 1.5)

			# Arcs internes crépitants
			for arc in _arcs:
				var a: float = arc["alpha"] * life
				var pts := PackedVector2Array([arc["from"], arc["mid"], arc["to"]])
				draw_polyline(pts, Color(0.3, 0.6, 1.0, a * 0.4), 5.0, true)
				draw_polyline(pts, Color(1.0, 1.0, 0.3, a),        2.0, true)
				draw_polyline(pts, Color(1.0, 1.0, 1.0, a * 0.7),  0.8, true)

			# Rayons depuis le centre
			var ray_count := 6
			for i in ray_count:
				var angle: float = (TAU / ray_count) * i + age * 2.0
				var rlen: float = radius * (0.4 + sin(age * 5.0 + i * 1.3) * 0.12)
				draw_line(Vector2.ZERO,
					Vector2(cos(angle) * rlen, sin(angle) * rlen),
					Color(1.0, 1.0, 0.4, 0.35 * life), 6.0)
				draw_line(Vector2.ZERO,
					Vector2(cos(angle) * rlen, sin(angle) * rlen),
					Color(1.0, 1.0, 0.8, 0.7 * life), 1.2)

		PhenomenonType.Type.FIRE_ZONE:
			draw_circle(Vector2.ZERO, radius, Color(1.0, 0.25, 0.0, 0.28))
			draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 48,
				Color(1.0, 0.5, 0.0, 0.90), 3.0)

		PhenomenonType.Type.THORN_PATCH:
			draw_circle(Vector2.ZERO, radius, Color(0.1, 0.8, 0.1, 0.28))
			draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 48,
				Color(0.2, 1.0, 0.2, 0.90), 3.0)

		PhenomenonType.Type.WIND_CURRENT:
			draw_circle(Vector2.ZERO, radius, Color(0.4, 0.9, 1.0, 0.22))
			draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 48,
				Color(0.5, 1.0, 1.0, 0.85), 3.0)


# ══════════════════════════════════════════════════════
# WIND CURRENT — repousse les ennemis dans la zone
# ══════════════════════════════════════════════════════
func _apply_wind_knockback():
	var enemy_manager := get_tree().get_first_node_in_group("enemy_manager")
	if enemy_manager == null:
		return
	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > radius:
			continue
		enemy.apply_knockback(WIND_KNOCKBACK_FORCE)
		# Petite rafale visuelle sur chaque ennemi repoussé
		_spawn_wind_puff(enemy.global_position)


func _spawn_wind_puff(pos: Vector2):
	var root := Node2D.new()
	get_parent().add_child(root)
	root.global_position = pos
	root.z_index = 20
	for i in 4:
		var streak := Node2D.new()
		root.add_child(streak)
		streak.position = Vector2(randf_range(-12.0, 12.0), randf_range(-20.0, 20.0))
		var length: float = randf_range(22.0, 50.0)
		var d := Node2D.new()
		streak.add_child(d)
		var c := Color(0.5, 1.0, 1.0, randf_range(0.55, 0.85))
		d.draw.connect(func():
			d.draw_line(Vector2.ZERO, Vector2(-length, 0), c, 2.0)
			d.draw_line(Vector2.ZERO, Vector2(-length * 0.6, 0), Color(c.r, c.g, c.b, c.a * 0.3), 5.0)
		)
		d.queue_redraw()
		var tw := streak.create_tween()
		tw.set_parallel(true)
		tw.tween_property(streak, "position:x", streak.position.x - randf_range(15.0, 30.0), 0.3)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(streak, "modulate:a", 0.0, 0.3)
		tw.chain().tween_callback(streak.queue_free)
	var cleanup := create_tween()
	cleanup.tween_interval(0.4)
	cleanup.tween_callback(root.queue_free)


# ══════════════════════════════════════════════════════
# RÉACTION CROISÉE — Water Pool + CHARGED = électrocution
# ══════════════════════════════════════════════════════
const CROSS_SHOCK_DAMAGE     := 80
const CROSS_STUN_DURATION    := 3.0
const CROSS_SHOCK_COOLDOWN   := 4.0
var _cross_shock_timers: Dictionary = {}   # enemy → cooldown restant

func _trigger_cross_electrocution(enemy: Node2D):
	# Cooldown par ennemi pour éviter le spam
	var enemy_id := enemy.get_instance_id()
	if _cross_shock_timers.get(enemy_id, 0.0) > 0.0:
		return
	_cross_shock_timers[enemy_id] = CROSS_SHOCK_COOLDOWN

	var stun: float = CROSS_STUN_DURATION + RunBonuses.get_stun_duration_bonus()
	var dmg: int    = int(CROSS_SHOCK_DAMAGE * RunBonuses.get_electrocution_damage_mult())

	enemy.take_damage(dmg, "silent")
	enemy.apply_slow(0.0, stun)
	enemy.add_status(StatusIds.STUNNED, stun)

	# Flash visuel sur l'ennemi
	_spawn_cross_shock_flash(enemy.global_position)

	FloatingTextService.spawn(
		get_tree().current_scene,
		enemy.global_position + Vector2(0, -65),
		"⚡ COURT-CIRCUIT !",
		Color(0.4, 0.9, 1.0),
		1.4
	)


func _spawn_cross_shock_flash(pos: Vector2):
	var flash := Node2D.new()
	get_parent().add_child(flash)
	flash.global_position = pos
	flash.z_index = 50

	var d := Node2D.new()
	flash.add_child(d)
	d.draw.connect(func():
		d.draw_circle(Vector2.ZERO, 36.0, Color(0.5, 0.9, 1.0, 0.8))
		d.draw_circle(Vector2.ZERO, 18.0, Color(1.0, 1.0, 1.0, 1.0))
		# Arcs courts
		for i in 6:
			var a: float = (TAU / 6.0) * i
			d.draw_line(Vector2.ZERO,
				Vector2(cos(a) * 30.0, sin(a) * 30.0),
				Color(0.6, 1.0, 1.0, 0.9), 2.0)
	)
	d.queue_redraw()

	var tween := flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.6, 1.6), 0.2)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(flash.queue_free)


# ══════════════════════════════════════════════════════
# ENTRÉE — flash quand le phénomène apparaît
# ══════════════════════════════════════════════════════
func _spawn_entry_flash():
	var flash := Node2D.new()
	add_child(flash)
	flash.z_index = 10

	var draw_node := Node2D.new()
	flash.add_child(draw_node)
	draw_node.draw.connect(func():
		draw_node.draw_circle(Vector2.ZERO, radius * 1.1, Color(0.9, 1.0, 0.4, 0.7))
		draw_node.draw_circle(Vector2.ZERO, radius * 0.5,  Color(1.0, 1.0, 0.7, 0.9))
	)
	draw_node.queue_redraw()

	var tween := flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.3, 1.3), 0.25)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(flash.queue_free)

	FloatingTextService.spawn(
		get_tree().current_scene,
		global_position + Vector2(0, -radius - 10),
		"⚡ Champ électrique !",
		Color(1.0, 1.0, 0.3),
		1.5
	)
