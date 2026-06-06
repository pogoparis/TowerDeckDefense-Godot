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

	if phenomenon_type == PhenomenonType.Type.WATER_POOL:
		return

	var color := Color.WHITE

	match phenomenon_type:

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
