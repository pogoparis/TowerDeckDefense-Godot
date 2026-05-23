class_name PlacementManager
extends Node

var selected_tower_scene: PackedScene = null
var ghost_tower: Node2D = null

func start_placing_tower(scene: PackedScene):

	selected_tower_scene = scene
