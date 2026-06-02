extends Node
class_name SynergyManager

@onready var tower_manager: TowerManager = $"../TowerManager"

var execution_froide_current := false

func recalculate_synergies():

	# ==============================
	# RESET
	# ==============================

	var execution_froide_found := false

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

		if tower.get_script().resource_path != "res://scripts/towers/tower_vega.gd":
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

			if neighbor is TowerGrumbolt:

				execution_froide_found = true

				tower.execution_froide_active = true
				neighbor.execution_froide_active = true

	# ==============================
	# ACTIVATION VISUELLE
	# ==============================

	if execution_froide_found and not execution_froide_current:

		print("EXECUTION FROIDE ACTIVE")

		var floating_text = preload(
			"res://scenes/ui/floating_text.tscn"
		).instantiate()

		get_tree().current_scene.add_child(floating_text)

		# On cherche une Vega active pour afficher le texte
		for tower in tower_manager.get_all_towers():

			if tower.get_script() == null:
				continue

			if tower.get_script().resource_path == "res://scripts/towers/tower_vega.gd":

				floating_text.global_position = tower.global_position
				break

		floating_text.setup("EXECUTION FROIDE !")

	execution_froide_current = execution_froide_found
