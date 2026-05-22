extends Node2D

@export var speed := 300

var damage: int
var target: Node2D = null

func _process(delta):
	if not is_instance_valid(target):
		queue_free()
		return

	var dir = (target.global_position - global_position).normalized()
	global_position += dir * speed * delta

	if global_position.distance_to(target.global_position) < 10:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
