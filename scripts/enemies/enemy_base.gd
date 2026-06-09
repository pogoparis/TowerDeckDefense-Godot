extends Node2D
class_name EnemyBase

@export var max_hp := 30
@export var speed := 120.0
@export var scrap_reward := 5
@export var death_explosion_scene: PackedScene

@onready var enemy_manager: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")
@onready var status_icons: StatusIconContainer = $StatusIcons
@onready var hp_fill: ColorRect = get_node_or_null("HPBarContainer/HPFill")

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

	if status_icons:
		status_icons.update_statuses(
			status_effects
		)
	
func remove_status(status_id: String):

	status_effects.erase(status_id)

	if status_icons:
		status_icons.update_statuses(
			status_effects
		)

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


func apply_knockback(force: float):
	var pf := get_parent()
	if not (pf is PathFollow2D):
		return

	# Recul progressif : tween sur le progress pour éviter la téléportation
	var target_progress: float = max(0.0, pf.progress - force)
	var tween := create_tween()
	tween.tween_property(pf, "progress", target_progress, 0.4)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	# Shake du visuel pendant le recul
	_shake_visual(0.4)

func _shake_visual(duration: float):
	var visual := get_node_or_null("VisualRoot")
	if not visual:
		return

	var origin: Vector2 = visual.position
	var shake_tween := create_tween()

	# Oscille rapidement en X (recul ressenti)
	var steps := 6
	for i in steps:
		var t: float = float(i) / steps
		var strength: float = lerp(14.0, 0.0, t)   # décroît avec le temps
		var offset_x: float = strength * (-1.0 if i % 2 == 0 else 1.0)
		var offset_y: float = randf_range(-strength * 0.3, strength * 0.3)
		shake_tween.tween_property(visual, "position",
			origin + Vector2(offset_x, offset_y),
			duration / steps
		).set_trans(Tween.TRANS_SINE)

	# Retour en position initiale
	shake_tween.tween_property(visual, "position", origin, 0.05)


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
	
	if expired.size() > 0 and status_icons:

		status_icons.update_statuses(
			status_effects
		)
	
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
