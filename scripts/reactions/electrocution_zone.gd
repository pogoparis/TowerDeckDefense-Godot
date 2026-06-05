extends ReactionEffect
class_name ElectrocutionZone

func _ready():

	radius = 96.0
	duration = 4.0
	tick_rate = 0.4
	damage = 20


func _draw():

	draw_circle(
		Vector2.ZERO,
		radius,
		Color(1.0, 1.0, 0.0, 0.35)
	)

	draw_arc(
		Vector2.ZERO,
		radius,
		0,
		TAU,
		32,
		Color.YELLOW,
		3.0
	)
