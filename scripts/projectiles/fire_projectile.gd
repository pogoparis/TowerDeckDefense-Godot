extends BaseProjectile
class_name FireProjectile

func on_hit(target):

	target.take_damage(damage)
