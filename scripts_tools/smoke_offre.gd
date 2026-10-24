extends Node
## Fumigène : vérifie que CHAQUE offre annonce visiblement son type.
## Le cas qui a piégé le joueur : une amélioration qui s'affichait comme la
## carte elle-même, parce qu'elle en reprend l'illustration.

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Runner.new())


class Runner extends Node:
	func _ready() -> void:
		Progress.current_level_id = 3
		Progress.selected_deck = null
		get_tree().change_scene_to_file("res://scenes/ui/level.tscn")
		await get_tree().create_timer(2.0).timeout

		var scene_carte = preload("res://scenes/ui/reward_card.tscn")
		for tirage in 3:
			print("\n--- Offre %d ---" % (tirage + 1))
			for r in RewardDB.get_random_rewards(3, 3):
				var ui = scene_carte.instantiate()
				add_child(ui)
				ui.setup(r)
				await get_tree().process_frame
				print("  %-14s illustration:%-5s bandeau: « %s »" % [
					RewardData.RewardType.keys()[r.reward_type],
					"oui" if r.icon != null else "non",
					_bandeau(ui) if _bandeau(ui) != "" else "AUCUN"])
				ui.queue_free()
		get_tree().quit()

	## Retrouve le libellé affiché, où qu'il soit dans l'arbre.
	## Retourne "" quand il n'y en a pas : une sentinelle non vide ferait
	## remonter un faux positif au premier nœud sans label.
	func _bandeau(node: Node) -> String:
		for child in node.get_children():
			if child is Label and child.text != "":
				return child.text
			var found := _bandeau(child)
			if found != "":
				return found
		return ""
