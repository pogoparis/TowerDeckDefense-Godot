extends ProjectileTower
class_name TowerWaterCannon

func _ready():
	element_type = ElementType.Type.WATER
	super._ready()


func find_target() -> Node2D:
	if not enemy_manager:
		return null

	var enemies := enemy_manager.get_all_enemies()

	# ── Priorité 1 : ennemi dans un Electric Field + dans portée ──
	var phenomenon_manager := _get_phenomenon_manager()
	if phenomenon_manager:
		var electric_fields := phenomenon_manager.get_active_phenomena().filter(
			func(p): return p.phenomenon_type == PhenomenonType.Type.ELECTRIC_FIELD
		)
		if not electric_fields.is_empty():
			# Priorité 1 : ennemi dans le field, en portée, PAS déjà stun
			for enemy in enemies:
				if not is_instance_valid(enemy):
					continue
				if global_position.distance_to(enemy.global_position) > attack_range:
					continue
				if enemy.has_status(StatusIds.STUNNED):
					continue
				for field in electric_fields:
					if field.global_position.distance_to(enemy.global_position) <= field.radius:
						return enemy
			# Si tous les mobs dans le field sont déjà stun → ciblage normal

	# ── Priorité 2 : ciblage normal (premier ennemi en portée) ──
	return super.find_target()


func _get_phenomenon_manager() -> PhenomenonManager:
	# Remonte jusqu'à la scène principale pour trouver le PhenomenonManager
	var scene := get_tree().current_scene
	if scene:
		return scene.get_node_or_null("PhenomenonManager")
	return null
