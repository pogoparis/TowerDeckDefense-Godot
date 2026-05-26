extends Node
class_name TowerManager

var selected_tower: BaseTower = null
var tower_container: Node2D

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
	
func handle_left_click(mouse_world: Vector2) -> bool:

	return try_select_tower(mouse_world)
	
func handle_right_click():

	deselect_current_tower()

func select_tower(tower: BaseTower):

	if selected_tower:
		selected_tower.set_selected(false)

	selected_tower = tower

	if selected_tower:
		selected_tower.set_selected(true)
		
		
		
func handle_input(event, mouse_world: Vector2) -> bool:

	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_RIGHT:

			handle_right_click()

			return true

		if event.button_index == MOUSE_BUTTON_LEFT:

			return handle_left_click(mouse_world)

	return false
	
func deselect_current_tower():

	if selected_tower:
		selected_tower.set_selected(false)

	selected_tower = null
	
