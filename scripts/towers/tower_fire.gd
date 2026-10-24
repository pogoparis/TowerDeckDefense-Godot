extends ProjectileTower
class_name TowerFire

func _ready():
	super._ready()


## Effet de Charge — Bombardement napalm : une grande zone de feu au sol
## (réutilise le moteur de zones : dégâts par tick + statut BURNING).
func _charge_effect() -> void:
	var pm = get_phenomenon_manager()
	if pm == null:
		return
	pm.spawn_phenomenon(PhenomenonType.Type.FIRE_ZONE, global_position, 170.0, 8.0)
	Audio.play_sfx(preload("res://assets/audio/sfx/shot_fire.wav"), 0.0)


## Cible en priorité l'ennemi le plus avancé qui ne brûle pas encore
## (évite de gaspiller des tirs sur une cible déjà en feu).
func _find_target_special() -> Node2D:
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
	return null
