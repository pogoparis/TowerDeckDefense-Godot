class_name PlacementManager
extends Node

var selected_tower_scene: PackedScene = null
var ghost_tower: Node2D = null

func start_placing_tower(scene: PackedScene):

	selected_tower_scene = scene
	

func clear_placement():

	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = null
	selected_tower_scene = null

func create_ghost(scene: PackedScene, parent: Node):

	if ghost_tower:
		ghost_tower.queue_free()

	ghost_tower = scene.instantiate()

	parent.add_child(ghost_tower)

	ghost_tower.z_index = 999
	ghost_tower.modulate = Color(0, 1, 0, 0.5)
