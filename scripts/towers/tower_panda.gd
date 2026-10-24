extends ProjectileTower
class_name TowerPanda
## Tour signature NATURE — le Panda Punk et ses éclats de bambou.
##
## Rôle : TUEUR DE GROS. Ses dégâts directs sont faibles, mais son poison ronge
## en pourcentage des PV max — il ne se dévalue donc jamais quand les ennemis
## grossissent, contrairement à toutes les autres tours. C'est la réponse
## structurelle aux Tanks et aux Drones Punk des vagues tardives.
##
## Sa Charge, le BOSQUET, fait pousser des ronces qui ENRACINENT ce qui les
## traverse. Aucune autre tour ne bloque vraiment : la Chouette repousse d'un
## coup, le Pingouin ralentit. Le Panda, lui, arrête.


## Cible en priorité l'ennemi le plus RÉSISTANT à portée, et parmi eux celui qui
## n'est PAS encore empoisonné. Empiler le poison sur une cible qui l'a déjà ne
## sert à rien (la durée se rafraîchit, les dégâts ne se cumulent pas), alors
## que le propager sur un second gros double la pression.
func _find_target_special() -> Node2D:
	if not enemy_manager:
		return null

	var best: Node2D = null
	var best_score := -1

	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > attack_range:
			continue
		var eb := enemy as EnemyBase
		if eb == null:
			continue

		# Un ennemi déjà empoisonné vaut beaucoup moins qu'un ennemi sain de
		# taille comparable — d'où la division plutôt qu'une exclusion nette,
		# qui laisserait la tour inactive si tout est déjà empoisonné.
		var score := eb.hp
		if eb.has_status(StatusIds.POISONED):
			score = int(score / 4)

		if score > best_score:
			best_score = score
			best = enemy

	if best:
		return best

	return null


## Effet de Charge — BOSQUET DE BAMBOU : des ronces qui immobilisent.
func _charge_effect() -> void:
	var pm := get_phenomenon_manager()
	if pm == null:
		return
	# 5 s et pas 7 : le statut ROOTED se renouvelle tant que l'ennemi est dans
	# la zone et traîne 3 s après en être sorti, donc la durée réelle d'arrêt
	# approche déjà 8 s. Au-delà, la Charge ne serait plus un répit mais une
	# annulation de vague.
	pm.spawn_phenomenon(PhenomenonType.Type.THORN_PATCH, global_position, 165.0, 5.0)
	Juice.shake(8.0, 0.25)
