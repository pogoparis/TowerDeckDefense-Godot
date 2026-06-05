extends Node

signal reaction_triggered(reaction_id: String, position: Vector2)

const REACTION_ELECTROCUTION := "electrocution"
const REACTION_STORM := "storm"

var _cooldowns: Dictionary = {}
const COOLDOWN_SEC := 1.5


func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.autostart = true
	timer.timeout.connect(_scan_phenomena)
	add_child(timer)


func _scan_phenomena() -> void:
	var phenomena := get_tree().get_nodes_in_group("phenomena")
	for i in range(phenomena.size()):
		var a: PhenomenonBase = phenomena[i] as PhenomenonBase
		if not a:
			continue
		for j in range(i + 1, phenomena.size()):
			var b: PhenomenonBase = phenomena[j] as PhenomenonBase
			if not b or not a.overlaps(b):
				continue
			_try_reaction(a, b)


func _try_reaction(a: PhenomenonBase, b: PhenomenonBase) -> void:
	var types := [a.element, b.element]
	if _has_elements(types, JunkElement.Type.WATER, JunkElement.Type.ELECTRIC):
		_trigger(REACTION_ELECTROCUTION, (a.global_position + b.global_position) * 0.5, Color(0.3, 0.8, 1.0))
	elif _has_elements(types, JunkElement.Type.ELECTRIC, JunkElement.Type.AIR):
		_trigger(REACTION_STORM, (a.global_position + b.global_position) * 0.5, Color(0.9, 0.95, 1.0))


func _has_elements(types: Array, e1: JunkElement.Type, e2: JunkElement.Type) -> bool:
	return (e1 in types and e2 in types)


func _trigger(reaction_id: String, pos: Vector2, color: Color) -> void:
	var key := reaction_id
	var now := Time.get_ticks_msec() / 1000.0
	if _cooldowns.has(key) and now - _cooldowns[key] < COOLDOWN_SEC:
		return
	_cooldowns[key] = now
	reaction_triggered.emit(reaction_id, pos)
	_apply_reaction_damage(reaction_id, pos)
	_spawn_reaction_vfx(reaction_id, pos, color)


func _apply_reaction_damage(reaction_id: String, pos: Vector2) -> void:
	var radius := 40.0 if reaction_id == REACTION_ELECTROCUTION else 55.0
	var damage := 15 if reaction_id == REACTION_ELECTROCUTION else 12
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(pos) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
			if reaction_id == REACTION_ELECTROCUTION and enemy.has_method("apply_paralyze"):
				enemy.apply_paralyze(0.8)


func _spawn_reaction_vfx(reaction_id: String, pos: Vector2, color: Color) -> void:
	var vfx_scene := load("res://scenes/reactions/reaction_burst.tscn")
	if not vfx_scene:
		return
	var vfx = vfx_scene.instantiate()
	vfx.global_position = pos
	if vfx.has_method("setup"):
		vfx.setup(reaction_id, color)
	var world := get_tree().current_scene.get_node_or_null("World") if get_tree().current_scene else null
	if world:
		world.add_child(vfx)
