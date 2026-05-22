extends Node2D
class_name base_tower

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

# ==============================
#          UPGRADE
# ==============================

var level: int = 1
var max_level: int = 3

# Format attendu :
# {
#   2: { "damage": 5, "range": 20, "fire_rate_mult": 0.9, "cost": 50 },
#   3: { "damage": 10, "range": 40, "fire_rate_mult": 0.8, "cost": 100 }
# }
var upgrade_data: Dictionary = {}

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
#           UPGRADE
# ==============================

func upgrade() -> bool:
	if level >= max_level:
		print("Tour déjà au niveau max")
		return false

	var next_level := level + 1
	var data: Dictionary = upgrade_data.get(next_level)

	if data.is_empty():
		print("Pas de données pour le niveau ", next_level)
		return false

	var cost: int = data.get("cost", 0)

	if not GameManager.spend_gold(cost):
		print("Pas assez d'or")
		return false

	level = next_level
	apply_upgrade(data)

	print("Upgrade réussi → niveau ", level)
	return true

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
	process_mode = Node.PROCESS_MODE_DISABLED
	set_process(false)
	set_physics_process(false)

	if timer:
		timer.stop()
