extends Node2D
class_name EnemyBase

@export var max_hp := 30
@export var speed := 120.0
@export var scrap_reward := 5

var hp := 0

func _ready():
	hp = max_hp

func take_damage(amount: int):

	hp -= amount

	if hp <= 0:
		die()

func die():

	EconomyManager.add_scrap(scrap_reward)

	queue_free()
