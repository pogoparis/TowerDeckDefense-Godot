extends ReactionEffect
class_name ElectrocutionZone

# ── Paramètres électrocution ──────────────────────────
const STUN_DURATION   := 3.0    # secondes d'immobilisation
const BURST_DAMAGE    := 40     # dégâts immédiats à l'entrée
const TICK_DAMAGE     := 15     # dégâts par tick
const TICK_RATE_SEC   := 0.35
const ZONE_DURATION   := 3.5    # durée totale de la zone

# ── État interne ──────────────────────────────────────
var _age       := 0.0
var _tick_acc  := 0.0
var _arc_lines : Array = []     # [{from, to, alpha}]
var _arc_timer := 0.0
const ARC_FLICKER := 0.06

func _ready():
	radius    = 112.0
	duration  = ZONE_DURATION
	tick_rate = TICK_RATE_SEC
	damage    = TICK_DAMAGE
	z_index   = 15

	# Entrée dramatique : flash + burst damage + stun
	_trigger_entry()


# ══════════════════════════════════════════════════════
# ENTRÉE — le moment qui sauve la game
# ══════════════════════════════════════════════════════
func _trigger_entry():
	# 1) Flash blanc-jaune instantané
	_spawn_entry_flash()

	# 2) Burst damage + stun sur TOUS les ennemis dans le rayon
	if enemy_manager == null:
		return

	var hit_count := 0
	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(global_position) > radius:
			continue

		enemy.take_damage(BURST_DAMAGE)
		enemy.apply_slow(0.0, STUN_DURATION)          # stun = immobilisation totale
		enemy.add_status(StatusIds.STUNNED, STUN_DURATION)
		enemy.add_status(StatusIds.CHARGED, STUN_DURATION)
		hit_count += 1

	# 3) Texte flottant spectaculaire
	if hit_count > 0:
		FloatingTextService.spawn(
			get_tree().current_scene,
			global_position + Vector2(0, -80),
			"⚡ ÉLECTROCUTION ! ⚡",
			Color(1.0, 1.0, 0.0),
			2.2
		)
		FloatingTextService.spawn(
			get_tree().current_scene,
			global_position + Vector2(0, -50),
			str(BURST_DAMAGE) + " DMG — STUN " + str(STUN_DURATION) + "s",
			Color(0.9, 0.9, 1.0),
			1.6
		)


# ══════════════════════════════════════════════════════
# PROCESS — ticks + visuels
# ══════════════════════════════════════════════════════
func _process(delta):
	_age      += delta
	_tick_acc += delta
	_arc_timer += delta

	# Re-génère les arcs toutes les 60ms
	if _arc_timer >= ARC_FLICKER:
		_arc_timer = 0.0
		_regenerate_arcs()

	# Tick de dégâts
	if _tick_acc >= TICK_RATE_SEC:
		_tick_acc = 0.0
		_damage_tick()

	queue_redraw()

	if _age >= ZONE_DURATION:
		queue_free()


func _damage_tick():
	if enemy_manager == null:
		return
	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(global_position) > radius:
			continue
		enemy.take_damage(TICK_DAMAGE)
		# Maintient le stun
		enemy.apply_slow(0.0, STUN_DURATION * 0.5)

		# Mini FloatingText sur chaque ennemi touché
		FloatingTextService.spawn(
			get_tree().current_scene,
			enemy.global_position + Vector2(randf_range(-20, 20), -45),
			"⚡" + str(TICK_DAMAGE),
			Color(1.0, 1.0, 0.3),
			0.9
		)


# ══════════════════════════════════════════════════════
# VISUELS — zone électrique spectaculaire
# ══════════════════════════════════════════════════════
func _regenerate_arcs():
	_arc_lines.clear()
	var count := int(randf_range(5.0, 9.0))
	for i in count:
		var angle := randf_range(0.0, TAU)
		var dist  := randf_range(radius * 0.2, radius * 0.9)
		var from  := Vector2(cos(angle), sin(angle)) * dist * 0.3
		var to    := Vector2(cos(angle + randf_range(-0.6, 0.6)), sin(angle + randf_range(-0.6, 0.6))) * dist
		_arc_lines.append({
			"from":  from,
			"to":    to,
			"alpha": randf_range(0.5, 1.0),
			"mid":   (from + to) * 0.5 + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		})


func _draw():
	var t_ratio: float = _age / ZONE_DURATION
	var pulse: float = 1.0 + sin(_age * 8.0) * 0.06

	# ── Fond de zone ──────────────────────────────────
	# Halo extérieur bleu profond
	draw_circle(Vector2.ZERO, radius * 1.1, Color(0.0, 0.1, 0.5, 0.18))
	# Zone principale jaune-bleu
	draw_circle(Vector2.ZERO, radius, Color(0.15, 0.3, 0.9, lerp(0.35, 0.1, t_ratio)))
	# Cœur brillant
	draw_circle(Vector2.ZERO, radius * 0.35, Color(0.7, 0.9, 1.0, lerp(0.4, 0.05, t_ratio)))

	# ── Anneau de bordure qui pulse ────────────────────
	draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 64,
		Color(0.3, 0.8, 1.0, lerp(0.9, 0.3, t_ratio)), 4.0)
	# Deuxième anneau intérieur
	draw_arc(Vector2.ZERO, radius * 0.55 * pulse, 0.0, TAU, 48,
		Color(1.0, 1.0, 0.4, lerp(0.7, 0.1, t_ratio)), 2.0)

	# ── Arcs électriques internes ──────────────────────
	for arc in _arc_lines:
		var a: float = arc["alpha"] * lerp(1.0, 0.2, t_ratio)
		var mid: Vector2 = arc["mid"]
		var pts := PackedVector2Array([arc["from"], mid, arc["to"]])
		# Halo
		draw_polyline(pts, Color(0.2, 0.5, 1.0, a * 0.4), 6.0, true)
		# Arc principal jaune
		draw_polyline(pts, Color(1.0, 1.0, 0.3, a), 2.5, true)
		# Cœur blanc
		draw_polyline(pts, Color(1.0, 1.0, 1.0, a * 0.8), 1.0, true)

	# ── Rayons depuis le centre ────────────────────────
	var ray_count := 8
	for i in ray_count:
		var angle: float = (TAU / ray_count) * i + _age * 1.5
		var ray_len: float = radius * (0.6 + sin(_age * 6.0 + i) * 0.15)
		var end_pt := Vector2(cos(angle) * ray_len, sin(angle) * ray_len)
		var ray_a: float = lerp(0.6, 0.05, t_ratio)
		draw_line(Vector2.ZERO, end_pt, Color(0.8, 1.0, 0.4, ray_a * 0.3), 8.0)
		draw_line(Vector2.ZERO, end_pt, Color(1.0, 1.0, 0.6, ray_a), 1.5)


# ══════════════════════════════════════════════════════
# FLASH D'ENTRÉE
# ══════════════════════════════════════════════════════
func _spawn_entry_flash():
	# Cercle blanc qui explose depuis le centre
	var flash := Node2D.new()
	get_parent().add_child(flash)
	flash.global_position = global_position
	flash.z_index = 50

	var draw := Node2D.new()
	flash.add_child(draw)
	draw.draw.connect(func():
		draw.draw_circle(Vector2.ZERO, radius * 1.3, Color(0.9, 1.0, 0.5, 0.85))
		draw.draw_circle(Vector2.ZERO, radius * 0.8,  Color(1.0, 1.0, 0.8, 0.95))
		draw.draw_circle(Vector2.ZERO, radius * 0.3,  Color(1.0, 1.0, 1.0, 1.0))
	)
	draw.queue_redraw()

	var tween := flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.4, 1.4), 0.18)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(flash.queue_free)

	# Anneau de choc qui s'étend
	var ring := Node2D.new()
	get_parent().add_child(ring)
	ring.global_position = global_position
	ring.z_index = 45
	ring.scale = Vector2(0.05, 0.05)

	var rdraw := Node2D.new()
	ring.add_child(rdraw)
	rdraw.draw.connect(func():
		rdraw.draw_arc(Vector2.ZERO, radius * 1.05, 0.0, TAU, 64, Color(0.4, 0.9, 1.0, 0.9), 5.0)
	)
	rdraw.queue_redraw()

	var rtween := ring.create_tween()
	rtween.set_parallel(true)
	rtween.tween_property(ring, "scale", Vector2(1.0, 1.0), 0.3)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	rtween.tween_property(ring, "modulate:a", 0.0, 0.3).set_delay(0.05)
	rtween.chain().tween_callback(ring.queue_free)
