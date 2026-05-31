extends Node
class_name TowerManager

var selected_tower: BaseTower = null
var tower_container: Node2D
var towers: Array[BaseTower] = []
signal towers_changed


func setup(new_tower_container: Node2D):

	tower_container = new_tower_container

# ==============================
#        TOWER REGISTRY
# ==============================

func register_tower(tower):
	towers.append(tower)
	towers_changed.emit()

func unregister_tower(tower):
	towers.erase(tower)
	towers_changed.emit()

func get_all_towers() -> Array[BaseTower]:

	return towers

func get_tower_at_cell(cell: Vector2i) -> BaseTower:

	for tower in towers:

		if not is_instance_valid(tower):
			continue

		if tower.grid_cell == cell:
			return tower

	return null

# ==============================
#        TOWER CREATION
# ==============================

func create_tower(
	tower_scene: PackedScene,
	world_position: Vector2,
	enemy_manager: EnemyManager
) -> BaseTower:

	if not tower_container:
		return null

	var tower = tower_scene.instantiate() as BaseTower

	tower.is_ghost = false
	tower.enemy_manager = enemy_manager
	tower.tower_manager = self
	
	tower.position = tower_container.to_local(world_position)
	tower.modulate = Color(1,1,1,1)

	tower_container.add_child(tower)

	register_tower(tower)

	return tower


# ==============================
#        INPUT
# ==============================

func handle_input(event, mouse_world: Vector2) -> bool:

	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_RIGHT:

			handle_right_click()

			return true

		if event.button_index == MOUSE_BUTTON_LEFT:

			return handle_left_click(mouse_world)

	return false

func handle_left_click(mouse_world: Vector2) -> bool:

	return try_select_tower(mouse_world)

func handle_right_click():

	deselect_current_tower()

func try_select_tower(mouse_world: Vector2) -> bool:

	if not tower_container:
		return false

	for tower in tower_container.get_children():

		if tower is BaseTower:

			if tower.is_ghost:
				continue

			if mouse_world.distance_to(tower.global_position) < 48:

				select_tower(tower)

				return true

	deselect_current_tower()

	return false

func select_tower(tower: BaseTower):

	if selected_tower:
		selected_tower.set_selected(false)

	selected_tower = tower

	if selected_tower:
		selected_tower.set_selected(true)

func deselect_current_tower():

	if selected_tower:
		selected_tower.set_selected(false)

	selected_tower = null

func apply_bonus_to_all_towers(bonus: BonusData):

	for tower in towers:

		if not is_instance_valid(tower):
			continue
		print("BUFFING TOWER: ", tower.damage)
		tower.apply_upgrade({
			"damage": bonus.damage_bonus,
			"range": bonus.range_bonus,
			"fire_rate_mult": bonus.fire_rate_mult
		})
