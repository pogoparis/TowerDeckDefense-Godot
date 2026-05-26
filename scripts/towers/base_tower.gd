extends Node2D
class_name BaseTower

# ==============================
#          STATS BASE
# ==============================

@export var base_damage: int = 10
@export var base_fire_rate: float = 0.8
@export var base_range: float = 120.0

# ==============================
#        STATS ACTUELLES
# ==============================
var is_ghost := false
var damage: int
var fire_rate: float
var attack_range: float
var enemy_manager: EnemyManager

# ==============================
#            NODES
# ==============================

@onready var timer: Timer = get_node_or_null("Timer")

# ==============================
#            READY
# ==============================

func _ready():
	damage = base_damage
	fire_rate = base_fire_rate
	attack_range = base_range

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

# ==============================
#          SELECTION
# ==============================

var is_selected := false

func set_selected(value: bool):

	is_selected = value
	queue_redraw()

# ==============================
#        VISUAL FEEDBACK
# ==============================

func update_visual_feedback():
	pass

func disable_behaviors():

	if timer:
		timer.stop()
