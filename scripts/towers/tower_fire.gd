extends BaseTower
class_name TowerFire

@export var projectile_scene: PackedScene
@onready var sprite: Sprite2D = $Sprite2D

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
		
	if not enemy_manager:
		return
	var enemies = enemy_manager.get_all_enemies()

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
	
	queue_redraw()
