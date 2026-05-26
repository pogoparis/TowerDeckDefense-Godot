extends TextureButton

@export var tower_scene: PackedScene

func _pressed():

	var level = get_tree().get_first_node_in_group("level")

	if level:
		level.start_placing_tower(tower_scene)
