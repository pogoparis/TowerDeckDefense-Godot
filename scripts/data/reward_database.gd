extends Node
class_name RewardDatabase

var rewards : Array[RewardData] = []


func _ready():

	load_rewards()


func load_rewards():

	rewards.clear()

	var dir = DirAccess.open("res://resources/rewards")

	if dir == null:
		push_error("Cannot open rewards directory")
		return

	dir.list_dir_begin()

	var file_name = dir.get_next()

	while file_name != "":

		if file_name.ends_with(".tres"):

			var reward = load(
				"res://resources/rewards/" + file_name
			)

			if reward:
				rewards.append(reward)

		file_name = dir.get_next()

	dir.list_dir_end()


func get_random_rewards(count:int) -> Array[RewardData]:

	var result : Array[RewardData] = []

	var pool = rewards.duplicate()

	while result.size() < count and pool.size() > 0:

		var index = randi() % pool.size()

		result.append(pool[index])

		pool.remove_at(index)

	return result
