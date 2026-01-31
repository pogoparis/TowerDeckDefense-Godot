extends TextureButton

signal tower_selected(scene: PackedScene)
@export var tower_scene: PackedScene

func _pressed():
	emit_signal("tower_selected", tower_scene)
	accept_event()
