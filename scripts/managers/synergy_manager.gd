extends Node
class_name SynergyManager

@onready var tower_manager: TowerManager = $"../TowerManager"
@onready var effects_container: Node2D = $"../World/EffectsContainer"

var synergy_lines = []

var active_mama_pairs := {}

func recalculate_synergies():

	# ==============================
	# RESET
	# ==============================

	for line in synergy_lines:

		if is_instance_valid(line):
			line.queue_free()

	synergy_lines.clear()

	for tower in tower_manager.get_all_towers():

		if not is_instance_valid(tower):
			continue

		tower.adjacency_damage_mult = 1.0
		tower.adjacency_range_mult = 1.0

		tower.set_buff_visual(false)

		tower.recalculate_stats()
