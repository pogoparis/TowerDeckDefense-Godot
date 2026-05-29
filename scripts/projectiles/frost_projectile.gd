extends Node2D

var target: Node2D
var damage := 10

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

		if target.has_method("take_damage"):
			target.take_damage(damage)

		if target.has_method("apply_slow"):
			target.apply_slow(0.5, 3.0)

		spawn_impact()

		queue_free()

func spawn_impact():

	if not impact_scene:
		return

	var impact = impact_scene.instantiate()
	
	impact.global_position = global_position

	get_parent().add_child(impact)
