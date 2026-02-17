extends CharacterBody2D

@export var hp := 30

func take_damage(amount):
	hp -= amount
	print("HP ennemi :", hp)
	if hp <= 0:
		queue_free()
