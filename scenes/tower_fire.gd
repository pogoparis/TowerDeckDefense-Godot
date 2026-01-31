@tool
extends Node2D

# variable interne
var _level: int = 1

# variable visible dans l’inspecteur
@export var level: int = 1:
	set(value):
		_level = clamp(value, 1, 3)
		update_visual()
	get:
		return _level

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	update_visual()

func update_visual():
	if sprite == null:
		return

	match _level:
		1:
			sprite.texture = preload("res://assets/towers/tour_de_feu_1_128_comp.png")
		2:
			sprite.texture = preload("res://assets/towers/tour_de_feu_2_128.png")
		3:
			sprite.texture = preload("res://assets/towers/tour_de_feu_3_128.png")
