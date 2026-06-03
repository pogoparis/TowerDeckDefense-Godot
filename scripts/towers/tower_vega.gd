extends ProjectileTower
class_name TowerVega

var marked_target: EnemyBase = null

@onready var laser_line: Line2D = $LaserLine


func fire_projectile(target: Node2D):

	if target is EnemyBase:

		marked_target = target

		target.add_status(SynergyIds.VEGA_MARK)

	super.fire_projectile(target)

func _process(_delta):

	if not execution_froide_active:
		laser_line.visible = false
		return

	if not is_instance_valid(marked_target):
		laser_line.visible = false
		return

	laser_line.visible = true

	var start_pos := shoot_point.position
	var end_pos := to_local(marked_target.global_position)

	laser_line.points = PackedVector2Array([
		start_pos,
		end_pos
	])
