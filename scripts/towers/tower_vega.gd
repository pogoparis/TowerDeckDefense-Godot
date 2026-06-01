extends ProjectileTower
class_name TowerVega

func fire_projectile(target: Node2D):

	if target is EnemyBase:
		target.add_status(SynergyIds.VEGA_MARK)
