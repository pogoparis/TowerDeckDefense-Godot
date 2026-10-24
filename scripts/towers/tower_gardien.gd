extends ProjectileTower
class_name TowerGardien
## Tour signature TERRE — le Gardien Rocheux et son lance-pierre.
##
## Rôle : ANTI-BLINDÉ. Tirs lents mais très lourds — mauvais contre une nuée,
## excellent contre les Tanks, qui dominent les vagues tardives. C'est la tour
## qu'on va chercher quand le mur de tanks arrive.
##
## Sa Charge, la PLUIE DE PIERRE, écrase une zone entière d'impacts lourds.

func _ready():
	super._ready()


## Cible en priorité l'ennemi le plus RÉSISTANT à portée (le plus gros tas de
## PV), pas le plus avancé : ses cailloux doivent partir sur les blindés,
## pas sur la piétaille.
func _find_target_special() -> Node2D:
	if not enemy_manager:
		return null

	var best: Node2D = null
	var best_hp := -1
	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > attack_range:
			continue
		var eb := enemy as EnemyBase
		if eb == null:
			continue
		if eb.hp > best_hp:
			best_hp = eb.hp
			best = enemy
	if best:
		return best

	return null


## Effet de Charge — PLUIE DE PIERRE : une zone martelée d'impacts lourds
## pendant plusieurs secondes. Le nettoyeur de blindés.
func _charge_effect() -> void:
	var pm := get_phenomenon_manager()
	if pm == null:
		return
	pm.spawn_phenomenon(PhenomenonType.Type.STONE_RAIN, global_position, 180.0, 6.0)
	Juice.shake(12.0, 0.35)
