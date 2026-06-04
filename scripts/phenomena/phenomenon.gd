extends Node2D
class_name Phenomenon

@export var phenomenon_type: PhenomenonType.Type
@export var radius := 64.0
@export var duration := 5.0

var power := 1
var age := 0.0

func refresh():

	age = 0.0

	power += 1

	radius += 4.0

	duration += 0.5


func _process(delta):

	age += delta

	queue_redraw()

	if age >= duration:
		queue_free()


func _draw():

	var color := Color.WHITE

	match phenomenon_type:

		PhenomenonType.Type.WATER_POOL:
			color = Color.CORNFLOWER_BLUE

		PhenomenonType.Type.ELECTRIC_FIELD:
			color = Color.YELLOW

		PhenomenonType.Type.FIRE_ZONE:
			color = Color.ORANGE_RED

		PhenomenonType.Type.THORN_PATCH:
			color = Color.LIME_GREEN

		PhenomenonType.Type.WIND_CURRENT:
			color = Color.CYAN

	draw_circle(
		Vector2.ZERO,
		radius,
		color
	)
