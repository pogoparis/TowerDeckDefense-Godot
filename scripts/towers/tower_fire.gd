extends base_tower
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
	sprite.modulate = Color(1,1,1,1)
	print("Sprite alpha:", sprite.modulate.a)
	print("Visible:", sprite.visible)
	print("Scale:", sprite.scale)
	print("Z index:", sprite.z_index)
	upgrade_data = {
		2: { "damage": 5, "range": 15, "fire_rate_mult": 0.9, "cost": 50 },
		3: { "damage": 10, "range": 25, "fire_rate_mult": 0.8, "cost": 100 }
	}
	print("Area pos:", $DetectionArea.position)
	print("Shape pos:", $DetectionArea/CollisionShape2D.position)
	
	super._ready()
	update_range_visual()

	# --- Timer ---
	if timer:
		timer.wait_time = fire_rate
		timer.timeout.connect(_on_timer_timeout)
		timer.start()

	# --- Détection ---
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	queue_redraw()

# ==============================
#         DETECTION
# ==============================

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		print("Distance entrée :", global_position.distance_to(body.global_position))
		print("Radius shape :", $DetectionArea/CollisionShape2D.shape.radius)
		targets.append(body)

func _on_body_exited(body):
	targets.erase(body)

var show_range := false

func _draw():

	if is_selected:
		draw_circle(Vector2.ZERO, attack_range, Color(0,1,0,0.25))

func _refresh_targets():
	targets.clear()

	for body in area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			targets.append(body)

# ==============================
#            TIR
# ==============================

func _on_timer_timeout():
	if projectile_scene == null:
		return

	targets = targets.filter(func(t): return is_instance_valid(t))

	if targets.is_empty():
		return

	var valid_target: Node2D = null

	for t in targets:
		var dist = global_position.distance_to(t.global_position)
		if dist <= attack_range:
			valid_target = t
			break

	if valid_target == null:
		return

	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.target = valid_target
	projectile.damage = damage
	get_parent().add_child(projectile)

	# ==============================
	#    UPDATE VISUEL SI UPGRADE
	# ==============================

func apply_upgrade(data: Dictionary):
		print("APPLY UPGRADE FIRE")
		
		super.apply_upgrade(data)
		update_range_visual()

		# Changement visuel selon niveau
		if level_textures.has(level):
			sprite.texture = level_textures[level]
			print("LEVEL:", level)
			print("Damage:", damage)
			print("Range:", attack_range)
			print("Fire rate:", fire_rate)

	
func disable_behaviors():
	super.disable_behaviors()

	if area:
		area.monitoring = false
		area.monitorable = false

	projectile_scene = null

func update_range_visual():
	var shape = $DetectionArea/CollisionShape2D.shape as CircleShape2D
	shape.radius = attack_range
	queue_redraw()
