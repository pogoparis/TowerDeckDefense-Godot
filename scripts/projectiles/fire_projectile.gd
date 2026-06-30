extends BaseProjectile
class_name FireProjectile

## Projectile de la Tour de Feu.
## Inflige des dégâts directs + applique le statut BURNING (dégâts sur la durée).

## Durée du statut BURNING appliqué à l'impact (secondes).
@export var burn_duration := 4.0

# ── Visuels traînée de flammes ────────────────────────
var _trail: Array = []
const TRAIL_MAX_AGE := 0.22
const TRAIL_INTERVAL := 0.02
var _trail_timer := 0.0
var _flicker := 0.0


func _ready():
	if has_node("Sprite2D"):
		$Sprite2D.visible = false


func _process(delta):
	super._process(delta)

	_flicker += delta

	_trail_timer += delta
	if _trail_timer >= TRAIL_INTERVAL:
		_trail_timer = 0.0
		_trail.append({ "pos": global_position, "age": 0.0 })

	for entry in _trail:
		entry["age"] += delta
	_trail = _trail.filter(func(e): return e["age"] < TRAIL_MAX_AGE)

	queue_redraw()


func _draw():
	# Traînée de flammes : jaune au cœur → orange → rouge en se dissipant.
	for entry in _trail:
		var t: float = entry["age"] / TRAIL_MAX_AGE
		var local_pos: Vector2 = to_local(entry["pos"])
		var r: float = lerp(11.0, 2.0, t)
		var col := Color(1.0, 0.85, 0.2, 0.9).lerp(Color(0.8, 0.15, 0.0, 0.0), t)
		draw_circle(local_pos, r, col)

	# Cœur ardent qui vacille.
	var pulse: float = 1.0 + sin(_flicker * 30.0) * 0.15
	draw_circle(Vector2.ZERO, 13.0 * pulse, Color(1.0, 0.4, 0.0, 0.85))
	draw_circle(Vector2.ZERO, 8.0 * pulse, Color(1.0, 0.85, 0.3, 0.95))
	draw_circle(Vector2.ZERO, 4.0 * pulse, Color(1.0, 1.0, 0.8, 1.0))


func on_hit(hit_target):
	hit_target.take_damage(damage)
	hit_target.apply_debuff(StatusIds.BURNING, burn_duration)
