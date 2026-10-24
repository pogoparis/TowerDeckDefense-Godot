extends ProjectileTower
class_name TowerTeslaCoil

func _ready():
	super._ready()


## Effet de Charge — Tempête électrique : un champ électrique massif au pied de
## la tour (réutilise le moteur de zones : dégâts + CHARGED + stun des WET).
func _charge_effect() -> void:
	var pm := get_phenomenon_manager()
	if pm == null:
		return
	pm.spawn_phenomenon(PhenomenonType.Type.ELECTRIC_FIELD, global_position, 150.0, 7.0)
	Audio.play_sfx(preload("res://assets/audio/sfx/tesla.wav"), 0.0)


func _find_target_special() -> Node2D:
	if not enemy_manager:
		return null

	var enemies := enemy_manager.get_all_enemies()

	# Priorité : ennemis en portée qui ne sont PAS déjà stun
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > attack_range:
			continue
		if not enemy.has_status(StatusIds.STUNNED):
			return enemy

	# Fallback : n'importe quel ennemi en portée (tous déjà stun)
	return null
