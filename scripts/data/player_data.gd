class_name PlayerData
extends Node

signal caps_changed(new_caps)
signal base_hp_changed(new_hp)

var caps := 6
var base_hp := 100

func add_caps(amount:int):

	caps += amount
	caps_changed.emit(caps)

func spend_caps(amount:int) -> bool:

	if caps < amount:
		return false

	caps -= amount
	caps_changed.emit(caps)

	return true

func damage_base(amount:int):

	base_hp -= amount

	if base_hp < 0:
		base_hp = 0

	base_hp_changed.emit(base_hp)
