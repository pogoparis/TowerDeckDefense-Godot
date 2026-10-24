extends BaseProjectile
class_name LightProjectile
## Projectile de la Luciole : une petite bille de lumière chaude.
## Dégâts purs — la vraie force de l'élément Lumière est son HALO, qui
## renforce les tours voisines (voir tower_luciole.gd).

var _pulse := 0.0


func _process(delta: float) -> void:
	_pulse += delta * 9.0
	queue_redraw()
	super._process(delta)


func _draw() -> void:
	var glow := 1.0 + sin(_pulse) * 0.15
	# Halo chaud → cœur blanc.
	draw_circle(Vector2.ZERO, 11.0 * glow, Color(1.0, 0.85, 0.35, 0.22))
	draw_circle(Vector2.ZERO, 6.5 * glow, Color(1.0, 0.90, 0.45, 0.55))
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 1.0, 0.92, 1.0))


func on_hit(hit_target) -> void:
	hit_target.take_damage(damage, "normal", hit_element())
