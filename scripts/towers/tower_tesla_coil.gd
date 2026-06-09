extends ProjectileTower
class_name TowerTeslaCoil

func _ready():
	element_type = ElementType.Type.ELECTRIC
	super._ready()


func find_target() -> Node2D:
	if not enemy_manager:
		return null

	var enemies := enemy_manager.get_all_enemies()

	# Priorité : ennemis en portée qui ne sont PAS déjà stun
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > attack_range:
			continue
		if not enemy.has_status(StatusIds.STUNNED):
			return enemy

	# Fallback : n'importe quel ennemi en portée (tous déjà stun)
	return super.find_target()
