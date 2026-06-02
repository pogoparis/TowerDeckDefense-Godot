extends TextureButton

signal card_clicked(card_data)

var card_data : CardData

func setup(data: CardData):

	card_data = data
	texture_normal = data.card_texture

func _pressed():

	card_clicked.emit(card_data)
