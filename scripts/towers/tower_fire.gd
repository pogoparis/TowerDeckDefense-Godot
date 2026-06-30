extends ProjectileTower
class_name TowerFire

func _ready():
	element_type = ElementType.Type.FIRE
	super._ready()


## Cible en priorité l'ennemi le plus avancé qui ne brûle pas encore
## (évite de gaspiller des tirs sur une cible déjà en feu).
func find_target() -> Node2D:
	if not enemy_manager:
		return null

	var best: Node2D = null
	var best_progress := -1.0
	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > attack_range:
			continue
		if enemy.has_status(StatusIds.BURNING):
			continue
		var pf := enemy.get_parent() as PathFollow2D
		var progress: float = pf.progress if pf != null else 0.0
		if progress > best_progress:
			best_progress = progress
			best = enemy
	if best:
		return best

	# Fallback : le plus avancé en portée (même déjà en feu).
	return super.find_target()
