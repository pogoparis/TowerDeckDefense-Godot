class_name PlayerData
extends Node

signal caps_changed(new_caps)
signal base_hp_changed(new_hp)
signal wave_changed(new_wave)
signal ferraille_changed(new_ferraille)

const MAX_BASE_HP := 20

var current_wave := 1
var caps := 4
var base_hp := MAX_BASE_HP
var ferraille := 0

## Base invulnérable (tutoriel guidé : le joueur ne peut pas perdre).
var invulnerable := false

func reset() -> void:
	current_wave = 1
	caps = 4
	base_hp = MAX_BASE_HP
	ferraille = 0
	invulnerable = false
	get_tree().paused = false

func set_wave(value:int):

	current_wave = value
	wave_changed.emit(current_wave)

func add_caps(amount:int):

	caps += amount
	caps_changed.emit(caps)

## Fixe les caps à une valeur exacte (utilisé par le tuto pour un dosage pile poil).
func set_caps(amount:int):
	caps = amount
	caps_changed.emit(caps)

## Fixe les PV de base à une valeur exacte (le tuto met 1 PV : zéro fuite tolérée).
func set_base_hp(amount:int):
	base_hp = amount
	base_hp_changed.emit(base_hp)

func spend_caps(amount:int) -> bool:

	if caps < amount:
		return false

	caps -= amount
	caps_changed.emit(caps)

	return true

func add_ferraille(amount: int):
	ferraille += amount
	ferraille_changed.emit(ferraille)

func spend_ferraille(amount: int) -> bool:

	if ferraille < amount:
		return false

	ferraille -= amount
	ferraille_changed.emit(ferraille)

	return true


func damage_base(amount:int):

	if invulnerable:
		return

	Audio.play_sfx(preload("res://assets/audio/sfx/base_hit.wav"), -3.0)
	base_hp -= amount

	if base_hp < 0:
		base_hp = 0

	base_hp_changed.emit(base_hp)

	if base_hp <= 0:

		get_tree().paused = true

		print("GAME OVER")
