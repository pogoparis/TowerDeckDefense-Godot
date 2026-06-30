extends BaseProjectile
class_name BasicProjectile
## Projectile basique : dégâts purs, aucun statut ni phénomène.
## Pour les tours de base (ex : PinkPunk).

func _draw() -> void:
	# Petite bille claire (le dessin suit le projectile qui se déplace).
	draw_circle(Vector2.ZERO, 6.0, Color(0.85, 0.88, 0.95, 0.85))
	draw_circle(Vector2.ZERO, 3.0, Color(1, 1, 1, 1))


func on_hit(hit_target) -> void:
	hit_target.take_damage(damage)
