extends BaseProjectile
class_name FireProjectile

@onready var glow_sprite: Sprite2D = $GlowSprite

func _process(delta):

	super._process(delta)

	if glow_sprite == null:
		return

	glow_sprite.visible = (
		source_tower != null
		and source_tower.laser_guide_active
	)

	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.15

	glow_sprite.scale = Vector2.ONE * pulse * 1.4


func on_hit(target):

	var final_damage = damage

	if (
		source_tower != null
		and source_tower.laser_guide_active
		and target.has_status(SynergyIds.VEGA_MARK)
	):
		final_damage = int(final_damage * 1.5)

	target.take_damage(final_damage)

	_spawn_tower_phenomenon(target)


func _spawn_tower_phenomenon(target):

	if source_tower == null:
		return

	print(
		"TOWER=",
		source_tower.get_script().get_global_name(),
		" ELEMENT=",
		source_tower.element_type
	)

	var phenomenon_manager := (
		get_tree()
		.current_scene
		.get_node_or_null("PhenomenonManager")
	)

	if phenomenon_manager == null:
		return

	match source_tower.element_type:

		ElementType.Type.WATER:

			print("SPAWN WATER")

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

			print("SPAWN FIRE")

			phenomenon_manager.spawn_phenomenon(
				PhenomenonType.Type.FIRE_ZONE,
				target.global_position,
				source_tower.phenomenon_radius
			)

		ElementType.Type.NATURE:

			print("SPAWN NATURE")

			phenomenon_manager.spawn_phenomenon(
				PhenomenonType.Type.THORN_PATCH,
				target.global_position,
				source_tower.phenomenon_radius
			)

		ElementType.Type.AIR:

			print("SPAWN AIR")

			phenomenon_manager.spawn_phenomenon(
				PhenomenonType.Type.WIND_CURRENT,
				target.global_position,
				source_tower.phenomenon_radius
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
