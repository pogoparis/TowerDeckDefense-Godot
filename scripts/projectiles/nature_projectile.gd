extends BaseProjectile
class_name NatureProjectile
## Éclat de bambou du Panda Punk.
##
## Dégâts directs modestes : l'essentiel passe par le POISON, qui ronge en
## pourcentage des PV max. Sur un Pillard c'est anecdotique, sur un Tank ou un
## Drone Punk c'est la meilleure source de dégâts du jeu.

## Longue durée : le poison doit survivre à la sortie du rayon, c'est ce qui en
## fait une pression continue plutôt qu'un dégât de plus.
@export var poison_duration := 5.0

var _spin := 0.0


func _process(delta: float) -> void:
	_spin += delta * 14.0
	queue_redraw()
	super._process(delta)


func _draw() -> void:
	# Segment de bambou qui tournoie + deux feuilles.
	var l := 11.0
	var dir := Vector2(cos(_spin), sin(_spin))
	var perp := Vector2(-dir.y, dir.x)

	draw_line(-dir * l, dir * l, Color(0.16, 0.30, 0.10, 0.9), 8.0, true)
	draw_line(-dir * l, dir * l, Color(0.52, 0.80, 0.24), 5.0, true)
	# Nœuds du bambou.
	for t in [-0.35, 0.35]:
		draw_line(dir * l * t - perp * 3.0, dir * l * t + perp * 3.0,
			Color(0.30, 0.52, 0.15), 2.0, true)

	for side: float in [1.0, -1.0]:
		var base := dir * l * 0.2
		var tip: Vector2 = base + perp * (side * 7.0) + dir * 4.0
		draw_line(base, tip, Color(0.40, 0.78, 0.28), 3.5, true)


func on_hit(hit_target) -> void:
	hit_target.take_damage(damage, "normal", hit_element())
	if hit_target is EnemyBase:
		hit_target.apply_debuff(StatusIds.POISONED, poison_duration)
