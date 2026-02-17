extends CharacterBody2D

@export var hp := 30

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		queue_free()
