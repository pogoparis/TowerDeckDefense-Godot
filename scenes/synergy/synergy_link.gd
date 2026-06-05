extends Line2D

var _instance: SynergyInstance
var _pulse: float = 0.0
var _is_preview: bool = false


func setup(instance: SynergyInstance, preview: bool = false) -> void:
	_instance = instance
	_is_preview = preview
	width = 4.0 if not preview else 3.0
	default_color = Color.WHITE
	if instance.rule and instance.rule.visual_profile:
		var vp: SynergyVisualProfile = instance.rule.visual_profile
		var grad := Gradient.new()
		grad.add_point(0.0, vp.link_color_a)
		grad.add_point(1.0, vp.link_color_b)
		gradient = grad
		default_color = vp.link_color_a
	if preview:
		modulate.a = 0.65
	_set_endpoints()


func _process(delta: float) -> void:
	_pulse += delta * 4.0
	if _instance:
		_set_endpoints()
	if not _is_preview:
		width = 4.0 + sin(_pulse) * 0.8


func _set_endpoints() -> void:
	if not _instance:
		return
	var a := SynergyManager.cell_to_world_center(_instance.cell_a)
	var b := SynergyManager.cell_to_world_center(_instance.cell_b)
	var parent_node := get_parent()
	if parent_node:
		a = parent_node.to_local(a)
		b = parent_node.to_local(b)
	clear_points()
	add_point(a)
	add_point(b)
