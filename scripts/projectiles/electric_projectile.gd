extends BaseProjectile
class_name ElectricProjectile

# ── Arcs en chaîne (sautent de mob en mob) ───────────────────
@export_group("Arcs en chaîne")
## Nombre de sauts vers des ennemis supplémentaires (0 = désactivé).
@export var chain_jumps := 3
## Distance max d'un saut entre deux ennemis (pixels).
@export var chain_range := 210.0
## Dégâts × ce facteur à chaque saut (0.6 = -40 % par saut).
@export var chain_falloff := 0.6

# ── Visuels arc électrique ────────────────────────────
var _arc_points: PackedVector2Array = []
var _arc_timer := 0.0
const ARC_FLICKER_RATE := 0.04   # re-randomise toutes les 40ms


func _ready():
	# Cache le sprite hérité (image de feu, mauvais pour l'électricité)
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	_regenerate_arc()


func _regenerate_arc():
	_arc_points.clear()
	var segments := 10
	for i in segments + 1:
		var t: float = float(i) / segments
		var x: float = lerp(-55.0, 55.0, t)
		# Amplitude max au milieu, nulle aux extrémités
		var amp: float = 22.0 * sin(t * PI)
		var y: float = randf_range(-amp, amp)
		_arc_points.append(Vector2(x, y))


func _process(delta):
	super._process(delta)

	_arc_timer += delta
	if _arc_timer >= ARC_FLICKER_RATE:
		_arc_timer = 0.0
		_regenerate_arc()
		queue_redraw()


func _draw():
	if _arc_points.size() < 2:
		return

	# Halo extérieur bleu
	draw_polyline(_arc_points, Color(0.3, 0.6, 1.0, 0.4), 14.0, true)
	# Arc principal blanc-jaune
	draw_polyline(_arc_points, Color(1.0, 1.0, 0.5, 1.0), 5.0, true)
	# Filet intérieur blanc pur
	draw_polyline(_arc_points, Color(1.0, 1.0, 1.0, 0.85), 2.0, true)

	# Noyau brillant au centre
	draw_circle(Vector2.ZERO, 10.0, Color(0.8, 0.9, 1.0, 0.9))
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 1.0, 1.0, 1.0))


func on_hit(hit_target):
	hit_target.take_damage(damage)
	hit_target.apply_debuff(StatusIds.CHARGED, 3.0)
	_chain_lightning(hit_target)


## L'éclair saute vers les ennemis proches, dégâts atténués à chaque saut.
func _chain_lightning(first_target) -> void:
	if chain_jumps <= 0 or source_tower == null:
		return
	var em = source_tower.enemy_manager
	if em == null:
		return

	var already := [first_target]
	var current = first_target
	var dmg := float(damage)

	for _j in chain_jumps:
		var next := _nearest_unhit(current, already, em)
		if next == null:
			break
		dmg *= chain_falloff
		next.take_damage(maxi(1, int(round(dmg))))
		next.add_status(StatusIds.CHARGED, 3.0)   # chargé aussi, mais sans onomatopée
		_spawn_arc(current.global_position, next.global_position)
		already.append(next)
		current = next


func _nearest_unhit(from_enemy, already: Array, em) -> Node2D:
	var best: Node2D = null
	var best_dist := chain_range
	for e in em.get_all_enemies():
		if not is_instance_valid(e) or already.has(e):
			continue
		var d: float = from_enemy.global_position.distance_to(e.global_position)
		if d <= best_dist:
			best_dist = d
			best = e
	return best


func _spawn_arc(from_w: Vector2, to_w: Vector2) -> void:
	var effects := get_tree().current_scene.get_node_or_null("World/EffectsContainer")
	if effects == null:
		effects = get_parent()
	if effects == null:
		return

	var pts := _jagged_line(from_w, to_w)
	var node := Node2D.new()
	node.z_index = 60
	effects.add_child(node)
	node.draw.connect(func():
		# Halo bleu large
		node.draw_polyline(pts, Color(0.3, 0.6, 1.0, 0.5), 13.0, true)
		# Corps jaune-blanc épais
		node.draw_polyline(pts, Color(1.0, 1.0, 0.6, 1.0), 5.5, true)
		# Cœur blanc pur
		node.draw_polyline(pts, Color(1.0, 1.0, 1.0, 1.0), 2.2, true)
		# Éclats lumineux aux deux extrémités
		node.draw_circle(pts[0], 9.0, Color(0.8, 0.95, 1.0, 0.9))
		node.draw_circle(pts[pts.size() - 1], 12.0, Color(1.0, 1.0, 0.85, 0.95))
	)
	node.queue_redraw()

	# Tient bien visible un court instant, puis s'estompe (~0.4s).
	var tw := node.create_tween()
	tw.tween_interval(0.12)
	tw.tween_property(node, "modulate:a", 0.0, 0.28)
	tw.tween_callback(node.queue_free)


func _jagged_line(from_w: Vector2, to_w: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var segs := 7
	var dir := to_w - from_w
	var perp := Vector2(-dir.y, dir.x).normalized()
	for i in segs + 1:
		var t := float(i) / segs
		var base := from_w.lerp(to_w, t)
		var amp := 14.0 * sin(t * PI)   # zéro aux extrémités
		pts.append(base + perp * randf_range(-amp, amp))
	return pts
