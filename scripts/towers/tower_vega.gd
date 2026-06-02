extends ProjectileTower
class_name TowerVega

func fire_projectile(target: Node2D):

	if target is EnemyBase:

		if not target.has_status(SynergyIds.VEGA_MARK):

			target.add_status(SynergyIds.VEGA_MARK)

	super.fire_projectile(target)
