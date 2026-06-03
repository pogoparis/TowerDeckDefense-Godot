extends BaseTower
class_name ProjectileTower

@export var projectile_scene: PackedScene
@onready var shoot_point: Marker2D = $ShootPoint

func _ready():

	if is_ghost:
		return

	super._ready()

	if timer:
		timer.wait_time = fire_rate
		timer.timeout.connect(_on_timer_timeout)
		timer.start()

func _on_timer_timeout():

	if projectile_scene == null:
		return
	var valid_target = find_target()

	if valid_target == null:
		return

	fire_projectile(valid_target)

func fire_projectile(target: Node2D):

	var projectile = projectile_scene.instantiate()

	projectile.global_position = shoot_point.global_position
	projectile.target = target
	projectile.damage = damage
	projectile.source_tower = self

	get_parent().add_child(projectile)
