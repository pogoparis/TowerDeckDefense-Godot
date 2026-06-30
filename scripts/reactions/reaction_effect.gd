extends Node2D
class_name ReactionEffect

@export var radius := 80.0
@export var duration := 3.0
@export var tick_rate := 0.5
@export var damage := 15

var enemy_manager: EnemyManager

var elapsed := 0.0
var tick_timer := 0.0

func _process(delta):

	elapsed += delta
	tick_timer += delta

	queue_redraw()

	if tick_timer >= tick_rate:

		tick_timer = 0.0

		damage_enemies()

	if elapsed >= duration:
		queue_free()


func damage_enemies():

	if enemy_manager == null:
		return

	for enemy in enemy_manager.get_all_enemies():

		if not is_instance_valid(enemy):
			continue

		if enemy.global_position.distance_to(global_position) > radius:
			continue

		enemy.take_damage(damage, "tick")


func _draw():

	draw_circle(
		Vector2.ZERO,
		radius,
		Color(1.0, 1.0, 0.2, 0.25)
	)
