extends Node2D
class_name Phenomenon

@export var phenomenon_type: PhenomenonType.Type
@export var radius := 64.0
@export var duration := 5.0
@export var min_reaction_age := 1.5

const WATER_POOL_SCENE := preload(
	"res://scenes/phenomena/water_pool.tscn"
)

var contamination_timer := 0.0
const CONTAMINATION_INTERVAL := 0.5

var power := 1
var age := 0.0

var visual: Node2D = null

func _ready():

	create_visual()

func create_visual():

	match phenomenon_type:

		PhenomenonType.Type.WATER_POOL:

			visual = WATER_POOL_SCENE.instantiate()

			add_child(visual)
			visual.scale = Vector2.ONE

			update_visual_scale()

func update_visual_scale():

	if visual == null:
		return

	visual.scale = Vector2.ONE * (
		1.0 + (power - 1) * 0.15
	)


func refresh():

	age = 0.0

	power = min(power + 1, 5)

	radius = min(radius + 4.0, 96.0)
	duration = min(duration + 0.5, 12.0)

	update_visual_scale()


func _process(delta):

	age += delta

	contamination_timer -= delta

	if contamination_timer <= 0.0:

		contamination_timer = CONTAMINATION_INTERVAL

		apply_contamination()

		queue_redraw()

	if age >= duration:
		queue_free()


func get_status_id() -> String:

	match phenomenon_type:

		PhenomenonType.Type.WATER_POOL:
			return StatusIds.WET

		PhenomenonType.Type.ELECTRIC_FIELD:
			return StatusIds.CHARGED

		PhenomenonType.Type.FIRE_ZONE:
			return StatusIds.BURNING

		PhenomenonType.Type.THORN_PATCH:
			return StatusIds.ROOTED

		PhenomenonType.Type.WIND_CURRENT:
			return StatusIds.WINDMARK

	return ""


func apply_contamination():

	var enemy_manager := get_tree().get_first_node_in_group(
		"enemy_manager"
	)

	if enemy_manager == null:
		return

	var status_id := get_status_id()

	if status_id == "":
		return

	for enemy in enemy_manager.get_all_enemies():

		if not is_instance_valid(enemy):
			continue

		var distance_to_enemy := global_position.distance_to(
			enemy.global_position
		)

		if distance_to_enemy > radius:
			continue

		if not enemy.has_status(status_id):

			enemy.add_status(
				status_id,
				3.0
			)


func _draw():

	var fill_color := Color.WHITE
	var border_color := Color.WHITE

	match phenomenon_type:

		PhenomenonType.Type.WATER_POOL:
			fill_color   = Color(0.15, 0.45, 1.0,  0.30)
			border_color = Color(0.3,  0.7,  1.0,  0.85)

		PhenomenonType.Type.ELECTRIC_FIELD:
			fill_color   = Color(1.0,  0.95, 0.1,  0.25)
			border_color = Color(1.0,  1.0,  0.2,  0.90)

		PhenomenonType.Type.FIRE_ZONE:
			fill_color   = Color(1.0,  0.25, 0.0,  0.28)
			border_color = Color(1.0,  0.5,  0.0,  0.90)

		PhenomenonType.Type.THORN_PATCH:
			fill_color   = Color(0.1,  0.8,  0.1,  0.28)
			border_color = Color(0.2,  1.0,  0.2,  0.90)

		PhenomenonType.Type.WIND_CURRENT:
			fill_color   = Color(0.4,  0.9,  1.0,  0.22)
			border_color = Color(0.5,  1.0,  1.0,  0.85)

	# Fond semi-transparent
	draw_circle(Vector2.ZERO, radius, fill_color)

	# Contour pulsant selon l'âge
	var pulse := 1.0 + sin(age * 4.0) * 0.06
	var border_width := 3.0
	draw_arc(Vector2.ZERO, radius * pulse, 0.0, TAU, 48, border_color, border_width)
