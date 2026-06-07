extends BaseProjectile
class_name FrostProjectile

func on_hit(target):

	target.take_damage(damage)

	target.add_status(
		StatusIds.CHARGED,
		3.0
	)
