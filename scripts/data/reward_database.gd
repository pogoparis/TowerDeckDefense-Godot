extends Node
class_name RewardDatabase

var rewards : Array[RewardData] = []

## Récompenses déjà prises dans la partie en cours (pas de doublon).
var taken : Array[RewardData] = []


func _ready():

	load_rewards()


## À appeler au début d'une partie : remet les récompenses dispo à zéro.
func reset_taken():
	taken.clear()


func mark_taken(reward: RewardData):
	if reward not in taken:
		taken.append(reward)


func load_rewards():

	rewards.clear()

	# Le pool est construit directement à partir des BONUS (resources/bonuses).
	# Chaque BonusData est emballé dans un RewardData à la volée (titre, desc,
	# rareté viennent du bonus). Une seule source de vérité : les fichiers bonus.
	var dir = DirAccess.open("res://resources/bonuses")

	if dir == null:
		push_error("Cannot open bonuses directory")
		return

	dir.list_dir_begin()

	var file_name = dir.get_next()

	while file_name != "":

		if file_name.ends_with(".tres"):

			var bonus = load("res://resources/bonuses/" + file_name)

			if bonus is BonusData:
				var rd := RewardData.new()
				rd.reward_type = RewardData.RewardType.BONUS
				rd.title = bonus.title
				rd.description = bonus.description
				rd.icon = bonus.icon
				rd.bonus_data = bonus
				rewards.append(rd)

		file_name = dir.get_next()

	dir.list_dir_end()


func get_random_rewards(count:int) -> Array[RewardData]:

	var result : Array[RewardData] = []

	# Pool = bonus non encore pris, et PAS de récompense de type CARD (carte-tour)
	# pour l'instant.
	var pool : Array[RewardData] = []
	for r in rewards:
		if r.reward_type == RewardData.RewardType.CARD:
			continue
		if r in taken:
			continue
		pool.append(r)

	while result.size() < count and pool.size() > 0:

		var index = randi() % pool.size()

		result.append(pool[index])

		pool.remove_at(index)

	return result
