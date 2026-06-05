extends Node2D

# === NODES ===
@onready var world := $World
@onready var path: Path2D = $World/Path2D
@onready var tower_cards := $UI/TowerDeck
@onready var path_follow_template: PathFollow2D = $World/Path2D/PathFollow2D
@onready var synergy_panel: PanelContainer = $UI/SynergyPanel
@onready var synergy_link_layer: Node2D = $World/SynergyLinkLayer
@onready var synergy_preview_layer: Node2D = $World/SynergyPreviewLayer

# === STATE ===
var selected_tower_data: TowerData = null
var ghost_tower: Node2D = null
const CELL_SIZE := 64
var blocked_cells := {}
var selected_tower: Node2D = null

# === READY ===
func _ready() -> void:
	if SynergyManager:
		SynergyManager.reset_run_tracking()
	_connect_tower_cards()

	if path_follow_template:
		path_follow_template.process_mode = Node.PROCESS_MODE_DISABLED
		path_follow_template.set_process(false)

	spawn_wave(6, 3.2, 70.0)
	block_path_cells()


func _connect_tower_cards() -> void:
	if not tower_cards:
		return
	for child in tower_cards.get_children():
		if child.has_signal("tower_selected"):
			if not child.tower_selected.is_connected(_on_tower_selected):
				child.tower_selected.connect(_on_tower_selected)


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(pos.x / CELL_SIZE),
		floor(pos.y / CELL_SIZE)
	)


func cell_to_world_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE * 0.5,
		cell.y * CELL_SIZE + CELL_SIZE * 0.5
	)


func block_path_cells() -> void:
	if path == null or path.curve == null:
		return

	var curve = path.curve
	var length = curve.get_baked_length()
	var step = 8.0

	var d := 0.0
	while d <= length:
		var local_point = curve.sample_baked(d)
		var world_point = path.to_global(local_point)
		var cell = world_to_cell(world_point)
		blocked_cells[cell] = true
		d += step


# === TOWER SELECTION ===
func _on_tower_selected(data: TowerData) -> void:
	selected_tower_data = data
	if not data or not data.tower_scene:
		return

	if ghost_tower:
		ghost_tower.queue_free()
		ghost_tower = null

	await get_tree().process_frame

	ghost_tower = data.tower_scene.instantiate()
	if ghost_tower is TowerBase:
		(ghost_tower as TowerBase).data = data
	ghost_tower.set_meta("is_ghost", true)
	ghost_tower.modulate.a = 0.5
	world.add_child(ghost_tower)

	await get_tree().process_frame
	_disable_ghost_behaviors()
	_update_ghost_position()
	_refresh_synergy_ui()


func _refresh_synergy_ui() -> void:
	if synergy_panel and synergy_panel.has_method("_refresh"):
		synergy_panel._refresh()


# === GHOST UPDATE ===
func _process(_delta: float) -> void:
	if ghost_tower:
		_update_ghost_position()
		_refresh_synergy_ui()
	queue_redraw()


func _update_ghost_position() -> void:
	var mouse_world = get_global_mouse_position()
	var cell = world_to_cell(mouse_world)
	ghost_tower.global_position = cell_to_world_center(cell)

	if blocked_cells.has(cell):
		ghost_tower.modulate = Color(1, 0, 0, 0.5)
	else:
		var base_color := selected_tower_data.element_color if selected_tower_data else Color(0, 1, 0)
		ghost_tower.modulate = Color(base_color.r, base_color.g, base_color.b, 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()

		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_ghost()
			selected_tower = null
			get_viewport().set_input_as_handled()
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			for tower in $World/TowerContainer.get_children():
				if tower is TowerBase:
					if mouse_pos.distance_to(tower.global_position) < 32:
						selected_tower = tower
						_cancel_ghost()
						get_viewport().set_input_as_handled()
						return

			selected_tower = null

			if ghost_tower and selected_tower_data:
				var cell = world_to_cell(ghost_tower.global_position)

				if blocked_cells.has(cell):
					get_viewport().set_input_as_handled()
					return

				var final_tower: Node2D = selected_tower_data.tower_scene.instantiate()
				if final_tower is TowerBase:
					(final_tower as TowerBase).data = selected_tower_data
				final_tower.global_position = cell_to_world_center(cell)
				$World/TowerContainer.add_child(final_tower)

				if final_tower is TowerBase:
					(final_tower as TowerBase).grid_cell = cell

				blocked_cells[cell] = true

				ghost_tower.queue_free()
				ghost_tower = null
				selected_tower_data = null

				if synergy_link_layer:
					synergy_link_layer.clear_preview()

				get_viewport().set_input_as_handled()
				_reset_tower_cards()
				_refresh_synergy_ui()


func _cancel_ghost() -> void:
	if ghost_tower:
		ghost_tower.queue_free()
	ghost_tower = null
	selected_tower_data = null
	if synergy_link_layer and synergy_link_layer.has_method("clear_preview"):
		synergy_link_layer.clear_preview()
	_reset_tower_cards()
	_refresh_synergy_ui()


func _reset_tower_cards() -> void:
	if not tower_cards:
		return
	for child in tower_cards.get_children():
		if child.has_method("reset"):
			child.reset()


func _disable_ghost_behaviors() -> void:
	if not ghost_tower:
		return
	if ghost_tower is TowerBase:
		(ghost_tower as TowerBase).disable_behaviors()
	elif ghost_tower.has_method("disable_behaviors"):
		ghost_tower.disable_behaviors()


func complete_run_for_guide() -> void:
	if SynergyGuideService:
		SynergyGuideService.record_run_completed()


# === ENEMY SPAWN ===
func _spawn_enemy_instance() -> PathFollow2D:
	if not path_follow_template:
		return null
	var pf: PathFollow2D = path_follow_template.duplicate()
	pf.process_mode = Node.PROCESS_MODE_INHERIT
	pf.set_process(true)
	return pf


func spawn_wave(count: int, interval: float, speed_override: float = -1.0) -> void:
	if not path:
		return
	for i in range(count):
		var pf = _spawn_enemy_instance()
		if pf:
			if speed_override > 0:
				pf.speed = speed_override
			path.add_child(pf)
			pf.progress = 0
		await get_tree().create_timer(interval).timeout
