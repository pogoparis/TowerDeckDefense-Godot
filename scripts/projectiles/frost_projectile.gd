extends BaseProjectile
class_name FrostProjectile

func on_hit(target):

	target.take_damage(damage)

	target.apply_slow(0.5, 3.0)

	_spawn_tower_phenomenon(target)


func _spawn_tower_phenomenon(target):

	if source_tower == null:
		return

	var phenomenon_manager := (
		get_tree()
		.current_scene
		.get_node_or_null("PhenomenonManager")
	)

	if phenomenon_manager == null:
		return

	match source_tower.element_type:

		ElementType.Type.WATER:

			phenomenon_manager.spawn_phenomenon(
				PhenomenonType.Type.WATER_POOL,
				target.global_position,
				source_tower.phenomenon_radius
			)

		ElementType.Type.ELECTRIC:

			print("SPAWN ELECTRIC")

			phenomenon_manager.spawn_phenomenon(
				PhenomenonType.Type.ELECTRIC_FIELD,
				target.global_position,
				source_tower.phenomenon_radius
			)

		ElementType.Type.FIRE:

			phenomenon_manager.spawn_phenomenon(
				PhenomenonType.Type.FIRE_ZONE,
				target.global_position,
				source_tower.phenomenon_radius
			)

		ElementType.Type.NATURE:

			phenomenon_manager.spawn_phenomenon(
				PhenomenonType.Type.THORN_PATCH,
				target.global_position,
				source_tower.phenomenon_radius
			)

		ElementType.Type.AIR:

			phenomenon_manager.spawn_phenomenon(
				PhenomenonType.Type.WIND_CURRENT,
				target.global_position,
				source_tower.phenomenon_radius
			)
