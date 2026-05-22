extends CharacterBody2D

@export var max_hp := 30
var hp := 30

@onready var hp_fill = $HPBarContainer/HPFill

func _ready():

	hp = max_hp
	update_hp_bar()

func take_damage(amount):

	hp -= amount

	if hp < 0:
		hp = 0

	update_hp_bar()

	print("HP ennemi :", hp)

	if hp <= 0:
		queue_free()

func update_hp_bar():

	var ratio = float(hp) / float(max_hp)

	# largeur de la barre
	hp_fill.size.x = 40 * ratio

	# couleur dynamique
	if ratio > 0.6:
		hp_fill.color = Color(0.2, 1, 0.2)

	elif ratio > 0.3:
		hp_fill.color = Color(1, 0.7, 0.2)

	else:
		hp_fill.color = Color(1, 0.2, 0.2)
