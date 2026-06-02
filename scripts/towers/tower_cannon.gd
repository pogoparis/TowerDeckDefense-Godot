extends BaseTower
class_name TowerCannon

@export var projectile_scene: PackedScene

@onready var area: Area2D = $DetectionArea
@onready var collision_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var effects_container: Node2D = $"../EffectsContainer"

var targets: Array = []

func _ready():

	super._ready()

	update_range_visual()

	if timer:
		timer.wait_time = fire_rate
		timer.timeout.connect(_on_timer_timeout)
		timer.start()

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.is_in_group("enemies"):
		targets.append(body)


func _on_body_exited(body):
	targets.erase(body)


func _on_timer_timeout():

	if is_ghost:
		return

	if projectile_scene == null:
		return

	targets = targets.filter(func(t): return is_instance_valid(t))

	if targets.is_empty():
		return

	var target = targets[0]

	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.target = target
	projectile.damage = damage

	get_parent().add_child(projectile)


func apply_upgrade(data: Dictionary):
	super.apply_upgrade(data)

	update_range_visual()

func _draw():

	if is_selected:
		draw_circle(Vector2.ZERO, attack_range, Color(0,1,0,0.25))

func update_range_visual():
	var shape = collision_shape.shape as CircleShape2D
	shape.radius = attack_range
	queue_redraw()
