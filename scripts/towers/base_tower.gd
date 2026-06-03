extends Node2D
class_name BaseTower

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

enum TowerFamily {
	IRONCLAD,
	SPARK,
	GHOST
}

# ==============================
#          STATS BASE
# ==============================

@export var base_damage: int = 10
@export var base_fire_rate: float = 0.8
@export var base_range: float = 120.0
@export var family: TowerFamily
@export var tower_tags: Array[String] = []

# ==============================
#        STATS ACTUELLES
# ==============================
var is_ghost := false
var damage: int
var fire_rate: float
var attack_range: float
var enemy_manager: EnemyManager
var grid_cell: Vector2i
var tower_manager
var adjacency_damage_mult := 1.0
var adjacency_range_mult := 1.0
var status_effects: Dictionary = {}
var laser_guide_active := false
var buff_visual_active := false
var was_buffed := false

# ==============================
#            NODES
# ==============================
@onready var halo_sprite: Sprite2D = get_node_or_null("HaloSprite")
@onready var timer: Timer = get_node_or_null("Timer")
@onready var sprite_material := sprite.material

# ==============================
#            READY
# ==============================

func _ready():

	damage = base_damage
	fire_rate = base_fire_rate
	attack_range = base_range

	add_to_group("towers")

	apply_run_bonuses()

	if sprite and sprite.material:

		sprite.material = sprite.material.duplicate()

		sprite_material = sprite.material

	if sprite_material:

		sprite_material.set_shader_parameter(
			"outline_size",
			0.0
		)

	if timer:
		timer.wait_time = fire_rate
	

# ==============================
#       APPLY UPGRADE
# ==============================
func apply_upgrade(data: Dictionary):
	damage += data.get("damage", 0)
	attack_range += data.get("range", 0)

	var fire_mult: float = data.get("fire_rate_mult", 1.0)
	fire_rate *= fire_mult

	if timer:
		timer.wait_time = fire_rate
		timer.stop()
		timer.start()
		update_visual_feedback()

func get_outline_size() -> float:
	return 4.0

func set_buff_visual(active: bool):

	buff_visual_active = active
	print(
	get_script().get_global_name(),
	" OUTLINE=",
	active
)
	print(
	name,
	" OUTLINE=",
	active
)
	if sprite_material == null:
		return

	if active:
		sprite_material.set_shader_parameter(
			"outline_size",
			4
		)
	else:
		sprite_material.set_shader_parameter(
			"outline_size",
			0.0
		)

func find_target() -> Node2D:

	if not enemy_manager:
		return null

	var enemies = enemy_manager.get_all_enemies()

	var valid_target: Node2D = null

	for enemy in enemies:

		if not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)

		if dist <= attack_range:

			valid_target = enemy
			break

	return valid_target
	
# ==============================
#          SELECTION
# ==============================

var is_selected := false

func set_selected(value: bool):

	is_selected = value
	queue_redraw()


func find_target_with_status(status_id: String) -> Node2D:

	if not enemy_manager:
		return null

	for enemy in enemy_manager.get_all_enemies():

		if not is_instance_valid(enemy):
			continue

		if not enemy.has_status(status_id):
			continue

		var dist = global_position.distance_to(enemy.global_position)

		if dist <= attack_range:
			return enemy

	return null

# ==============================
#        VISUAL FEEDBACK
# ==============================

func update_visual_feedback():
	pass

func disable_behaviors():

	if timer:
		timer.stop()

func apply_run_bonuses():

	damage = base_damage
	attack_range = base_range
	fire_rate = base_fire_rate

	for bonus in RunBonuses.owned_bonuses:
		damage += bonus.damage_bonus
		attack_range += bonus.range_bonus
		fire_rate *= bonus.fire_rate_mult


	if timer:
		timer.wait_time = fire_rate

func add_status(status_id: String):
	status_effects[status_id] = true

func remove_status(status_id: String):
	status_effects.erase(status_id)

func has_status(status_id: String) -> bool:
	return status_effects.has(status_id)

func recalculate_stats():

	apply_run_bonuses()

	damage = int(damage * adjacency_damage_mult)
	attack_range = attack_range * adjacency_range_mult
