extends Node2D

const CELL_SIZE := 64

var _level: Node = null
var _pulse: float = 0.0
var _highlight_cells: Array[Vector2i] = []
var _highlight_color: Color = Color(1, 1, 1, 0.35)
var _partner_towers: Array[Node2D] = []
var _dimmed_towers: Array[Node2D] = []


func _ready() -> void:
	z_index = 7
	_level = get_parent().get_parent() if get_parent() else null
	if SynergyManager:
		SynergyManager.registry_changed.connect(_on_registry_changed)


func _process(delta: float) -> void:
	_pulse += delta * 3.0
	_update_preview_state()
	queue_redraw()
	_update_tower_highlights()


func _on_registry_changed() -> void:
	_update_preview_state()


func _update_preview_state() -> void:
	_highlight_cells.clear()
	_partner_towers.clear()
	_highlight_color = Color(1, 1, 1, 0.35)

	if not _level or not SynergyGuideService.should_show_placement_halos():
		_clear_link_preview()
		return
	if not _level.get("ghost_tower") or _level.ghost_tower == null:
		_clear_link_preview()
		return
	if not _level.get("selected_tower_data") or _level.selected_tower_data == null:
		return

	var ghost: Node2D = _level.ghost_tower
	var cell: Vector2i = _level.world_to_cell(ghost.global_position)
	var element: JunkElement.Type = _level.selected_tower_data.element
	var preview: Dictionary = SynergyManager.get_preview_synergies(element, cell)

	for inst in preview.get("possible", []):
		if inst is SynergyInstance and inst.rule and inst.rule.visual_profile:
			_highlight_cells.append(inst.cell_b)
			if _highlight_color == Color(1, 1, 1, 0.35):
				_highlight_color = inst.rule.visual_profile.cell_highlight

	for t in preview.get("partner_towers", []):
		if t is Node2D:
			_partner_towers.append(t)

	_refresh_link_preview(preview.get("possible", []))


func _clear_link_preview() -> void:
	var link_layer := get_parent().get_node_or_null("SynergyLinkLayer")
	if link_layer and link_layer.has_method("clear_preview"):
		link_layer.clear_preview()


func _refresh_link_preview(possible: Array) -> void:
	var link_layer := get_parent().get_node_or_null("SynergyLinkLayer")
	if link_layer and link_layer.has_method("refresh_preview"):
		link_layer.refresh_preview(possible)


func _update_tower_highlights() -> void:
	for t in _dimmed_towers:
		if is_instance_valid(t):
			t.modulate = Color(1, 1, 1, 1)
	_dimmed_towers.clear()

	if not SynergyGuideService.should_show_partner_dimming():
		return
	if _partner_towers.is_empty() and _highlight_cells.is_empty():
		return

	var container: Node = get_parent().get_node_or_null("TowerContainer")
	if not container:
		return

	for child in container.get_children():
		if not (child is Node2D):
			continue
		if child in _partner_towers:
			child.modulate = Color(1.2, 1.2, 1.2, 1.0)
		elif _level and _level.get("ghost_tower") and _level.ghost_tower:
			child.modulate = Color(1, 1, 1, 0.55)
			_dimmed_towers.append(child)


func _draw() -> void:
	if not SynergyGuideService.should_show_placement_halos():
		return

	var pulse_alpha := 0.25 + 0.15 * sin(_pulse)

	for cell in _highlight_cells:
		var top_left := Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)
		var c := _highlight_color
		c.a = pulse_alpha * 1.2
		draw_rect(Rect2(top_left, Vector2(CELL_SIZE, CELL_SIZE)), c, true)
		var border := _highlight_color.lightened(0.3)
		border.a = 0.85
		draw_rect(Rect2(top_left, Vector2(CELL_SIZE, CELL_SIZE)), border, false, 3.0)

	if _level and _level.get("ghost_tower") and _level.ghost_tower:
		var ghost_cell: Vector2i = _level.world_to_cell(_level.ghost_tower.global_position)
		for ncell in SynergyManager.get_orthogonal_neighbors(ghost_cell):
			if ncell in _highlight_cells:
				continue
			var top_left := Vector2(ncell.x * CELL_SIZE, ncell.y * CELL_SIZE)
			draw_rect(Rect2(top_left, Vector2(CELL_SIZE, CELL_SIZE)), Color(1, 1, 1, 0.06), true)
