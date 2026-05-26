extends BaseTower
class_name TowerFire

@export var projectile_scene: PackedScene
@onready var collision_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var area: Area2D = $DetectionArea
@onready var sprite: Sprite2D = $Sprite2D

var level_textures := {
	2: preload("res://assets/towers/tour_de_feu_2_128_min2.png"),
	3: preload("res://assets/towers/tour_de_feu_3_128_min3.png")
}

var targets: Array = []

# ==============================
#            READY
# ==============================

func _ready():
	print("Tower ready")

	print("Monitoring =", area.monitoring)
	print("Mask =", area.collision_mask)

	if is_ghost:
		return
	sprite.modulate = Color(1,1,1,1)
	super._ready()
	update_range_visual()

	# --- Timer ---
	if timer:
		timer.wait_time = fire_rate
		timer.timeout.connect(_on_timer_timeout)
		timer.start()

	queue_redraw()

	for body in area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			targets.append(body)

# ==============================
#            TIR
# ==============================

func _on_timer_timeout():

	if projectile_scene == null:
		return

	var enemies = get_tree().get_nodes_in_group("enemies")

	var valid_target: Node2D = null

	for enemy in enemies:

		if not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)

		if dist <= attack_range:
			valid_target = enemy
			break

	if valid_target == null:
		return

	var projectile = projectile_scene.instantiate()

	projectile.global_position = global_position
	projectile.target = valid_target
	projectile.damage = damage

	get_parent().add_child(projectile)


func update_range_visual():
	
	var shape = $DetectionArea/CollisionShape2D.shape as CircleShape2D
	print(shape)
	print(shape.radius)
	shape.radius = attack_range
	queue_redraw()

func _process(_delta):

	print(area.get_overlapping_bodies().size())
