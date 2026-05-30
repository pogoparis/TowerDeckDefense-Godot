extends Button
class_name RewardCard

signal reward_clicked(reward_data)

@onready var icon_texture = $MarginContainer/VBoxContainer/Icon
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel

var reward_data : RewardData


func setup(data: RewardData):

	print("SETUP")
	print(title_label)
	print(description_label)
	
	reward_data = data

	title_label.text = data.title
	description_label.text = data.description

	if data.icon:
		icon_texture.texture = data.icon

func _pressed():

	print("CARD CLICKED : ", reward_data.title)

	reward_clicked.emit(reward_data)
	
