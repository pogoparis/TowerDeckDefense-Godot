extends PathFollow2D

@export var speed := 120.0

var _reached_end := false

func _physics_process(delta):

	if get_child_count() == 0:
		return

	# La vitesse vient UNIQUEMENT de la scène du mob (EnemyBase.speed),
	# lue en direct pour que les changements runtime (ex : TankMob en roulade)
	# soient pris en compte. `speed` ne sert que de fallback.
	var final_speed = speed

	if get_child_count() > 0:
		var enemy = get_child(0)
		if enemy is EnemyBase:
			final_speed = enemy.speed * enemy.slow_multiplier

	progress += final_speed * delta

	if progress_ratio >= 1.0 and not _reached_end:
		_reached_end = true

		var dmg := 1
		if get_child_count() > 0:
			var enemy = get_child(0)
			if enemy is EnemyBase:
				dmg = enemy.leak_damage
				if enemy.enemy_manager:
					enemy.enemy_manager.unregister_enemy(enemy)
					enemy.enemy_manager.notify_leak()

		Player.damage_base(dmg)
		queue_free()
