extends BaseTower
class_name ProjectileTower

@export var projectile_scene: PackedScene
## Son joué à chaque tir — assigné dans la scène de chaque tour.
@export var shot_sound: AudioStream
## Volume du tir en décibels (0 = volume du fichier, négatif = plus faible).
@export var shot_volume_db: float = -10.0
@onready var shoot_point: Marker2D = $ShootPoint

func _ready():

	if is_ghost:
		return

	super._ready()

	if timer:
		timer.wait_time = fire_rate
		timer.timeout.connect(_on_timer_timeout)
		timer.start()

func _on_timer_timeout():

	if projectile_scene == null:
		return
	var valid_target = find_target()

	if valid_target == null:
		reset_aim()
		return

	fire_projectile(valid_target)

func fire_projectile(target: Node2D):

	face_target(target.global_position)
	play_fire_frame()
	Audio.play_sfx(shot_sound, shot_volume_db, 0.12)

	var projectile = projectile_scene.instantiate()

	projectile.global_position = shoot_point.global_position
	projectile.target = target
	projectile.damage = damage
	projectile.source_tower = self

	get_parent().add_child(projectile)
