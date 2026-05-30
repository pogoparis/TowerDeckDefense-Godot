extends Node

var owned_bonuses: Array[BonusData] = []

func add_bonus(bonus: BonusData):

	owned_bonuses.append(bonus)

	print("BONUS ADDED: ", bonus.title)
	if bonus == null:
		push_error("BONUS IS NULL")
		return
	owned_bonuses.append(bonus)
