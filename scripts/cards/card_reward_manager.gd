extends Node
class_name CardRewardManager
## Écran de récompense entre deux vagues (autoload "RewardManager").
##
## C'est le moment où le deck GRANDIT. Sans lui, le joueur finit la partie avec
## exactement les 10 cartes du début : rien à découvrir, et deux parties sur le
## même niveau sont identiques.

signal reward_chosen

## Caps offertes si le joueur PASSE l'offre.
##
## Pourquoi une option "passer" : sans elle, une offre inutile (trois cartes
## qu'on ne veut pas) devient une punition déguisée, et diluer son deck avec une
## mauvaise carte coûte plus cher que de ne rien prendre. Avec elle, refuser
## devient un choix légitime — c'est la leçon de Slay the Spire.
const SKIP_CAPS := 45

var reward_panel: Control
var reward_container

var reward_card_scene := preload("res://scenes/ui/reward_card.tscn")

var reward_selected := false
var reward_cards: Array[RewardData] = []


func show_rewards():
	reward_selected = false
	reward_panel.visible = true

	clear_rewards()

	# Le niveau en cours conditionne l'offre : on ne propose pas une carte de
	# Feu sur un niveau où le Feu ne paie pas.
	reward_cards = RewardDB.get_random_rewards(3, Progress.current_level_id)

	if reward_cards.is_empty():
		push_error("Aucune récompense disponible")
		reward_selected = true
		reward_panel.visible = false
		return

	for reward in reward_cards:
		var card = reward_card_scene.instantiate()
		reward_container.add_child(card)
		card.setup(reward)
		card.reward_clicked.connect(_on_reward_selected)

	reward_container.add_child(_build_skip_button())


## Bouton PASSER — accepte l'offre en Caps plutôt qu'en carte.
func _build_skip_button() -> Control:
	var btn := Button.new()
	btn.text = "PASSER\n+%d caps" % SKIP_CAPS
	btn.custom_minimum_size = Vector2(150, 200)
	btn.pressed.connect(_on_skip)
	return btn


func _on_skip() -> void:
	Audio.ui_click()
	Player.add_caps(SKIP_CAPS)
	_close()


func select_reward(index: int):
	var reward = reward_cards[index]
	RewardDB.mark_taken(reward)

	match reward.reward_type:

		RewardData.RewardType.CARD:
			var card_manager = get_tree().current_scene.card_manager
			var destination: String = card_manager.add_reward_card(reward.card_data)
			RunDeck.owned_cards.append(reward.card_data)
			get_tree().current_scene.refresh_hand_ui()
			_announce("%s → %s" % [reward.card_data.card_name, destination],
				Color(0.5, 0.9, 1.0))

		RewardData.RewardType.CARD_UPGRADE:
			# La carte visée est DÉJÀ dans le deck (c'est une copie propre à la
			# partie, dupliquée au démarrage) : on la modifie en place, toutes
			# ses occurrences en pioche/main/défausse sont donc à jour.
			var before: String = reward.card_data.card_name
			reward.card_data.apply_upgrade()
			get_tree().current_scene.refresh_hand_ui()
			_announce("%s améliorée ★" % before, Color(1.0, 0.85, 0.3))

		RewardData.RewardType.CARD_REMOVE:
			var cm = get_tree().current_scene.card_manager
			var removed_name: String = reward.card_data.card_name
			if cm.remove_card_from_deck(reward.card_data):
				_announce("%s retirée du deck (%d cartes)" % [
					removed_name, cm.all_cards().size()
				], Color(1.0, 0.55, 0.45))
			else:
				push_warning("Épuration : carte introuvable dans le deck.")
			get_tree().current_scene.refresh_hand_ui()

		RewardData.RewardType.BONUS:
			RunBonuses.add_bonus(reward.bonus_data)

		RewardData.RewardType.RELIC:
			push_warning("Reliques non implémentées")

	_close()


## Annonce ce qui vient de se passer, au centre de l'écran.
##
## Sans ça, une récompense qui atterrit dans la PIOCHE ou qui retire une carte
## déjà en pioche est invisible : le joueur croit que rien ne s'est produit.
## Les deux cas ont été signalés en playtest, et c'était le même défaut.
func _announce(text: String, color: Color) -> void:
	var scene := get_tree().current_scene
	if scene is Node2D:
		FloatingTextService.spawn(
			scene,
			Vector2(scene.get_viewport().get_visible_rect().size * Vector2(0.5, 0.30)),
			text, color, 1.7
		)


func _close() -> void:
	reward_selected = true
	reward_panel.visible = false
	reward_chosen.emit()


func clear_rewards():
	for child in reward_container.get_children():
		child.queue_free()


func _on_reward_selected(reward: RewardData):
	var index := reward_cards.find(reward)
	if index != -1:
		select_reward(index)
