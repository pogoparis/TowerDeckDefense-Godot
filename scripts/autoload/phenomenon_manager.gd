extends Node

const PHENOMENON_SCENE := preload("res://scenes/phenomenon/Phenomenon.tscn")


func spawn_from_tower(tower: TowerBase, generation_multiplier: float = 1.0) -> void:
	if not tower or not tower.data:
		return
	var world := _get_world_container(tower)
	if not world:
		return

	var spawn_pos := _find_path_spawn_position(tower)
	var phen: PhenomenonBase = PHENOMENON_SCENE.instantiate()
	phen.element = tower.data.element
	phen.phenomenon_type = tower.data.phenomenon_type
	phen.radius = tower.data.phenomenon_radius
	phen.max_duration = tower.data.phenomenon_duration
	phen.tint = tower.data.element_color
	phen.source_tower = tower
	phen.generation_multiplier = generation_multiplier

	var size_mult := SynergyManager.get_phenomenon_size_multiplier_for(tower) if SynergyManager else 1.0
	phen.radius *= size_mult

	phen.global_position = spawn_pos
	world.add_child(phen)


func _find_path_spawn_position(tower: Node2D) -> Vector2:
	var path: Path2D = _find_path(tower)
	if not path or not path.curve:
		return tower.global_position

	var curve := path.curve
	var length := curve.get_baked_length()
	var closest_dist := INF
	var closest_point := tower.global_position

	var d := 0.0
	while d <= length:
		var local_point := curve.sample_baked(d)
		var world_point := path.to_global(local_point)
		var dist := tower.global_position.distance_to(world_point)
		if dist < closest_dist:
			closest_dist = dist
			closest_point = world_point
		d += 12.0

	return closest_point


func _find_path(from: Node) -> Path2D:
	var level := from.get_tree().current_scene
	if level:
		return level.get_node_or_null("World/Path2D") as Path2D
	return null


func _get_world_container(tower: Node) -> Node:
	var level := tower.get_tree().current_scene
	if level:
		return level.get_node_or_null("World/PhenomenonContainer")
	return null
