extends Button
class_name RewardCard

signal reward_clicked(reward_data)

@onready var art: TextureRect = $Art

var reward_data : RewardData


func setup(data: RewardData):
	reward_data = data
	# La carte de bonus est une illustration complète (titre + effet + rareté
	# bakés dans l'image). On affiche juste l'art.
	if data.icon:
		art.texture = data.icon


func _pressed():
	reward_clicked.emit(reward_data)
