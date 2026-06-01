extends Node
class_name SynergyManager

@onready var tower_manager: TowerManager = $"../TowerManager"

func recalculate_synergies():

	# ==============================
	# RESET
	# ==============================

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
	# Vega + Grumbolt
	# ==============================

	for tower in tower_manager.get_all_towers():

		if not is_instance_valid(tower):
			continue

		if tower.get_script() == null:
			continue

		print(
			"TOWER SCRIPT = ",
			tower.get_script().resource_path
		)
		print("FOUND VEGA ", tower.grid_cell)

		if tower.get_script().resource_path != "res://scripts/towers/tower_vega.gd":
			continue
			
		var adjacent_cells = [
			tower.grid_cell + Vector2i.LEFT,
			tower.grid_cell + Vector2i.RIGHT,
			tower.grid_cell + Vector2i.UP,
			tower.grid_cell + Vector2i.DOWN
		]

		for cell in adjacent_cells:
			print("CHECK CELL ", cell)

			var neighbor = tower_manager.get_tower_at_cell(cell)

			print("NEIGHBOR = ", neighbor)

			if neighbor == null:
				continue

			if neighbor is TowerGrumbolt:
				print("GRUMBOLT FOUND")

				tower.execution_froide_active = true
				neighbor.execution_froide_active = true

				print("EXECUTION FROIDE ACTIVE")
