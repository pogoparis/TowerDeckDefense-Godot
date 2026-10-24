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

## Deck choisi par le joueur sur l'écran de sélection, pour la run en cours.
## null = on retombe sur le deck par défaut du niveau (cas du tutoriel).
var selected_deck: StartingDeckData = null

## Scène du niveau à lancer une fois le deck choisi (l'écran de sélection
## s'intercale entre la carte du monde et le niveau).
var pending_level_scene: String = ""

## Deck FINAL après personnalisation (jusqu'à 3 échanges sur l'écran de deck).
## Vide = on utilise tel quel le deck préconstruit de `selected_deck`.
var custom_deck_cards: Array[CardData] = []

var _stars: Dictionary = {}

# ══════════════════════════════════════════════════════
#            MÉTA-PROGRESSION : LES DÉBLOCAGES
# ══════════════════════════════════════════════════════
#
# Après la victoire, le jeu ne proposait RIEN : des étoiles, un niveau suivant,
# et plus rien après le niveau 3. Aucune raison de rejouer, aucune collection à
# compléter, aucun objectif à poursuivre.
#
# Le principe retenu : terminer un niveau AGRANDIT le pool de récompenses des
# parties suivantes. C'est une progression qui AJOUTE — on ne retire jamais au
# joueur ce qu'il avait, et chaque victoire promet des offres plus riches.
#
# Ce qu'on débloque : les cartes UTILITAIRES. Ce sont les plus « avancées »
# (économie, cycle, améliorations gratuites) et ce sont elles qui créent les
# archétypes — donc débloquer, c'est littéralement débloquer des façons de jouer.
const UNLOCKS_BY_LEVEL := {
	1: ["util_recyclage", "util_reconnaissance"],
	2: ["util_bricolage", "util_decharge_sauvage", "util_plan_b"],
	3: ["util_contrebande", "util_atelier", "util_pillage"],
}

var _unlocked: Array[String] = []


## Identifiants de cartes débloqués (nom de fichier sans extension).
func unlocked_cards() -> Array[String]:
	return _unlocked


func is_card_unlocked(card_id: String) -> bool:
	# Tout ce qui n'est pas dans une table de déblocage est disponible d'office :
	# les tours et les sorts restent accessibles dès la première partie.
	for ids in UNLOCKS_BY_LEVEL.values():
		if card_id in ids:
			return card_id in _unlocked
	return true


## Débloque les cartes d'un niveau. Retourne CE QUI VIENT d'être débloqué,
## pour l'annoncer sur l'écran de victoire — un déblocage silencieux n'est pas
## une récompense.
func unlock_for_level(level_id: int) -> Array[String]:
	var freshly: Array[String] = []
	for card_id in UNLOCKS_BY_LEVEL.get(level_id, []):
		if not card_id in _unlocked:
			_unlocked.append(card_id)
			freshly.append(card_id)
	if not freshly.is_empty():
		_save()
	return freshly



func _ready() -> void:
	_load()


## Étoiles obtenues sur un niveau (0 si jamais terminé).
func get_stars(level_id: int) -> int:
	return _stars.get(level_id, 0)


func is_unlocked(level_id: int) -> bool:
	# L'ATELIER (99) est un outil de conception, pas une étape de l'aventure :
	# le verrouiller derrière une progression le rendrait inutile exactement
	# quand il sert — au moment où l'on crée le mob du niveau suivant.
	if level_id == AtelierPanel.LEVEL_ID:
		return true
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
	_unlocked.clear()
	_save()


func _save() -> void:
	var config := ConfigFile.new()
	for level_id: int in _stars:
		config.set_value("stars", str(level_id), _stars[level_id])
	config.set_value("unlocks", "cards", _unlocked)
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	if config.has_section("stars"):
		for key in config.get_section_keys("stars"):
			_stars[int(key)] = int(config.get_value("stars", key, 0))
	if config.has_section("unlocks"):
		var saved: Array = config.get_value("unlocks", "cards", [])
		for id in saved:
			_unlocked.append(str(id))
