extends BaseTower
class_name TowerMamaCog

@export var damage_bonus_mult := 1.3
@export var range_bonus_mult := 1.3

var buffed_towers: Array[BaseTower] = []

func _ready():

	super()
	

func update_aura():
	print("=== MAMA COG UPDATE ===")
	print("my cell = ", grid_cell)
	if tower_manager == null:
		return

	for tower in buffed_towers:

		if is_instance_valid(tower):

			tower.adjacency_damage_mult = 1.3
			tower.recalculate_stats()

	buffed_towers.clear()

	var adjacent_cells = [
		grid_cell + Vector2i.LEFT,
		grid_cell + Vector2i.RIGHT,
		grid_cell + Vector2i.UP,
		grid_cell + Vector2i.DOWN
	]

	for cell in adjacent_cells:

		print("checking cell ", cell)
		var tower = tower_manager.get_tower_at_cell(cell)
		print("found tower = ", tower)
		
		if tower == null:
			continue

		if tower == self:
			continue

		tower.damage = int(tower.base_damage * damage_bonus_mult)
		print("BUFFING ", tower)
		buffed_towers.append(tower)

		print(
			"Mama Cog buff -> ",
			tower.grid_cell,
			" damage=",
			tower.damage
		)
