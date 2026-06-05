class_name TowerBase
extends Node2D

@export var data: TowerData

var attack_range: float = 60.0
var fire_rate: float = 0.8
var damage: int = 10
var projectile_scene: PackedScene

var grid_cell: Vector2i = Vector2i.ZERO
var _phenomenon_timer: Timer
var _combat_timer: Timer
var _area: Area2D
var _targets: Array = []


func _ready() -> void:
	if data:
		attack_range = data.attack_range
		fire_rate = data.fire_rate
		damage = data.damage
		projectile_scene = data.projectile_scene
		if data.element_color != Color.WHITE:
			var sprite := get_node_or_null("Sprite2D") as Sprite2D
			if sprite:
				sprite.modulate = data.element_color

	_setup_detection()
	_setup_phenomenon_timer()
	_setup_combat_timer()
	_register_synergy()
	queue_redraw()


func _exit_tree() -> void:
	if SynergyManager:
		SynergyManager.unregister_tower(self)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 5, data.element_color if data else Color.GRAY)


func _register_synergy() -> void:
	if not data or not SynergyManager:
		return
	var level := _find_level()
	if level and level.has_method("world_to_cell"):
		grid_cell = level.world_to_cell(global_position)
	SynergyManager.register_tower(self, grid_cell, data.element, data)


func _find_level() -> Node:
	var n: Node = self
	while n:
		if n.has_method("world_to_cell"):
			return n
		n = n.get_parent()
	return null


func _setup_detection() -> void:
	_area = get_node_or_null("DetectionArea") as Area2D
	if not _area:
		return
	var col := _area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = attack_range
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)


func _setup_phenomenon_timer() -> void:
	_phenomenon_timer = Timer.new()
	_phenomenon_timer.name = "PhenomenonTimer"
	add_child(_phenomenon_timer)
	var interval := data.base_phenomenon_interval if data else 3.0
	_phenomenon_timer.wait_time = interval
	_phenomenon_timer.timeout.connect(_spawn_phenomenon)
	_phenomenon_timer.start()


func _setup_combat_timer() -> void:
	if not projectile_scene:
		return
	_combat_timer = get_node_or_null("Timer") as Timer
	if not _combat_timer:
		return
	_combat_timer.wait_time = fire_rate
	if not _combat_timer.timeout.is_connected(_on_combat_timeout):
		_combat_timer.timeout.connect(_on_combat_timeout)


func _spawn_phenomenon() -> void:
	if not data or not PhenomenonManager:
		return
	var mult := SynergyManager.get_generation_multiplier_for(self) if SynergyManager else 1.0
	_phenomenon_timer.wait_time = data.base_phenomenon_interval / mult
	PhenomenonManager.spawn_from_tower(self, mult)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		_targets.append(body)


func _on_body_exited(body: Node) -> void:
	_targets.erase(body)


func _on_combat_timeout() -> void:
	if not projectile_scene or _targets.is_empty():
		return
	var target = _targets[0]
	if not is_instance_valid(target):
		return
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	if "target" in projectile:
		projectile.target = target
	if "damage" in projectile:
		projectile.damage = damage
	var tint := SynergyManager.get_projectile_tint_for(self) if SynergyManager else Color.WHITE
	if "modulate" in projectile:
		projectile.modulate = tint
	get_parent().add_child(projectile)


func disable_behaviors() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	set_process(false)
	set_physics_process(false)
	if _area:
		_area.monitoring = false
		_area.monitorable = false
	if _phenomenon_timer:
		_phenomenon_timer.stop()
	if _combat_timer:
		_combat_timer.stop()
	projectile_scene = null


func get_element() -> JunkElement.Type:
	return data.element if data else JunkElement.Type.FIRE


func get_tower_data() -> TowerData:
	return data
