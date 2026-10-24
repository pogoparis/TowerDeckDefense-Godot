extends ProjectileTower
class_name TowerVampire
## Tour signature OMBRE — le Punk Vampire et son canon à toile.
##
## Rôle : SUPPORT / amplificateur. Ses tirs appliquent la MARQUE D'OMBRE, qui
## fait encaisser +40% de dégâts de TOUTES les sources à l'ennemi marqué.
## Sa force n'est donc pas son DPS brut, mais ce qu'elle fait gagner aux
## tours voisines → elle récompense un bon placement.

func _ready():
	super._ready()


## Cible en priorité l'ennemi le plus avancé qui n'est PAS encore marqué
## (évite de gaspiller des tirs à re-marquer la même cible).
func _find_target_special() -> Node2D:
	if not enemy_manager:
		return null

	var best: Node2D = null
	var best_progress := -1.0
	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > attack_range:
			continue
		if enemy.has_status(StatusIds.MARKED):
			continue
		var pf := enemy.get_parent() as PathFollow2D
		var progress: float = pf.progress if pf != null else 0.0
		if progress > best_progress:
			best_progress = progress
			best = enemy
	if best:
		return best

	# Fallback : le plus avancé à portée (même déjà marqué).
	return null


## Effet de Charge — NUÉE DE CHAUVES-SOURIS : une nappe d'ombre qui draine la
## vie en continu ET marque tous les ennemis pris dedans (ils encaissent
## ensuite +40% de tout). Combo redoutable avec les tours de dégâts voisines.
func _charge_effect() -> void:
	var pm := get_phenomenon_manager()
	if pm == null:
		return
	# Charge AUTOMATIQUE (tous les 8 tirs) : la zone doit être plus petite et
	# plus courte qu'une Charge signature, sinon une nuée permanente couvrirait
	# le terrain sans que le joueur n'ait rien décidé.
	pm.spawn_phenomenon(PhenomenonType.Type.SHADOW_ZONE, global_position, 120.0, 4.0)
