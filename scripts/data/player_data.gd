class_name PlayerData
extends Node

signal caps_changed(new_caps)
signal base_hp_changed(new_hp)
## Une FUITE vient d'arriver — un ennemi a atteint le Squat.
##
## Distinct de base_hp_changed, qui sert aussi quand on FIXE les PV (tutoriel).
## Ici c'est un ÉVÈNEMENT dramatique : c'est le seul moment de tension du jeu,
## et il passait jusqu'ici quasiment inaperçu (un son, un chiffre qui change).
## Une remontada n'existe que si le joueur SAIT qu'il est en train de la faire.
signal leaked(amount, remaining_hp)
## Compteur de fuites de la partie — affiché sur l'écran de défaite pour que
## la défaite ENSEIGNE au lieu de simplement sanctionner.
var leaks := 0
signal wave_changed(new_wave)

const MAX_BASE_HP := 20

var current_wave := 1
## Caps de départ. ⚠ Elles doivent permettre DEUX tours, pas "1-2" : la vague 1
## réclame ~17 DPS et aucune tour seule n'y arrive (la meilleure plafonne à
## 12.5). À 50 caps, toute paire incluant le Gardien (40) était inachetable —
## soit la carte la plus fréquente du deck Roche. 70 couvre Gardien + Requin.
var caps := 70
var base_hp := MAX_BASE_HP

## Base invulnérable (tutoriel guidé : le joueur ne peut pas perdre).
var invulnerable := false

func reset() -> void:
	current_wave = 1
	caps = 70
	base_hp = MAX_BASE_HP
	leaks = 0
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

func damage_base(amount:int):

	if invulnerable:
		return

	Audio.play_sfx(preload("res://assets/audio/sfx/base_hit.wav"), -3.0)
	base_hp -= amount

	if base_hp < 0:
		base_hp = 0

	base_hp_changed.emit(base_hp)
	leaks += 1
	leaked.emit(amount, base_hp)

	if base_hp <= 0:

		get_tree().paused = true

		print("GAME OVER")
