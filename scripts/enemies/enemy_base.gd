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
	queue_redraw()
	if hp <= 0:
		die()

func die():

	EconomyManager.add_scrap(scrap_reward)

	queue_free()

func _draw():

	var width := 32.0
	var height := 5.0

	var ratio = float(hp) / float(max_hp)

	# fond rouge
	draw_rect(
		Rect2(-width * 0.5, -40, width, height),
		Color(0.4, 0, 0)
	)

	# vie verte
	draw_rect(
		Rect2(-width * 0.5, -40, width * ratio, height),
		Color(0, 1, 0)
	)
