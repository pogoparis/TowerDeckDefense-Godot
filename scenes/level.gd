extends Node2D

# === NODES ===
@onready var world := $World
@onready var tilemap: TileMapLayer = $World/TileMapLayer
@onready var path: Path2D = $World/Path2D
@onready var tower_card := $UI/TowerCardFire
@onready var path_follow_template: PathFollow2D = $World/Path2D/PathFollow2D

# === STATE ===
var selected_tower_scene: PackedScene = null
var ghost_tower: Node2D = null

# === READY ===
func _ready():
	tower_card.tower_selected.connect(_on_tower_selected)

	if path_follow_template:
		path_follow_template.process_mode = Node.PROCESS_MODE_DISABLED
		path_follow_template.set_process(false)

	spawn_wave(6, 3.2, 70.0)

	# === DEBUG ===
	print("map_to_local(0,0) = ", tilemap.map_to_local(Vector2i(0,0)))
	print("tile_size = ", tilemap.tile_set.tile_size)


# === TOWER SELECTION ===
func _on_tower_selected(scene: PackedScene):
	selected_tower_scene = scene

	if ghost_tower:
		ghost_tower.queue_free()
		ghost_tower = null

	await get_tree().process_frame

	ghost_tower = scene.instantiate()
	ghost_tower.modulate.a = 0.5
	world.add_child(ghost_tower)

	await get_tree().process_frame
	_disable_ghost_behaviors()
	_update_ghost_position()


# === GHOST UPDATE ===
func _process(_delta):
	if ghost_tower:
		_update_ghost_position()


func _update_ghost_position():
	var mouse_world: Vector2 = get_global_mouse_position()

	# Conversion MONDE → LOCAL TileMap (robuste)
	var mouse_local: Vector2 = tilemap.to_local(mouse_world)

	var cell: Vector2i = tilemap.local_to_map(mouse_local)

	var center_local: Vector2 = tilemap.map_to_local(cell)

	ghost_tower.global_position = tilemap.to_global(center_local)
	print("Cell:", cell)
	print("Center local:", center_local)
	print("Global:", tilemap.to_global(center_local))

	if is_too_close_to_path(ghost_tower.global_position, 55.0):
		ghost_tower.modulate = Color(1, 0, 0, 0.5)
	else:
		ghost_tower.modulate = Color(0, 1, 0, 0.5)


# === INPUT ===
func _unhandled_input(event):
	if not ghost_tower or not selected_tower_scene:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_ghost()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_ghost()
			get_viewport().set_input_as_handled()
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_too_close_to_path(ghost_tower.global_position, 55.0):
				get_viewport().set_input_as_handled()
				return

			var final_tower = selected_tower_scene.instantiate()
			final_tower.global_position = ghost_tower.global_position
			world.add_child(final_tower)

			if ghost_tower:
				ghost_tower.queue_free()

			ghost_tower = null
			selected_tower_scene = null

			get_viewport().set_input_as_handled()

			await get_tree().create_timer(0.1).timeout
			tower_card.reset()


func _cancel_ghost():
	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = null
	selected_tower_scene = null
	tower_card.reset()


# === DISTANCE AU PATH ===
func is_too_close_to_path(tower_pos: Vector2, min_distance: float) -> bool:
	if path == null or path.curve == null:
		return false

	var curve = path.curve
	var length = curve.get_baked_length()
	var step = 25.0

	var d = 0.0
	while d <= length:
		var path_local = curve.sample_baked(d)
		var path_world = path.to_global(path_local)

		if tower_pos.distance_to(path_world) < min_distance:
			return true

		d += step

	return false


# === GHOST CLEAN ===
func _disable_ghost_behaviors():
	if not ghost_tower:
		return

	if ghost_tower is TowerFire:
		ghost_tower.disable_behaviors()


# === ENEMY SPAWN ===
func _spawn_enemy_instance() -> PathFollow2D:
	if not path_follow_template:
		return null

	var pf: PathFollow2D = path_follow_template.duplicate()
	pf.process_mode = Node.PROCESS_MODE_INHERIT
	pf.set_process(true)
	return pf


func spawn_wave(count: int, interval: float, speed_override: float = -1.0):
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
