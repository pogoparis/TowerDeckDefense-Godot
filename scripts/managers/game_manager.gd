class_name GameManager
extends Node

var gold: int = 300

func add_gold(amount: int):
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true
