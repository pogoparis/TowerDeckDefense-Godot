extends BaseProjectile
class_name ElectricProjectile

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


func on_hit(target):
	target.take_damage(damage)
	target.add_status(StatusIds.CHARGED, 3.0)
