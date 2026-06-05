extends Node2D
class_name EnemyBase

@onready var hp_fill: ColorRect = get_node_or_null("HPBarContainer/HPFill")

@export var max_hp := 30
@export var speed := 120.0
@export var scrap_reward := 5
@export var death_explosion_scene: PackedScene
@onready var enemy_manager: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")

var hp := 0
var slow_multiplier := 1.0
var slow_timer := 0.0
var status_effects: Dictionary = {}

func _ready():
	add_status("test", 3.0)

	if not hp_fill:
		push_error("HPFill introuvable dans " + str(name))
		return

	hp = max_hp

	update_hp_bar()

	if enemy_manager:
		enemy_manager.register_enemy(self)

func add_status(
	status_id: String,
	duration: float = 3.0
):

	if has_status(status_id):
		return

	status_effects[status_id] = duration
	
func remove_status(status_id: String):

	status_effects.erase(status_id)

func get_status_time(
	status_id: String
) -> float:

	if not status_effects.has(status_id):
		return 0.0

	return status_effects[status_id]

func has_status(status_id: String) -> bool:

	return (
		status_effects.has(status_id)
		and
		status_effects[status_id] > 0.0
	)



func take_damage(amount: int):

	hp -= amount

	if hp < 0:
		hp = 0

	update_hp_bar()

	if hp <= 0:
		die()

func update_hp_bar():

	if not hp_fill:
		return

	var ratio = float(hp) / float(max_hp)

	hp_fill.size.x = 40 * ratio

	if ratio > 0.6:
		hp_fill.color = Color(0.2, 1, 0.2)
	elif ratio > 0.3:
		hp_fill.color = Color(1, 0.7, 0.2)
	else:
		hp_fill.color = Color(1, 0.2, 0.2)

func apply_slow(multiplier: float, duration: float):

	slow_multiplier = multiplier
	slow_timer = duration

func _process(delta):

	update_statuses(delta)

	if slow_timer > 0:

		slow_timer -= delta

		if slow_timer <= 0:

			slow_multiplier = 1.0

func update_statuses(delta):

	var expired := []

	for status_id in status_effects.keys():

		status_effects[status_id] -= delta

		if status_effects[status_id] <= 0.0:

			expired.append(status_id)

	for status_id in expired:

		status_effects.erase(status_id)

func die():

	if death_explosion_scene:

		var explosion = death_explosion_scene.instantiate() as Node2D
		var effects = get_tree().current_scene.get_node("World/EffectsContainer")

		effects.add_child(explosion)

		explosion.global_position = global_position
		explosion.z_index = 100

		explosion.global_position = global_position

	if enemy_manager:
		enemy_manager.unregister_enemy(self)

	queue_free()
