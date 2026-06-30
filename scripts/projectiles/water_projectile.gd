extends BaseProjectile
class_name WaterProjectile

## Ralentissement léger appliqué à l'impact (1.0 = aucun, 0.85 = -15 % de vitesse).
@export var slow_multiplier := 0.85
## Durée du ralentissement (secondes).
@export var slow_duration := 2.0

@onready var glow_sprite: Sprite2D = $GlowSprite

# ── Visuels jet d'eau ─────────────────────────────────
var _trail: Array = []
const TRAIL_MAX_AGE := 0.18
const TRAIL_INTERVAL := 0.025
var _trail_timer := 0.0
var _wobble_time := 0.0


func _ready():
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	if glow_sprite:
		glow_sprite.visible = false


func _process(delta):
	super._process(delta)

	_wobble_time += delta

	_trail_timer += delta
	if _trail_timer >= TRAIL_INTERVAL:
		_trail_timer = 0.0
		_trail.append({ "pos": global_position, "age": 0.0 })

	for entry in _trail:
		entry["age"] += delta
	_trail = _trail.filter(func(e): return e["age"] < TRAIL_MAX_AGE)

	queue_redraw()


func _draw():
	var wobble: float = sin(_wobble_time * 18.0) * 2.5

	# Halo extérieur
	_draw_ellipse(Vector2(2.0, wobble), 18.0, 9.0, Color(0.3, 0.75, 1.0, 0.35))
	# Corps cyan
	_draw_ellipse(Vector2(2.0, wobble), 14.0, 7.0, Color(0.15, 0.65, 1.0, 0.9))
	# Reflet blanc
	_draw_ellipse(Vector2(-2.0, wobble - 2.0), 5.0, 3.0, Color(1.0, 1.0, 1.0, 0.6))

	# Traînée de gouttelettes
	for entry in _trail:
		var t: float = entry["age"] / TRAIL_MAX_AGE
		var local_pos: Vector2 = to_local(entry["pos"])
		var r: float = lerp(5.0, 1.5, t)
		var alpha: float = lerp(0.6, 0.0, t)
		draw_circle(local_pos, r, Color(0.2, 0.7, 1.0, alpha))


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color):
	var points := PackedVector2Array()
	for i in 21:
		var angle: float = (TAU / 20.0) * i
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)


func on_hit(hit_target):
	var final_damage: int = damage

	if (
		source_tower != null
		and source_tower.laser_guide_active
		and hit_target.has_status(SynergyIds.VEGA_MARK)
	):
		final_damage = int(final_damage * 1.5)

	hit_target.take_damage(final_damage)
	hit_target.apply_debuff(StatusIds.WET, 3.0 + RunBonuses.get_wet_duration_bonus())

	# Léger ralentissement — sans écraser un ralentissement plus fort (stun, etc.).
	if hit_target.slow_multiplier > slow_multiplier:
		hit_target.apply_slow(slow_multiplier, slow_duration)
