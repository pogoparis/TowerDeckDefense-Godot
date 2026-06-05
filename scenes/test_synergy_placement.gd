extends Node2D

## Sandbox : valider l'UX synergies sans lancer une vague complète.

const CELL_SIZE := 64

var selected_tower_data: TowerData = null
var ghost_tower: Node2D = null
var blocked_cells: Dictionary = {}

@onready var tower_container: Node2D = $World/TowerContainer
@onready var synergy_link_layer: Node2D = $World/SynergyLinkLayer
@onready var synergy_panel: PanelContainer = $UI/SynergyPanel


func _ready() -> void:
	if SynergyManager:
		SynergyManager.reset_run_tracking()
	_place_preset_electric()
	_setup_card_buttons()


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / CELL_SIZE), floor(pos.y / CELL_SIZE))


func cell_to_world_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5)


func _place_preset_electric() -> void:
	var data: TowerData = load("res://data/towers/tower_electric.tres") as TowerData
	if not data:
		return
	var tower: TowerBase = data.tower_scene.instantiate() as TowerBase
	tower.data = data
	tower.global_position = cell_to_world_center(Vector2i(5, 5))
	tower_container.add_child(tower)


func _setup_card_buttons() -> void:
	var deck_paths := [
		"res://data/towers/tower_water.tres",
		"res://data/towers/tower_air.tres",
	]
	var x := 16.0
	for p in deck_paths:
		var data: TowerData = load(p) as TowerData
		if not data:
			continue
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(100, 120)
		btn.position = Vector2(x, 16)
		btn.texture_normal = load("res://assets/towers/tour_de_feu_1_128_comp.png")
		var script := load("res://scenes/ui/ui_tower_card.gd")
		btn.set_script(script)
		btn.tower_data = data
		btn.tower_selected.connect(_on_tower_selected)
		$UI.add_child(btn)
		x += 120.0


func _on_tower_selected(data: TowerData) -> void:
	selected_tower_data = data
	if ghost_tower:
		ghost_tower.queue_free()
	ghost_tower = data.tower_scene.instantiate()
	if ghost_tower is TowerBase:
		(ghost_tower as TowerBase).data = data
	ghost_tower.set_meta("is_ghost", true)
	ghost_tower.modulate.a = 0.5
	$World.add_child(ghost_tower)
	if ghost_tower is TowerBase:
		(ghost_tower as TowerBase).disable_behaviors()


func _process(_delta: float) -> void:
	if ghost_tower:
		var cell := world_to_cell(get_global_mouse_position())
		ghost_tower.global_position = cell_to_world_center(cell)
	if synergy_panel and synergy_panel.has_method("_refresh"):
		synergy_panel._refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		if ghost_tower:
			ghost_tower.queue_free()
			ghost_tower = null
		selected_tower_data = null
		if synergy_link_layer.has_method("clear_preview"):
			synergy_link_layer.clear_preview()
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not ghost_tower or not selected_tower_data:
		return
	var cell := world_to_cell(ghost_tower.global_position)
	if blocked_cells.has(cell):
		return
	var tower: TowerBase = selected_tower_data.tower_scene.instantiate() as TowerBase
	tower.data = selected_tower_data
	tower.global_position = cell_to_world_center(cell)
	tower_container.add_child(tower)
	blocked_cells[cell] = true
	ghost_tower.queue_free()
	ghost_tower = null
	selected_tower_data = null
