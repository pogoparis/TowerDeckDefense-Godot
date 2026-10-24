extends Node
## Fumigène : améliore une carte TOUR par récompense, la pose, et compare la
## tour obtenue à une tour posée avec la carte normale.
## Cas signalé : « je pose une carte améliorée, elle se pose non améliorée ».

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Runner.new())


class Runner extends Node:
	func _ready() -> void:
		Progress.current_level_id = 3
		Progress.selected_deck = null
		get_tree().change_scene_to_file("res://scenes/ui/level.tscn")
		await get_tree().create_timer(2.5).timeout

		var scene := get_tree().current_scene
		var cm = scene.card_manager
		var pm = scene.placement
		var grid = scene.grid

		Player.add_caps(5000)

		# Une carte TOUR du deck en cours.
		var cible: CardData = null
		for c in cm.all_cards():
			if c != null and c.card_type == CardData.CardType.TOWER:
				cible = c
				break
		if cible == null:
			print("aucune carte TOUR dans le deck")
			get_tree().quit()
			return

		print("Carte : %s   upgraded=%s" % [cible.card_name, cible.upgraded])

		var normale = await _poser(scene, pm, grid, cible, Vector2i(4, 6))
		print("AVANT  degats=%d  cadence=%.2f  portee=%.0f  card_mult=%.2f"
			% [normale.damage, normale.fire_rate, normale.attack_range, normale.card_damage_mult])

		# On applique l'amélioration comme le fait la récompense.
		var reward := RewardData.new()
		reward.reward_type = RewardData.RewardType.CARD_UPGRADE
		reward.card_data = cible
		RewardManager.reward_cards = [reward] as Array[RewardData]
		RewardManager.select_reward(0)
		await get_tree().process_frame
		print("Apres recompense : %s   upgraded=%s" % [cible.card_name, cible.upgraded])

		# La carte est-elle encore la même instance dans la main ?
		var en_main := 0
		for c in cm.hand:
			if c == cible:
				en_main += 1
		print("Meme instance en main : %d" % en_main)

		var amelioree = await _poser(scene, pm, grid, cible, Vector2i(6, 6))
		if amelioree == null:
			print("!! pose impossible")
		else:
			print("APRES  degats=%d  cadence=%.2f  portee=%.0f  card_mult=%.2f"
				% [amelioree.damage, amelioree.fire_rate, amelioree.attack_range,
				   amelioree.card_damage_mult])

			# Le badge doit SURVIVRE au recalcul des synergies : c'est lui qui
			# effaçait l'ancien marqueur dans la seconde suivant la pose.
			scene.synergy_manager.recalculate_synergies()
			await get_tree().process_frame
			print("       badge ★ present apres recalcul : %s"
				% amelioree.has_node("StarBadge"))
			print("       niveau=%d  cout de la prochaine amelioration=%d caps"
				% [amelioree.upgrade_level, amelioree.upgrade_price()])
			print("       tour NORMALE : niveau=%d  prochaine amelioration=%d caps"
				% [normale.upgrade_level, normale.upgrade_price()])

			# ⚠ Contamination : en GDScript, un Array d'export peut être PARTAGÉ
			# entre instances. Si _raise_upgrade_prices() mutait le tableau au
			# lieu d'en assigner un neuf, TOUTES les tours de ce type verraient
			# leurs prix grimper — y compris celles posées ensuite, et le bug ne
			# se verrait que des parties plus tard.
			# On sonde une instance NEUVE de la même scène : reposer la carte
			# ne prouverait rien, elle est désormais ★ elle aussi.
			var neuve = cible.tower_scene.instantiate()
			print("       INSTANCE NEUVE de la meme scene : couts=%s"
				% str(neuve.upgrade_costs))
			neuve.free()
		get_tree().quit()


	## Pose en passant par le VRAI chemin du jeu : start_tower_placement puis
	## try_place_tower, comme un clic du joueur. Un raccourci qui appellerait
	## create_tower directement contournerait justement l'endroit suspect.
	func _poser(scene, pm, grid, carte: CardData, cell: Vector2i):
		pm.start_tower_placement(carte.tower_scene, carte, scene.tower_container)
		pm.try_place_tower(grid.cell_to_world(cell))
		await get_tree().process_frame
		return grid.occupied_cells.get(cell)
