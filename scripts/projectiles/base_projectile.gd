extends Node2D
class_name BaseProjectile

var target: Node2D
var damage := 10
var source_tower: BaseTower
var homing_strength := 0.0

@export var speed := 500.0
@export var hit_distance := 12.0
@export var impact_scene: PackedScene

func _process(delta):

	if not is_instance_valid(target):
		queue_free()
		return

	var dir = global_position.direction_to(target.global_position)

	rotation = dir.angle()
	global_position += dir * speed * delta

	if global_position.distance_to(target.global_position) <= hit_distance:

		on_hit(target)

		spawn_impact()

		queue_free()

func on_hit(_target):

	pass

func spawn_impact():

	if not impact_scene:
		return

	var impact = impact_scene.instantiate()

	impact.global_position = global_position

	get_parent().add_child(impact)
