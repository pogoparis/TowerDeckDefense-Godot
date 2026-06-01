extends BaseProjectile
class_name FireProjectile

func on_hit(target):

	var final_damage = damage

	print("HAS MARK = ", target.has_status(SynergyIds.VEGA_MARK))
	print("EXECUTION ACTIVE = ", source_tower.execution_froide_active)

	if (
		source_tower != null
		and source_tower.execution_froide_active
		and target.has_status(SynergyIds.VEGA_MARK)
	):
		print("EXECUTION BONUS")
		final_damage = int(final_damage * 1.5)

	print("FINAL DAMAGE = ", final_damage)

	target.take_damage(final_damage)
