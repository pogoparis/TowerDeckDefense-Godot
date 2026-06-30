extends Node
## Progression du joueur (autoload "Progress").
##
## Mémorise les étoiles obtenues par niveau et en déduit les déblocages.
## Persisté dans user://save.cfg — survit au redémarrage du jeu.
##
## Règles :
## - Le niveau 1 est toujours débloqué
## - Le niveau N se débloque quand le niveau N-1 a au moins 1 étoile
## - On ne remplace jamais un meilleur score par un moins bon

const SAVE_PATH := "user://save.cfg"

## Niveau actuellement joué — défini par la carte du monde avant de
## lancer la partie, lu à la victoire pour attribuer les étoiles.
var current_level_id: int = 1

var _stars: Dictionary = {}


func _ready() -> void:
	_load()


## Étoiles obtenues sur un niveau (0 si jamais terminé).
func get_stars(level_id: int) -> int:
	return _stars.get(level_id, 0)


func is_unlocked(level_id: int) -> bool:
	return level_id <= 1 or get_stars(level_id - 1) > 0


## Enregistre un résultat de niveau. Ne sauvegarde que si c'est un record.
func complete_level(level_id: int, stars: int) -> void:
	if stars <= get_stars(level_id):
		return
	_stars[level_id] = clampi(stars, 1, 3)
	_save()


## Efface toute la progression (future option "recommencer l'aventure").
func reset_progress() -> void:
	_stars.clear()
	_save()


func _save() -> void:
	var config := ConfigFile.new()
	for level_id: int in _stars:
		config.set_value("stars", str(level_id), _stars[level_id])
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	if not config.has_section("stars"):
		return
	for key in config.get_section_keys("stars"):
		_stars[int(key)] = int(config.get_value("stars", key, 0))
