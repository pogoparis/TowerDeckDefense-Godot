extends BaseProjectile
class_name MolotovProjectile

## Projectile cocktail Molotov : la bouteille tournoie en vol, laisse une
## traînée de feu, et enflamme la cible à l'impact.

## Durée du statut BURNING appliqué à l'impact (secondes).
@export var burn_duration := 4.0
## Vitesse de rotation de la bouteille en vol (tumble), en tours/seconde-ish.
@export var spin_speed := 14.0

@onready var _spr: Sprite2D = get_node_or_null("Sprite2D")

# Traînée de feu.
var _trail: Array = []
const TRAIL_INTERVAL := 0.025
const TRAIL_MAX_AGE := 0.3
var _trail_timer := 0.0


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	# Déplacement vers la cible (sans tourner le NŒUD : la traînée reste droite).
	var dir := global_position.direction_to(target.global_position)
	global_position += dir * speed * delta

	# La bouteille tournoie (le sprite, pas le nœud).
	if _spr:
		_spr.rotation += spin_speed * delta

	# Traînée de feu.
	_trail_timer += delta
	if _trail_timer >= TRAIL_INTERVAL:
		_trail_timer = 0.0
		_trail.append({ "pos": global_position, "age": 0.0 })
	for entry in _trail:
		entry["age"] += delta
	_trail = _trail.filter(func(e): return e["age"] < TRAIL_MAX_AGE)
	queue_redraw()

	# Impact.
	if global_position.distance_to(target.global_position) <= hit_distance:
		on_hit(target)
		spawn_impact()
		queue_free()


func _draw() -> void:
	# Traînée de feu : jaune au cœur → orange → rouge en se dissipant.
	for entry in _trail:
		var t: float = entry["age"] / TRAIL_MAX_AGE
		var local_pos: Vector2 = to_local(entry["pos"])
		var r: float = lerp(9.0, 2.0, t)
		var col := Color(1.0, 0.8, 0.2, 0.85).lerp(Color(0.8, 0.15, 0.0, 0.0), t)
		draw_circle(local_pos, r, col)


func on_hit(hit_target):
	hit_target.take_damage(damage)
	hit_target.apply_debuff(StatusIds.BURNING, burn_duration)
