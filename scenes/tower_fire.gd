class_name TowerFire
extends Node2D

@export var fire_rate := 0.8
@export var damage := 10
@export var attack_range := 60.0
@export var projectile_scene: PackedScene

@onready var area: Area2D = $DetectionArea
@onready var timer: Timer = $Timer

var targets: Array = []

func _draw():
	# Pivot réel
	draw_circle(Vector2.ZERO, 6, Color.RED)

	# Petit repère croix
	draw_line(Vector2(-10, 0), Vector2(10, 0), Color.RED, 2)
	draw_line(Vector2(0, -10), Vector2(0, 10), Color.RED, 2)

func _ready():
	# Portée
	var shape := CircleShape2D.new()
	shape.radius = attack_range
	$DetectionArea/CollisionShape2D.shape = shape

	# Timer
	timer.wait_time = fire_rate
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

	# Détection
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	queue_redraw()


func _on_body_entered(body):
	if body.is_in_group("enemies"):
		targets.append(body)
		print("👀 Ennemi détecté :", body.name)


func _on_body_exited(body):
	targets.erase(body)


func _on_timer_timeout():
	# Si ghost ou mal initialisée
	if projectile_scene == null:
		return

	if targets.is_empty():
		return

	var target = targets[0]

	if not is_instance_valid(target):
		return

	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.target = target
	projectile.damage = damage

	get_parent().add_child(projectile)


func disable_behaviors():
	process_mode = Node.PROCESS_MODE_DISABLED
	set_process(false)
	set_physics_process(false)

	if area:
		area.monitoring = false
		area.monitorable = false

	if timer:
		timer.stop()

	projectile_scene = null
