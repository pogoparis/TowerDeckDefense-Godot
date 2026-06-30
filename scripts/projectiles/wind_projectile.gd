extends BaseProjectile
class_name WindProjectile

@export var knockback_force := 40.0
@export var wind_hit_scene: PackedScene

# ── Visuels rafale de vent ────────────────────────────
var _age := 0.0
const LIFETIME := 0.35


func _ready():
	# Pas de sprite à cacher, tout est dessiné en code
	_regenerate()


func _regenerate():
	queue_redraw()


func _process(delta):
	super._process(delta)
	_age += delta
	queue_redraw()


func _draw():
	var t: float = _age / LIFETIME   # 0→1 pendant la vie

	# 3 arcs de vent en éventail, de plus en plus transparents avec l'âge
	var arcs := [
		{"offset": -18.0, "len": 38.0, "w": 4.0},
		{"offset":   0.0, "len": 48.0, "w": 6.0},
		{"offset":  18.0, "len": 38.0, "w": 4.0},
	]

	for arc_def in arcs:
		var pts := PackedVector2Array()
		var segs := 8
		for i in segs + 1:
			var s: float = float(i) / segs
			# Arc courbé vers l'avant (axe X = direction du tir)
			var x: float = lerp(0.0, arc_def["len"], s)
			var y: float = arc_def["offset"] * sin(s * PI)
			# Légère ondulation secondaire
			y += sin(s * TAU * 2.0 + _age * 12.0) * 4.0
			pts.append(Vector2(x, y))

		var alpha: float = lerp(0.85, 0.0, t)
		# Halo extérieur bleu clair
		draw_polyline(pts, Color(0.6, 0.88, 1.0, alpha * 0.5), arc_def["w"] + 4.0, true)
		# Filet principal blanc-bleu
		draw_polyline(pts, Color(0.85, 0.97, 1.0, alpha), arc_def["w"], true)
		# Cœur blanc
		draw_polyline(pts, Color(1.0, 1.0, 1.0, alpha * 0.7), arc_def["w"] * 0.4, true)

	# Petites particules qui s'envolent
	var particle_count := 5
	for i in particle_count:
		var s: float = float(i) / particle_count
		var px: float = lerp(8.0, 50.0, s) * (1.0 - t * 0.3)
		var py: float = sin(s * TAU + _age * 8.0) * 14.0
		var pr: float = lerp(4.0, 1.5, t)
		var pa: float = lerp(0.7, 0.0, t) * (1.0 - abs(s - 0.5) * 1.5)
		draw_circle(Vector2(px, py), pr, Color(0.8, 0.95, 1.0, pa))


func on_hit(hit_target):
	hit_target.take_damage(damage)
	if hit_target is EnemyBase:
		# PAF ! seulement quand l'ennemi prend WINDMARK (pas s'il l'a déjà).
		hit_target.apply_debuff(StatusIds.WINDMARK, 1.5, "paf")
		hit_target.apply_slow(0.35, 1.5)

	if wind_hit_scene:
		var fx := wind_hit_scene.instantiate()
		get_parent().add_child(fx)
		fx.global_position = target.global_position
