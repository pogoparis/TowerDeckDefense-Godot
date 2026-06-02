extends Node
class_name SynergyManager

@onready var tower_manager: TowerManager = $"../TowerManager"
@onready var effects_container: Node2D = $"../World/EffectsContainer"

var execution_froide_current := false
var synergy_lines = []

func recalculate_synergies():

	# ==============================
	# RESET
	# ==============================

	var execution_froide_found := false

	for line in synergy_lines:
		if is_instance_valid(line):
			line.queue_free()

	synergy_lines.clear()

	for tower in tower_manager.get_all_towers():

		if not is_instance_valid(tower):
			continue

		tower.adjacency_damage_mult = 1.0
		tower.adjacency_range_mult = 1.0
		tower.execution_froide_active = false

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

	# ==============================
	# EXECUTION FROIDE
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

			execution_froide_found = true

			tower.execution_froide_active = true
			neighbor.execution_froide_active = true

			var line := Line2D.new()

			line.width = 8
			line.default_color = Color(0.2, 1.0, 1.0)
			line.z_index = 6																																							

			line.add_point(tower.global_position)
			line.add_point(neighbor.global_position)

			effects_container.add_child(line)

			synergy_lines.append(line)

			execution_pair_position = (
				tower.global_position +
				neighbor.global_position
			) / 2.0

	# ==============================
	# ACTIVATION VISUELLE
	# ==============================

	if execution_froide_found and not execution_froide_current:

		print("EXECUTION FROIDE ACTIVE")

		var floating_text = preload(
			"res://scenes/ui/floating_text.tscn"
		).instantiate()

		get_tree().current_scene.add_child(floating_text)

		execution_pair_position.y -= 40

		floating_text.global_position = execution_pair_position

		floating_text.setup(" TIRS GUIDÉS !")

	execution_froide_current = execution_froide_found
