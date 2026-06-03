extends Node
class_name WaveManager

@export var prep_time := 2
@export var waves: Array[WaveData]

@onready var card_manager: CardManager = $"../CardManager"

var wave_started := false
var current_wave_index := 0

var path: Path2D
var wave_timer_label: Label
var enemy_manager: EnemyManager
var tower_manager: TowerManager

const PATH_FOLLOW_SCRIPT = preload("res://scripts/core/path_follow_2d.gd")
const ENEMY_SCENE = preload("res://scenes/enemies/SimpleMob.tscn")

func start_prep_phase():

	wave_started = false
	for i in range(prep_time, 0, -1):
		wave_timer_label.text = "Wave in: " + str(i)
		await get_tree().create_timer(1.0).timeout
	wave_timer_label.text = "WAVE !"
	start_wave()

func setup(
	new_path: Path2D,
	new_wave_timer_label: Label,
	new_enemy_manager: EnemyManager,
	new_tower_manager: TowerManager
):
	
	tower_manager = new_tower_manager
	path = new_path
	wave_timer_label = new_wave_timer_label
	enemy_manager = new_enemy_manager

func start_wave():

	if wave_started:
		return

	wave_started = true

	if waves.is_empty():
		push_error("Aucune wave configurée")
		return

	if current_wave_index >= waves.size():

		wave_timer_label.text = "ALL WAVES CLEARED"
		return

	var wave_data = waves[current_wave_index]

	Player.set_wave(current_wave_index + 1)
	await spawn_wave_data(wave_data)

	await wait_for_wave_clear()

	RewardManager.show_rewards()

	while not RewardManager.reward_selected:
		await get_tree().process_frame

	start_prep_phase()


func spawn_wave_data(wave_data: WaveData) -> void:

	spawn_wave(
		wave_data.enemy_count,
		wave_data.spawn_interval,
		wave_data.enemy_speed,
		wave_data.enemy_scene
	)


func spawn_wave(
	count: int,
	interval: float,
	speed_override: float,
	enemy_scene: PackedScene
):

	if not path:
		return

	for i in range(count):

		var pf = _spawn_enemy_instance(enemy_scene)

		if pf:

			if speed_override > 0:
				pf.speed = speed_override

			path.add_child(pf)

			pf.progress = 0

		await get_tree().create_timer(interval).timeout


# ==============================
#        ENEMY SPAWN
# ==============================

func _spawn_enemy_instance(enemy_scene: PackedScene) -> PathFollow2D:

	if not enemy_scene:

		push_error("enemy_scene est null")
		return null

	var pf := PathFollow2D.new()

	pf.set_script(PATH_FOLLOW_SCRIPT)

	pf.rotates = false
	pf.loop = false
	pf.visible = true

	var enemy := enemy_scene.instantiate() as EnemyBase

	if not enemy:

		push_error("Impossible d'instancier enemy_scene")
		return null

	pf.add_child(enemy)

	return pf
	
func wait_for_wave_clear():

	while enemy_manager.get_all_enemies().size() > 0:
		await get_tree().process_frame

	Player.add_caps(3)

	card_manager.draw_until_full_hand()

	get_tree().current_scene.refresh_hand_ui()

	current_wave_index += 1
