extends EnemyBase
class_name DroneMob

## DRONE JAUNE — le mob "de milieu/fin de partie".
##
## Son rôle n'est PAS d'avoir beaucoup de PV (le Tank fait déjà ça) : c'est un
## mob RAPIDE et BLINDÉ. Le blindage écrase les tours qui tapent vite et faible,
## la vitesse réduit la fenêtre de tir. Il oblige donc à poser au moins une
## grosse frappe (Gardien, Punk Explosif) ou du ralentissement (Glace, Ventilo)
## — c'est le mob qui punit le deck mono-tour.
##
## Il vole : il oscille verticalement et projette une ombre au sol, pour qu'on
## le distingue au premier coup d'œil des mobs terrestres.

@export_group("Vol")
## Amplitude et vitesse du flottement vertical (purement visuel).
@export var hover_amplitude := 7.0
@export var hover_speed := 3.2

@export_group("Sprites 4 directions")
@export var tex_east: Texture2D
@export var tex_south: Texture2D
@export var tex_west: Texture2D
@export var tex_north: Texture2D

@onready var _sprite: Sprite2D = $VisualRoot/Sprite2D
@onready var _visual: Node2D = $VisualRoot

var _hover_t := 0.0
var _visual_base_y := 0.0
var _last_pos := Vector2.ZERO
var _facing := -1


func _ready() -> void:
	super()
	_last_pos = global_position
	if _visual:
		_visual_base_y = _visual.position.y
	_set_facing(0)


func _process(delta: float) -> void:
	# Indispensable : c'est le _process de la base qui fait tourner les statuts
	# (gel, ralentissement, Marque d'Ombre, WET…). L'oublier rendrait le drone
	# insensible à tout le contrôle.
	super(delta)

	# Flottement : le drone ne "marche" pas, il tangue.
	_hover_t += delta * hover_speed
	if _visual:
		_visual.position.y = _visual_base_y + sin(_hover_t) * hover_amplitude

	# Orientation d'après le déplacement réel le long du chemin.
	var delta_pos := global_position - _last_pos
	if delta_pos.length_squared() > 0.01:
		_update_facing(delta_pos)
		_last_pos = global_position


## Choisit la texture selon la direction dominante du déplacement.
## Seuil sur l'axe dominant : sur un chemin orthogonal, ça évite le clignotement
## entre deux sprites quand le mob passe un angle.
func _update_facing(dir: Vector2) -> void:
	var want: int
	if absf(dir.x) >= absf(dir.y):
		want = 0 if dir.x > 0.0 else 2
	else:
		want = 1 if dir.y > 0.0 else 3
	if want != _facing:
		_set_facing(want)


func _set_facing(dir: int) -> void:
	if _sprite == null:
		return
	_facing = dir
	match dir:
		0: _sprite.texture = tex_east
		1: _sprite.texture = tex_south
		2: _sprite.texture = tex_west
		3: _sprite.texture = tex_north
