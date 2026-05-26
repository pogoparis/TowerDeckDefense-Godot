extends Node

@export var prep_time := 2

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

	pf.add_child(enemy)

	return pf

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
