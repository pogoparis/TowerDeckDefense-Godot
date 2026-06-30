extends ProjectileTower
class_name TowerWaterCannon

func _ready():
	element_type = ElementType.Type.WATER
	super._ready()


func find_target() -> Node2D:
	if not enemy_manager:
		return null

	var enemies := enemy_manager.get_all_enemies()

	var phenomenon_manager := _get_phenomenon_manager()
	var electric_fields: Array = []
	if phenomenon_manager:
		electric_fields = phenomenon_manager.get_active_phenomena().filter(
			func(p): return p.phenomenon_type == PhenomenonType.Type.ELECTRIC_FIELD
		)

	# ── Priorité 1 : dans un Electric Field, pas stun, pas WET ──
	if not electric_fields.is_empty():
		var field_best: Node2D = null
		var field_best_progress := -1.0
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			if global_position.distance_to(enemy.global_position) > attack_range:
				continue
			if enemy.has_status(StatusIds.STUNNED):
				continue
			if enemy.has_status(StatusIds.WET):
				continue
			for field in electric_fields:
				if field.global_position.distance_to(enemy.global_position) <= field.radius:
					var pf := enemy.get_parent() as PathFollow2D
					var progress: float = pf.progress if pf != null else 0.0
					if progress > field_best_progress:
						field_best_progress = progress
						field_best = enemy
					break
		if field_best:
			return field_best

		# Priorité 1b : dans Electric Field, pas stun (même si WET — mieux que rien)
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

	# ── Priorité 2 : en portée, pas WET, le plus avancé ──
	var best: Node2D = null
	var best_progress := -1.0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > attack_range:
			continue
		if enemy.has_status(StatusIds.WET):
			continue
		var pf := enemy.get_parent() as PathFollow2D
		var progress: float = pf.progress if pf != null else 0.0
		if progress > best_progress:
			best_progress = progress
			best = enemy
	if best:
		return best

	# ── Priorité 3 : fallback — le plus avancé en portée (même WET) ──
	return super.find_target()


func _get_phenomenon_manager() -> PhenomenonManager:
	var scene := get_tree().current_scene
	if scene:
		return scene.get_node_or_null("PhenomenonManager")
	return null
