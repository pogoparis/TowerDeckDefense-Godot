extends Node

var scrap := 300

func add_scrap(amount: int):
	scrap += amount

func spend_scrap(amount: int) -> bool:

	if scrap < amount:
		return false

	scrap -= amount
	return true
