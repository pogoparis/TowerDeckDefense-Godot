extends BaseProjectile
class_name FrostProjectile

func on_hit(target):

	target.take_damage(damage)

	target.apply_slow(0.5, 3.0)
