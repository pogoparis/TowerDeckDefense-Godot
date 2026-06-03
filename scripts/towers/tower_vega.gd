extends ProjectileTower
class_name TowerVega

var marked_target: EnemyBase = null

@onready var laser_line: Line2D = $LaserLine

func set_buff_visual(active: bool):

	super.set_buff_visual(active)

	if sprite_material == null:
		return

	if active:
		sprite_material.set_shader_parameter(
			"outline_size",
			5
		)

func fire_projectile(target: Node2D):

	if target is EnemyBase:

		marked_target = target

		target.add_status(SynergyIds.VEGA_MARK)

	super.fire_projectile(target)

func get_outline_size() -> float:
	return 5.0

func _process(_delta):

	if not laser_guide_active:
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
