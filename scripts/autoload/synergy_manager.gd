extends Node

signal synergy_activated(instance: SynergyInstance)
signal synergy_deactivated(instance: SynergyInstance)
signal registry_changed

const CELL_SIZE := 64

@export var synergy_rules: Array[SynergyRuleData] = []

var _placed: Dictionary = {} # Vector2i -> { tower, element, data }
var _active_links: Array[SynergyInstance] = []
var _known_synergies_this_run: Dictionary = {}


func _ready() -> void:
	_load_default_rules()


func _load_default_rules() -> void:
	if not synergy_rules.is_empty():
		return
	var paths := [
		"res://data/synergies/water_electric.tres",
		"res://data/synergies/air_electric.tres",
	]
	for p in paths:
		if ResourceLoader.exists(p):
			var rule := load(p) as SynergyRuleData
			if rule:
				synergy_rules.append(rule)


func register_tower(tower: Node2D, cell: Vector2i, element: JunkElement.Type, data: TowerData = null) -> void:
	_placed[cell] = {"tower": tower, "element": element, "data": data}
	_refresh_active_synergies()
	registry_changed.emit()


func unregister_tower(tower: Node2D) -> void:
	var remove_key: Vector2i = Vector2i(-9999, -9999)
	for cell in _placed.keys():
		if _placed[cell].tower == tower:
			remove_key = cell
			break
	if remove_key != Vector2i(-9999, -9999):
		_placed.erase(remove_key)
	_refresh_active_synergies()
	registry_changed.emit()


func update_tower_cell(tower: Node2D, cell: Vector2i) -> void:
	unregister_tower(tower)
	var element: JunkElement.Type = JunkElement.Type.WATER
	var data: TowerData = null
	if tower is TowerBase:
		element = (tower as TowerBase).get_element()
		data = (tower as TowerBase).get_tower_data()
	register_tower(tower, cell, element, data)


func get_orthogonal_neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1),
	]


func find_rule_for_elements(a: JunkElement.Type, b: JunkElement.Type) -> SynergyRuleData:
	for rule in synergy_rules:
		if rule.matches_elements(a, b):
			return rule
	return null


func get_active_synergies() -> Array[SynergyInstance]:
	return _active_links.duplicate()


func get_preview_synergies(ghost_element: JunkElement.Type, ghost_cell: Vector2i) -> Dictionary:
	var possible: Array[SynergyInstance] = []
	var partner_cells: Array[Vector2i] = []
	var partner_towers: Array[Node2D] = []

	for ncell in get_orthogonal_neighbors(ghost_cell):
		if not _placed.has(ncell):
			continue
		var entry: Dictionary = _placed[ncell]
		var rule := find_rule_for_elements(ghost_element, entry.element)
		if rule == null:
			continue
		var inst := SynergyInstance.new()
		inst.rule = rule
		inst.cell_a = ghost_cell
		inst.cell_b = ncell
		inst.tower_b = entry.tower
		inst.is_preview = true
		possible.append(inst)
		partner_cells.append(ncell)
		partner_towers.append(entry.tower)

	return {
		"active": get_active_synergies(),
		"possible": possible,
		"partner_cells": partner_cells,
		"partner_towers": partner_towers,
	}


func get_generation_multiplier_for(tower: Node2D) -> float:
	var mult := 1.0
	for inst in _active_links:
		if inst.tower_a != tower and inst.tower_b != tower:
			continue
		if inst.rule.effect == SynergyRuleData.EffectType.GENERATION_SPEED \
				or inst.rule.effect == SynergyRuleData.EffectType.STORM_FREQUENCY:
			mult = maxf(mult, inst.rule.multiplier)
	return mult


func get_projectile_tint_for(tower: Node2D) -> Color:
	for inst in _active_links:
		if inst.tower_a != tower and inst.tower_b != tower:
			continue
		if inst.rule.visual_profile:
			return inst.rule.visual_profile.phenomenon_tint
	return Color.WHITE


func get_phenomenon_size_multiplier_for(tower: Node2D) -> float:
	var mult := 1.0
	for inst in _active_links:
		if inst.tower_a != tower and inst.tower_b != tower:
			continue
		if inst.rule.effect == SynergyRuleData.EffectType.PHENOMENON_SIZE:
			mult = maxf(mult, inst.rule.multiplier)
	return mult


func cell_to_world_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE * 0.5,
		cell.y * CELL_SIZE + CELL_SIZE * 0.5
	)


func notify_synergy_activated_display(instance: SynergyInstance) -> void:
	if instance.rule and not _known_synergies_this_run.has(instance.rule.synergy_id):
		_known_synergies_this_run[instance.rule.synergy_id] = true
		if SynergyGuideService and SynergyGuideService.should_show_floating_text():
			_spawn_floating_text(instance)


func reset_run_tracking() -> void:
	_known_synergies_this_run.clear()


func _refresh_active_synergies() -> void:
	var previous := _active_links.duplicate()
	_active_links.clear()
	var seen: Dictionary = {}

	for cell in _placed.keys():
		for ncell in get_orthogonal_neighbors(cell):
			if not _placed.has(ncell):
				continue
			var key := _pair_key(cell, ncell)
			if seen.has(key):
				continue
			seen[key] = true
			var a: Dictionary = _placed[cell]
			var b: Dictionary = _placed[ncell]
			var rule := find_rule_for_elements(a.element, b.element)
			if rule == null:
				continue
			var inst := SynergyInstance.new()
			inst.rule = rule
			inst.tower_a = a.tower
			inst.tower_b = b.tower
			inst.cell_a = cell
			inst.cell_b = ncell
			_active_links.append(inst)

	for inst in _active_links:
		var was_active := false
		for old in previous:
			if old.rule == inst.rule and old.cell_a == inst.cell_a and old.cell_b == inst.cell_b:
				was_active = true
				break
		if not was_active:
			synergy_activated.emit(inst)
			notify_synergy_activated_display(inst)

	for old in previous:
		var still := false
		for inst in _active_links:
			if old.rule == inst.rule and old.cell_a == inst.cell_a and old.cell_b == inst.cell_b:
				still = true
				break
		if not still:
			synergy_deactivated.emit(old)

	registry_changed.emit()


func _pair_key(a: Vector2i, b: Vector2i) -> String:
	if a < b:
		return "%d,%d|%d,%d" % [a.x, a.y, b.x, b.y]
	return "%d,%d|%d,%d" % [b.x, b.y, a.x, a.y]


func _spawn_floating_text(instance: SynergyInstance) -> void:
	var label_scene := load("res://scenes/ui/floating_synergy_text.tscn")
	if not label_scene:
		return
	var label = label_scene.instantiate()
	var mid := (cell_to_world_center(instance.cell_a) + cell_to_world_center(instance.cell_b)) * 0.5
	label.global_position = mid
	if label.has_method("setup"):
		var text := instance.rule.display_name
		if instance.rule.visual_profile and instance.rule.visual_profile.floating_text != "":
			text = instance.rule.visual_profile.floating_text
		label.setup(text, instance.rule.visual_profile.link_color_a if instance.rule.visual_profile else Color.WHITE)
	var level := get_tree().current_scene
	if level:
		var world := level.get_node_or_null("World")
		if world:
			world.add_child(label)
