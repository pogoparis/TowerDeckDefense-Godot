class_name PlayerData
extends Node

signal caps_changed(new_caps)
signal base_hp_changed(new_hp)
signal wave_changed(new_wave)

var current_wave := 1
var caps := 4
var base_hp := 100

func set_wave(value:int):

	current_wave = value
	wave_changed.emit(current_wave)

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

	if base_hp <= 0:

		get_tree().paused = true

		print("GAME OVER")
