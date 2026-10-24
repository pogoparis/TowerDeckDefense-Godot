extends Node
## Fumigène : charge le niveau en mode ATELIER, lâche un mob, et quitte.
## Prend les erreurs d'exécution que --editor ne voit pas (le contrôle de
## syntaxe ne dit rien d'un panneau qui plante à la construction).
##
## ⚠ Le test DOIT vivre en dehors de la scène courante : change_scene_to_file()
## libère celle-ci, donc un nœud qui s'y trouve est détruit au milieu de son
## propre await — la partie après le changement de scène ne s'exécutait jamais
## et le processus tournait indéfiniment.

func _ready() -> void:
	var runner := Runner.new()
	get_tree().root.add_child.call_deferred(runner)


class Runner extends Node:
	func _ready() -> void:
		Progress.current_level_id = AtelierPanel.LEVEL_ID
		Progress.selected_deck = null
		get_tree().change_scene_to_file("res://scenes/ui/level.tscn")
		await get_tree().create_timer(2.0).timeout

		var scene := get_tree().current_scene
		var panel = scene.get_node_or_null("AtelierPanel") if scene else null
		print("ATELIER_PRESENT=", panel != null)

		if panel:
			var em = scene.get("enemy_manager")
			panel._on_spawn("fournaise")
			await get_tree().create_timer(1.0).timeout
			print("MOBS_VIVANTS=", em.get_all_enemies().size() if em else "?")

			var mob = em.get_all_enemies()[0] if em and em.get_all_enemies().size() > 0 else null
			if mob:
				print("CHALEUR_DEPART=%.2f  VITESSE=%.0f" % [mob.heat, mob.speed])
				await get_tree().create_timer(3.0).timeout
				print("CHALEUR_APRES_3s=%.2f  VITESSE=%.0f" % [mob.heat, mob.speed])
				panel._on_chill_all()
				await get_tree().create_timer(1.0).timeout
				print("CHALEUR_APRES_GIVRE=%.2f  VITESSE=%.0f" % [mob.heat, mob.speed])

			panel._on_clear()
			await get_tree().create_timer(0.5).timeout
			print("NETTOYAGE_RESTE=", em.get_all_enemies().size() if em else "?")

		get_tree().quit()
