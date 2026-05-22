extends EnemyBase

@onready var hp_fill = $HPBarContainer/HPFill

func _process(delta):
	update_hp_bar()

func update_hp_bar():

	var ratio = float(hp) / float(max_hp)

	hp_fill.size.x = 40 * ratio

	if ratio > 0.6:
		hp_fill.color = Color(0.2, 1, 0.2)

	elif ratio > 0.3:
		hp_fill.color = Color(1, 0.7, 0.2)

	else:
		hp_fill.color = Color(1, 0.2, 0.2)
