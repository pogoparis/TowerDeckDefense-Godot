extends Node
class_name EnemyManager

signal enemy_leaked

var enemies: Array = []

func register_enemy(enemy: Node2D):
	if enemy not in enemies:
		enemies.append(enemy)

func unregister_enemy(enemy: Node2D):
	enemies.erase(enemy)

func notify_leak():
	enemy_leaked.emit()

func get_all_enemies() -> Array:
	return enemies
