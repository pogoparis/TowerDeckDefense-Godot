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

	var laser_guide_found := false

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
	# MAMA COG
	# ==============================

	for tower in tower_manager.get_all_towers():

		if not is_instance_valid(tower):
			continue

		if not tower is TowerMamaCog:
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

			if neighbor == tower:
				continue

			neighbor.adjacency_damage_mult = tower.damage_bonus_mult
			neighbor.recalculate_stats()

			var pair_id = (
				str(tower.get_instance_id())
				+ "_"
				+ str(neighbor.get_instance_id())
			)

			neighbor.set_buff_visual(true)

			if not active_mama_pairs.has(pair_id):

				active_mama_pairs[pair_id] = true

				var floating_text = preload(
					"res://scenes/ui/floating_text.tscn"
				).instantiate()

				get_tree().current_scene.add_child(
					floating_text
				)

				floating_text.global_position = (
					neighbor.global_position
					+ Vector2(0, -40)
				)

				floating_text.setup(
					"+10% DAMAGE",
					Color("#FFD54A"),
					1.4
				)
			
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

			if not neighbor is TowerGrumbolt:
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

				var floating_text = preload(
					"res://scenes/ui/floating_text.tscn"
				).instantiate()

				get_tree().current_scene.add_child(
					floating_text
				)

				floating_text.global_position = (
					tower.global_position
					+ neighbor.global_position
				) / 2.0

				floating_text.global_position.y -= 40

				floating_text.setup("TIRS GUIDÉS !")

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
