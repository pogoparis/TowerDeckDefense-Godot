extends BaseProjectile
class_name RockProjectile
## Projectile du Gardien Rocheux : un gros caillou lancé au lance-pierre.
## Dégâts bruts et lourds, tir lent — c'est la réponse aux blindés.

var _spin := 0.0


func _process(delta: float) -> void:
	_spin += delta * 5.0
	queue_redraw()
	super._process(delta)


func _draw() -> void:
	# Caillou irrégulier (polygone tournant) avec une facette claire.
	var pts := PackedVector2Array()
	var n := 7
	for i in n:
		var a: float = _spin + (TAU / n) * i
		var r: float = 8.0 + sin(i * 2.3) * 2.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	draw_colored_polygon(pts, Color(0.42, 0.30, 0.19))
	draw_polyline(pts, Color(0.25, 0.17, 0.10, 0.9), 2.0, true)
	draw_circle(Vector2(-2, -2), 3.0, Color(0.66, 0.50, 0.32, 0.9))


func on_hit(hit_target) -> void:
	hit_target.take_damage(damage, "normal", hit_element())
	if hit_target is EnemyBase:
		# POUSSIÈRE : sans statut, la Terre restait hors du système de réactions.
		# Elle sert de moitié à la Tempête de Sable (avec la Marque de Vent).
		hit_target.apply_debuff(StatusIds.DUSTY, 3.0)
