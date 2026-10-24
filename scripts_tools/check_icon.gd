extends SceneTree

func _initialize() -> void:
	var tex := load("res://assets/icons/parametres256.png")
	print("TEX_LOADED=", tex != null, "  ", tex)

	var ps := load("res://scenes/ui/TopHUD.tscn") as PackedScene
	print("SCENE_LOADED=", ps != null)

	var inst := ps.instantiate()
	var btn := inst.get_node_or_null("Panel/VBox/StatsRow/SettingsButton")
	print("BTN=", btn)
	if btn:
		print("SCENE_ICON=", btn.icon)
		print("EXPAND_ICON=", btn.expand_icon)
		print("THEME_TYPE=", btn.theme_type_variation)
	quit()
