class_name CardManager
extends Node

## Gestion du deck : pioche / main / défausse / mulligan + jeu des cartes.
## Le mécanisme CONSUME (défausser une carte → phénomène) a été retiré —
## les zones/réactions seront rebranchées sur les Charges et les Sorts.

var placement_manager: PlacementManager
var tower_container: Node2D

var refill_hand_size := 3
var max_hand_size := 4

var draw_pile: Array[CardData] = []
var hand     : Array[CardData] = []
## Cartes déjà jouées. Quand la pioche est vide, la défausse est remélangée
## dedans (cycle deckbuilder classique, prévu par le GDD). Sans ça le deck
## s'épuise en milieu de partie et les Caps ne servent plus à rien.
var discard_pile: Array[CardData] = []


# ==================================================
# MULLIGAN
# ==================================================

var mulligan_used := false

func can_use_mulligan() -> bool:
	return not mulligan_used


func mulligan(cards_to_replace: Array[CardData]):

	if mulligan_used:
		return

	if cards_to_replace.is_empty():
		return

	for card in cards_to_replace:

		if hand.has(card):

			hand.erase(card)
			draw_pile.append(card)

	draw_pile.shuffle()

	draw_to_hand(cards_to_replace.size())

	mulligan_used = true


# ==================================================
# SETUP
# ==================================================

func setup(
	new_placement_manager: PlacementManager,
	new_tower_container: Node2D
):

	placement_manager = new_placement_manager
	tower_container = new_tower_container


func setup_starting_deck(cards: Array, shuffle: bool = true):

	draw_pile.clear()
	hand.clear()
	discard_pile.clear()

	mulligan_used = false

	# ⚠ DUPLICATION OBLIGATOIRE — prérequis de tout le système d'amélioration.
	#
	# Les CardData sont des ressources PARTAGÉES : preload() renvoie la même
	# instance à tout le monde et Godot la garde en cache ENTRE LES PARTIES.
	# Améliorer une carte en jeu modifierait donc la carte définitivement — y
	# compris dans les decks préconstruits et dans les parties suivantes.
	# Le bug ne se verrait pas tout de suite : il se verrait trois parties plus
	# tard, quand tout serait déjà amélioré.
	#
	# duplicate(false) = copie superficielle : les propriétés sont copiées, mais
	# tower_scene et spell_data restent des références partagées (on ne veut
	# surtout pas dupliquer une scène entière). Les sous-ressources qui doivent
	# vraiment être privées sont dupliquées au moment de l'amélioration.
	var run_cards: Array[CardData] = []
	for card in cards:
		if card != null:
			run_cards.append(card.duplicate(false))

	for card in run_cards:
		draw_pile.append(card)

	if shuffle:
		draw_pile.shuffle()
	else:
		# Ordre scripté : draw_to_hand tire avec pop_back (la fin du tableau).
		# On inverse pour que le 1er élément du deck soit tiré en premier.
		draw_pile.reverse()

	draw_to_hand(3)


# ==================================================
# DRAW
# ==================================================

func draw_to_hand(amount: int):

	for i in amount:

		if draw_pile.is_empty():
			_reshuffle_discard()

		if draw_pile.is_empty():
			return   # vraiment plus aucune carte nulle part

		var card = draw_pile.pop_back()
		hand.append(card)


## Remélange la défausse dans la pioche (quand la pioche est vide).
func _reshuffle_discard() -> void:
	if discard_pile.is_empty():
		return
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	draw_pile.shuffle()


func draw_until_full_hand():

	var missing_cards = refill_hand_size - hand.size()

	if missing_cards <= 0:
		return

	draw_to_hand(missing_cards)


# ==================================================
# DECK MANAGEMENT
# ==================================================

## Toutes les cartes du deck, où qu'elles soient (pioche, main, défausse).
## Sert aux récompenses d'amélioration, qui doivent viser une carte possédée.
func all_cards() -> Array[CardData]:
	var out: Array[CardData] = []
	out.append_array(draw_pile)
	out.append_array(hand)
	out.append_array(discard_pile)
	return out


## Retire DÉFINITIVEMENT une carte du deck (récompense d'épuration).
## Cherche dans les trois piles : la carte peut être n'importe où.
func remove_card_from_deck(card: CardData) -> bool:
	for pile in [draw_pile, hand, discard_pile]:
		if pile.has(card):
			pile.erase(card)
			return true
	return false


## Ajoute une carte gagnée en récompense. Retourne "main" ou "pioche" — c'est
## l'appelant qui l'annonce au joueur.
##
## ⚠ DUPLICATION, même raison que pour le deck de départ : `reward.card_data`
## vient du pool global, chargé par `load()`. Godot met ces ressources en cache
## ENTRE LES PARTIES — l'améliorer plus tard modifierait la carte pour toujours.
##
## ⚠ Et surtout : quand la main est pleine, la carte file dans la PIOCHE. Sans
## message, le joueur croit que sa récompense n'a pas fonctionné — c'est
## exactement ce qui a été signalé en playtest.
func add_reward_card(card: CardData) -> String:
	var copy: CardData = card.duplicate(false)

	if hand.size() < max_hand_size:
		hand.append(copy)
		return "main"

	draw_pile.append(copy)
	return "pioche"


func add_card(card: CardData):

	if card == null:
		return

	hand.append(card)


## Retire une carte de la main et l'envoie à la DÉFAUSSE (carte Tour posée).
## Elle reviendra dans la pioche au prochain remélange → le joueur peut
## continuer à poser des tours tant qu'il a des Caps.
func discard_card(card: CardData):

	if card == null:
		return

	if hand.has(card):
		hand.erase(card)
		discard_pile.append(card)


# ==================================================
# PLAY (BUILD)
# ==================================================

func play_card(card: CardData):

	match card.card_type:

		CardData.CardType.TOWER:

			if Player.caps < card.mana_cost:

				alert_not_enough_caps()

				return

			placement_manager.start_tower_placement(
				card.tower_scene,
				card,
				tower_container
			)

		CardData.CardType.SPELL:

			if card.spell_data == null:
				push_error("Carte SORT sans spell_data : " + card.card_name)
				return

			# On ne débite PAS ici : le joueur entre en visée, il doit pouvoir
			# annuler sans rien perdre. Les Caps partent au lancement effectif
			# (placement_manager.try_cast_spell).
			if Player.caps < card.mana_cost:
				alert_not_enough_caps()
				return

			placement_manager.start_spell_targeting(card.spell_data, card)

		CardData.CardType.UPGRADE:

			# Se vise comme un sort : on désigne la tour à améliorer.
			if not Player.spend_caps(card.mana_cost):
				alert_not_enough_caps()
				return
			placement_manager.start_upgrade_targeting(card)

		CardData.CardType.TACTIC, CardData.CardType.ECONOMY:

			if not Player.spend_caps(card.mana_cost):
				alert_not_enough_caps()
				return
			_play_utility(card)

		CardData.CardType.RELIC:

			push_warning("Reliques non implémentées : " + card.card_name)


## Effet immédiat d'une carte utilitaire (économie ou tactique).
func _play_utility(card: CardData) -> void:
	var scene := get_tree().current_scene

	if card.instant_caps > 0:
		Player.add_caps(card.instant_caps)
		_float(scene, "+%d caps" % card.instant_caps, Color(1.0, 0.85, 0.25))

	if card.caps_per_wave > 0:
		RunDeck.caps_per_wave += card.caps_per_wave
		_float(scene, "+%d caps / vague" % card.caps_per_wave, Color(0.6, 1.0, 0.5))

	if card.draw_cards > 0:
		draw_to_hand(card.draw_cards)
		_float(scene, "+%d cartes" % card.draw_cards, Color(0.6, 0.85, 1.0))

	discard_card(card)
	scene.refresh_hand_ui()


func _float(scene: Node, text: String, color: Color) -> void:
	if scene is Node2D:
		FloatingTextService.spawn(
			scene, scene.get_global_mouse_position() + Vector2(0, -40), text, color, 1.4
		)


# ==================================================
# FEEDBACK
# ==================================================

## Alerte quand une carte ciblée ne trouve rien (la carte est remboursée).
func alert_no_target() -> void:
	Audio.error()
	var scene := get_tree().current_scene
	if scene is Node2D:
		FloatingTextService.spawn(
			scene, scene.get_global_mouse_position() + Vector2(0, -40),
			"AUCUNE TOUR À AMÉLIORER", Color(1, 0.5, 0.3), 1.4
		)


## Son d'erreur + alerte rouge au curseur quand le joueur manque de Caps.
func alert_not_enough_caps() -> void:
	Audio.error()

	var scene := get_tree().current_scene
	if scene is Node2D:
		FloatingTextService.spawn(
			scene,
			scene.get_global_mouse_position() + Vector2(0, -40),
			"PAS ASSEZ DE CAPS !",
			Color(1, 0.3, 0.3),
			1.4
		)
