extends Node
class_name WaveManager

@export var prep_time := 2

var wave_started := false

var path: Path2D
var wave_timer_label: Label
var enemy_manager: EnemyManager

const PATH_FOLLOW_SCRIPT = preload("res://scripts/core/path_follow_2d.gd")
const ENEMY_SCENE = preload("res://scenes/enemies/SimpleMob.tscn")

func start_prep_phase():

	wave_started = false
	for i in range(prep_time, 0, -1):
		wave_timer_label.text = "Wave in: " + str(i)
		await get_tree().create_timer(1.0).timeout
	wave_timer_label.text = "WAVE !"
	start_wave()
	
func start_wave():
	if wave_started:
		return
	wave_started = true
	spawn_wave(20, 1.5, 70.0)

# ==============================
#        ENEMY SPAWN
# ==============================
func _spawn_enemy_instance() -> PathFollow2D:

	var pf := PathFollow2D.new()

	pf.set_script(PATH_FOLLOW_SCRIPT)

	pf.rotates = false
	pf.loop = false
	pf.visible = true

	var enemy = ENEMY_SCENE.instantiate()
	enemy_manager.register_enemy(enemy)
	enemy.enemy_manager = enemy_manager
	
	pf.add_child(enemy)

	return pf

func setup(
	new_path: Path2D,
	new_wave_timer_label: Label,
	new_enemy_manager: EnemyManager
):

	path = new_path
	wave_timer_label = new_wave_timer_label
	enemy_manager = new_enemy_manager

func spawn_wave(count: int, interval: float, speed_override: float = -1.0):

	if not path:
		return

	for i in range(count):

		var pf = _spawn_enemy_instance()

		if pf:
			if speed_override > 0:
				pf.speed = speed_override

			path.add_child(pf)
			pf.progress = 0

		await get_tree().create_timer(interval).timeout
