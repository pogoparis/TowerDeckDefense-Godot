extends Node2D
class_name BaseProjectile

var target: Node2D
var damage := 10
var source_tower: BaseTower
var homing_strength := 0.0

@export var speed := 500.0
@export var hit_distance := 12.0
@export var impact_scene: PackedScene


## Élément porté par ce tir : celui de la tour qui l'a lancé. Centralisé ici
## pour que chaque projectile n'ait pas à le recopier — et pour qu'ajouter un
## élément à une tour suffise à faire jouer les faiblesses des ennemis.
func hit_element() -> ElementType.Type:
	if source_tower != null and is_instance_valid(source_tower):
		return source_tower.element_type
	return ElementType.Type.NONE


func _process(delta):

	if not is_instance_valid(target):
		queue_free()
		return

	var dir = global_position.direction_to(target.global_position)

	rotation = dir.angle()
	global_position += dir * speed * delta

	if global_position.distance_to(target.global_position) <= hit_distance:

		on_hit(target)

		spawn_impact()

		queue_free()


func on_hit(_target):
	pass


func spawn_impact():

	if not impact_scene:
		return

	var impact = impact_scene.instantiate()

	get_parent().add_child(impact)
	impact.global_position = global_position


func spawn_tower_phenomenon(_target):
	pass
