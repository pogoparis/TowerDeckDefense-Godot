extends Node

var owned_bonuses: Array[BonusData] = []

func add_bonus(bonus: BonusData):

	if bonus == null:
		push_error("BONUS IS NULL")
		return

	owned_bonuses.append(bonus)

	print("BONUS ADDED: ", bonus.title)

	refresh_all_towers()

func get_total_damage_bonus() -> int:

	var total := 0

	for bonus in owned_bonuses:
		total += bonus.damage_bonus

	return total
	
func get_total_range_bonus() -> int:

	var total := 0

	for bonus in owned_bonuses:
		total += bonus.range_bonus

	return total
	
func get_fire_rate_multiplier() -> float:

	var mult := 1.0

	for bonus in owned_bonuses:
		mult *= bonus.fire_rate_mult

	return mult
	
func refresh_all_towers():

	for tower in get_tree().get_nodes_in_group("towers"):

		if tower is BaseTower:
			tower.apply_run_bonuses()
