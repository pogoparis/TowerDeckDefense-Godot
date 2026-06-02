extends BaseProjectile
class_name FireProjectile

func on_hit(target):

	var final_damage = damage

	if (
		source_tower != null
		and source_tower.execution_froide_active
		and target.has_status(SynergyIds.VEGA_MARK)
	):

		final_damage = int(final_damage * 1.5)

	target.take_damage(final_damage)
