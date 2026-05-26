extends Node
class_name TowerManager

var selected_tower: BaseTower = null

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
	
