extends Node
class_name SynergyManager

@onready var tower_manager: TowerManager = $"../TowerManager"
@onready var effects_container: Node2D = $"../World/EffectsContainer"

var laser_guide_found := false
var laser_guide_current := false

var synergy_lines = []

var active_execution_pairs := {}
var active_mama_pairs := {}

func recalculate_synergies():

	# ==============================
	# RESET
	# ==============================

	laser_guide_found = false

	for line in synergy_lines:

		if is_instance_valid(line):
			line.queue_free()

	synergy_lines.clear()

	for tower in tower_manager.get_all_towers():

		if not is_instance_valid(tower):
			continue

		tower.adjacency_damage_mult = 1.0
		tower.adjacency_range_mult = 1.0
		tower.laser_guide_active = false

		tower.set_buff_visual(false)

		tower.recalculate_stats()


	# ==============================
	# LASER GUIDE
	# ==============================

	var execution_pair_position: Vector2 = Vector2.ZERO

	for tower in tower_manager.get_all_towers():

		if not is_instance_valid(tower):
			continue

		if not tower is TowerVega:
			continue

		var adjacent_cells = [
			tower.grid_cell + Vector2i.LEFT,
			tower.grid_cell + Vector2i.RIGHT,
			tower.grid_cell + Vector2i.UP,
			tower.grid_cell + Vector2i.DOWN
		]

		for cell in adjacent_cells:

			var neighbor = tower_manager.get_tower_at_cell(cell)

			if neighbor == null:
				continue

			if not neighbor is TowerWaterCannon:
				continue

			laser_guide_found = true

			tower.laser_guide_active = true
			neighbor.laser_guide_active = true

			var pair_id = (
				str(tower.get_instance_id())
				+ "_"
				+ str(neighbor.get_instance_id())
			)

			if not active_execution_pairs.has(pair_id):

				active_execution_pairs[pair_id] = true

				FloatingTextService.spawn(
					get_tree().current_scene,
					(
						tower.global_position
						+ neighbor.global_position
					) / 2.0 + Vector2(0, -40),
					"TIRS GUIDÉS !"
				)

			var line := Line2D.new()

			line.width = 8
			line.default_color = Color(0.2, 1.0, 1.0)
			line.z_index = 6

			line.add_point(
				tower.global_position
			)

			line.add_point(
				neighbor.global_position
			)

			effects_container.add_child(line)

			synergy_lines.append(line)

			execution_pair_position = (
				tower.global_position
				+ neighbor.global_position
			) / 2.0
