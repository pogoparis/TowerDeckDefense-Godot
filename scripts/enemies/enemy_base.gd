extends Node2D
class_name EnemyBase

@onready var hp_fill: ColorRect = get_node_or_null("HPBarContainer/HPFill")

@export var max_hp := 30
@export var speed := 120.0
@export var scrap_reward := 5
@export var death_explosion_scene: PackedScene

var hp := 0
@onready var enemy_manager: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")

func _ready():

	if not hp_fill:
		push_error("HPFill introuvable dans " + str(name))
		return

	hp = max_hp

	update_hp_bar()

	if enemy_manager:
		enemy_manager.register_enemy(self)
	

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

func die():

	if death_explosion_scene:

		var explosion = death_explosion_scene.instantiate() as Node2D
		var effects = get_tree().current_scene.get_node("World/EffectsContainer")

		effects.add_child(explosion)

		explosion.global_position = global_position
		explosion.z_index = 100

		explosion.global_position = global_position

	EconomyManager.add_scrap(scrap_reward)

	if enemy_manager:
		enemy_manager.unregister_enemy(self)

	queue_free()
