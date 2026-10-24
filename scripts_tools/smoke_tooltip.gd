extends Node
## Fumigène : mesure la bulle d'aide sur les cartes les plus bavardes.
## Le Requin Cracheur (water_cannon_card) a quatre réactions élémentaires —
## c'est lui dont la dernière ligne était coupée par la bulle à hauteur fixe.

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Runner.new())


class Runner extends Node:
	func _ready() -> void:
		await get_tree().process_frame
		var scene = preload("res://scenes/ui/card_tooltip.tscn")

		for file in ["water_cannon_card", "fire_punk_card", "util_pillage"]:
			var card = load("res://resources/cards/%s.tres" % file)
			if card == null:
				continue
			var tip = scene.instantiate()
			add_child(tip)
			tip.setup(card)
			# Deux images : la première met en forme le texte, la seconde
			# propage la taille au conteneur.
			await get_tree().process_frame
			await get_tree().process_frame
			print("%-22s bulle %d x %d px" % [card.card_name, tip.size.x, tip.size.y])
			tip.queue_free()

		get_tree().quit()
