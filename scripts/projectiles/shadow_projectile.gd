extends BaseProjectile
class_name ShadowProjectile
## Projectile du Vampire : une toile d'ombre qui inflige des dégâts et applique
## la MARQUE D'OMBRE — l'ennemi marqué encaisse ensuite plus de dégâts de
## TOUTES les sources (rôle amplificateur/support de l'élément Ombre).

## Durée de la Marque d'Ombre appliquée à l'impact (secondes).
@export var mark_duration := 5.0

var _spin := 0.0


func _process(delta: float) -> void:
	_spin += delta * 8.0
	queue_redraw()
	super._process(delta)


func _draw() -> void:
	# Petite toile sombre auréolée de rouge (thème araignée/vampire).
	draw_circle(Vector2.ZERO, 9.0, Color(0.35, 0.05, 0.25, 0.35))
	draw_circle(Vector2.ZERO, 5.0, Color(0.10, 0.02, 0.14, 0.9))
	# Rayons de toile qui tournent.
	for i in 6:
		var a: float = _spin + (TAU / 6.0) * i
		draw_line(
			Vector2.ZERO,
			Vector2(cos(a), sin(a)) * 8.0,
			Color(0.95, 0.85, 0.95, 0.75),
			1.5
		)
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.25, 0.35, 1.0))


func on_hit(hit_target) -> void:
	hit_target.take_damage(damage, "normal", hit_element())
	hit_target.apply_debuff(StatusIds.MARKED, mark_duration)
