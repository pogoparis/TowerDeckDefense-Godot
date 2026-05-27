extends BaseTower
class_name TowerFire

@export var projectile_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_point: Marker2D = $ShootPoint

# ==============================
#            READY
# ==============================

func _ready():

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

# ==============================
#            TIR
# ==============================

func _on_timer_timeout():

	if projectile_scene == null:
		return
	
	var valid_target = find_target()

	if valid_target == null:
		return

	var projectile = projectile_scene.instantiate()

	projectile.global_position = shoot_point.global_position
	projectile.target = valid_target
	projectile.damage = damage

	get_parent().add_child(projectile)


func update_range_visual():
	
	queue_redraw()
