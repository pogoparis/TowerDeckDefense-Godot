extends Node2D

const LINK_SCENE := preload("res://scenes/synergy/SynergyLink.tscn")

var _links: Dictionary = {}


func _ready() -> void:
	z_index = 6
	if SynergyManager:
		SynergyManager.registry_changed.connect(_refresh)
		SynergyManager.synergy_activated.connect(_on_synergy_activated)
	_refresh()


func _on_synergy_activated(_instance: SynergyInstance) -> void:
	_refresh()


func refresh_preview(preview_list: Array) -> void:
	_clear_preview_links()
	for inst in preview_list:
		if not (inst is SynergyInstance):
			continue
		var key := "preview_%s" % _inst_key(inst)
		var link: Line2D = LINK_SCENE.instantiate()
		link.setup(inst, true)
		_links[key] = link
		add_child(link)


func clear_preview() -> void:
	_clear_preview_links()


func _clear_preview_links() -> void:
	var remove_keys: Array = []
	for key in _links.keys():
		if str(key).begins_with("preview_"):
			remove_keys.append(key)
	for key in remove_keys:
		_links[key].queue_free()
		_links.erase(key)


func _refresh() -> void:
	_clear_preview_links()
	for key in _links.keys():
		if not str(key).begins_with("preview_"):
			_links[key].queue_free()
	_links.clear()

	if not SynergyManager:
		return

	for inst in SynergyManager.get_active_synergies():
		var key := _inst_key(inst)
		var link: Line2D = LINK_SCENE.instantiate()
		link.setup(inst, false)
		_links[key] = link
		add_child(link)


func _inst_key(inst: SynergyInstance) -> String:
	return "%s|%d,%d|%d,%d" % [
		inst.rule.synergy_id if inst.rule else "",
		inst.cell_a.x, inst.cell_a.y,
		inst.cell_b.x, inst.cell_b.y,
	]
