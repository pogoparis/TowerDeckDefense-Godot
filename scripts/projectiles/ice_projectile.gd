extends BaseProjectile
class_name IceProjectile
## Projectile du Punk Glace : un éclat de givre.
##
## Peu de dégâts, tout est dans le GIVRE CUMULATIF (voir EnemyBase.add_chill).
## Chaque impact retire `chill_step` de vitesse et rafraîchit la durée, donc
## une cible sous le feu continu ralentit de plus en plus — jusqu'au plancher.
## C'est ce qui distingue la Glace de l'Eau (ralentissement accessoire à la
## combo WET) et de l'Air (ralentissement bref accessoire à la repoussée).

## −12 % de vitesse par impact. Il faut ~7 tirs pour atteindre le plancher
## (×0.4) : assez lent pour qu'une seule tour ne suffise pas, assez rapide pour
## que deux tours qui se recouvrent le fassent en quelques secondes.
@export var chill_step := 0.88
## Longue par rapport à l'Eau (2 s) et à l'Air (1.5 s) : l'ennemi doit rester
## gelé bien après être sorti du rayon, sinon ça ne "s'installe" pas.
@export var chill_duration := 4.5

var _spin := 0.0


func _process(delta: float) -> void:
	_spin += delta * 6.0
	queue_redraw()
	super._process(delta)


func _draw() -> void:
	# Éclat à 6 branches qui tourne sur lui-même.
	var branches := 6
	for i in branches:
		var angle: float = _spin + TAU * float(i) / branches
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(Vector2.ZERO, dir * 9.0, Color(0.75, 0.94, 1.0, 0.9), 2.5, true)
		# Petites barbules, pour la silhouette de flocon.
		var mid := dir * 5.5
		var perp := Vector2(-dir.y, dir.x) * 2.8
		draw_line(mid, mid + perp, Color(0.85, 0.97, 1.0, 0.7), 1.5, true)
		draw_line(mid, mid - perp, Color(0.85, 0.97, 1.0, 0.7), 1.5, true)

	draw_circle(Vector2.ZERO, 5.0, Color(0.6, 0.88, 1.0, 0.30))
	draw_circle(Vector2.ZERO, 2.6, Color(0.95, 1.0, 1.0, 1.0))


func on_hit(hit_target) -> void:
	hit_target.take_damage(damage, "normal", hit_element())
	if hit_target is EnemyBase:
		hit_target.add_chill(chill_step, chill_duration)
