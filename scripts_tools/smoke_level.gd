extends Node
## Fumigène : charge un niveau réel et rapporte ce qui est effectivement en
## place — fond, chemin, cases constructibles. Le contrôle de syntaxe ne dit
## rien d'un chemin qui ne s'applique pas.

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Runner.new())


class Runner extends Node:
	func _ready() -> void:
		Progress.current_level_id = 3
		Progress.selected_deck = null
		get_tree().change_scene_to_file("res://scenes/ui/level.tscn")
		await get_tree().create_timer(2.0).timeout

		var scene := get_tree().current_scene
		var bg = scene.get_node_or_null("World/Background")
		var path = scene.get_node_or_null("World/Path2D")
		var grid = scene.get("grid")

		if bg and bg.texture:
			print("FOND=", bg.texture.resource_path.get_file(),
				"  taille=", bg.texture.get_size(), "  echelle=", bg.scale)
		if path and path.curve:
			print("PATH_POS=", path.position, "  POINTS=", path.curve.point_count,
				"  LONGUEUR=%.0f px" % path.curve.get_baked_length())
			var rows := []
			for i in path.curve.point_count:
				var pt: Vector2 = path.to_global(path.curve.get_point_position(i))
				rows.append("(%d,%d)" % [pt.x, pt.y])
			print("TRACE=", " ".join(rows))
		if grid:
			# buildable_cells est un Array[Vector2i], pas un dictionnaire.
			print("CASES_CONSTRUCTIBLES=", grid.buildable_cells.size(),
				" sur ", GridManager.GRID_WIDTH * GridManager.GRID_HEIGHT)
		get_tree().quit()
