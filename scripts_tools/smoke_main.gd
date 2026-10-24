extends Node
## Fumigène : mesure une carte de la main au repos puis au survol.
##
## Ce qu'on vérifie : la carte est entièrement dans l'écran au repos, et le
## survol la fait REMONTER — pas seulement grossir sur place, ce qui laissait
## son pied (les phénomènes) aussi caché qu'avant.

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Runner.new())


class Runner extends Node:
	func _ready() -> void:
		Progress.current_level_id = 3
		Progress.selected_deck = null
		get_tree().change_scene_to_file("res://scenes/ui/level.tscn")
		await get_tree().create_timer(2.5).timeout

		var scene := get_tree().current_scene
		var box = scene.tower_cards_container
		if box.get_child_count() == 0:
			print("aucune carte en main")
			get_tree().quit()
			return

		# ⚠ get_global_rect().size INCLUT déjà l'échelle : la remultiplier
		# faisait état d'une remontée de 9 px là où il y en a 75.
		var card = box.get_child(0)
		var ecran: float = scene.get_viewport_rect().size.y
		var r0: Rect2 = card.get_global_rect()
		print("Ecran   hauteur=%.0f" % ecran)
		print("REPOS   haut=%.0f bas=%.0f hauteur=%.0f | sous l'ecran : %.0f px"
			% [r0.position.y, r0.end.y, r0.size.y, maxf(0.0, r0.end.y - ecran)])

		card._on_mouse_entered()
		await get_tree().create_timer(0.4).timeout
		var r1: Rect2 = card.get_global_rect()
		print("SURVOL  haut=%.0f bas=%.0f hauteur=%.0f | sous l'ecran : %.0f px"
			% [r1.position.y, r1.end.y, r1.size.y, maxf(0.0, r1.end.y - ecran)])
		print("        deplacement : bas %.0f px, haut %.0f px, echelle x%.2f"
			% [r0.end.y - r1.end.y, r0.position.y - r1.position.y, card.scale.y])

		# Le survol ouvre aussi l'infobulle : elle ne doit pas finir derriere
		# la carte agrandie, sinon la liste des phenomenes reste illisible.
		var ancre = scene.get_node_or_null("UI/RootUI/CardTooltipAnchor")
		if ancre and ancre.get_child_count() > 0:
			var bulle = ancre.get_child(0)
			var rb: Rect2 = bulle.get_global_rect()
			print("BULLE   haut=%.0f bas=%.0f hauteur=%.0f" % [rb.position.y, rb.end.y, rb.size.y])
			var chevauche: float = rb.end.y - r1.position.y
			if chevauche > 0.0:
				print("        ⚠ RECOUVERTE par la carte sur %.0f px" % chevauche)
			else:
				print("        libre, %.0f px au-dessus de la carte" % -chevauche)
		get_tree().quit()
