extends PathFollow2D

@export var speed := 120.0

func _physics_process(delta):

	var final_speed = speed

	if get_child_count() > 0:

		var enemy = get_child(0)

		if enemy is EnemyBase:

			final_speed *= enemy.slow_multiplier

	progress += final_speed * delta

	if progress_ratio >= 1.0:

		Player.damage_base(1)

		if get_child_count() > 0:

			var enemy = get_child(0)

			if enemy is EnemyBase:

				if enemy.enemy_manager:
					enemy.enemy_manager.unregister_enemy(enemy)

		queue_free()
