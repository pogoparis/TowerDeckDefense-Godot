extends Node
class_name SynergyManager

@onready var tower_manager: TowerManager = $"../TowerManager"

func recalculate_synergies():

	for tower in tower_manager.get_all_towers():

		if not is_instance_valid(tower):
			continue

		tower.adjacency_damage_mult = 1.0
		tower.adjacency_range_mult = 1.0
		tower.recalculate_stats()

	for tower in tower_manager.get_all_towers():

		if not is_instance_valid(tower):
			continue

		if tower.get_script().resource_path != "res://scripts/towers/tower_mama_cog.gd":
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

			neighbor.adjacency_damage_mult = tower.damage_bonus_mult
			neighbor.recalculate_stats()
