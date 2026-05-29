extends BaseTower
class_name ProjectileTower

@export var projectile_scene: PackedScene

@onready var shoot_point: Marker2D = $ShootPoint

func _ready():

	super._ready()

	if is_ghost:
		return

	if timer:
		timer.timeout.connect(_on_timer_timeout)
		timer.start()

func _on_timer_timeout():

	var target = find_target()

	if target == null:
		return

	fire_projectile(target)

func fire_projectile(target):
	pass
