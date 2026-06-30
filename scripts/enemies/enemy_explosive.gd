extends EnemyBase
class_name EnemyExplosive

const EXPLOSION_RADIUS := 120.0
const EXPLOSION_DAMAGE := 40

@export var explosion_chain_scene: PackedScene

func die():
	Audio.play_sfx(preload("res://assets/audio/sfx/explosion.wav"), -4.0, 0.1)
	_chain_explosion()
	super.die()


func _chain_explosion():
	if not enemy_manager:
		return

	var pos := global_position

	for other in enemy_manager.get_all_enemies():
		if not is_instance_valid(other) or other == self:
			continue
		if pos.distance_to(other.global_position) > EXPLOSION_RADIUS:
			continue
		# take_damage affiche déjà le chiffre de dégâts ; pas de texte en double.
		other.take_damage(EXPLOSION_DAMAGE)

	if explosion_chain_scene:
		var fx := explosion_chain_scene.instantiate()
		var container := get_tree().current_scene.get_node_or_null("World/EffectsContainer")
		if container == null:
			container = get_tree().current_scene
		container.add_child(fx)
		fx.global_position = pos
