extends PanelContainer
class_name CardActionPanel

signal build_pressed
signal consume_pressed

@onready var build_button: Button = $HBoxContainer/BuildButton
@onready var consume_button: Button = $HBoxContainer/ConsumeButton


func _ready():
	build_button.pressed.connect(func(): build_pressed.emit())
	consume_button.pressed.connect(func(): consume_pressed.emit())


func show_for_card(card_data: CardData, card_ui: Control):

	# Positionne le panel au-dessus de la carte
	var card_global_pos = card_ui.get_global_rect().get_center()
	global_position = card_global_pos + Vector2(-size.x / 2.0, -size.y - 80)

	# Masque "DÉFAUSSER" si la carte ne peut pas être consommée
	consume_button.visible = card_data.can_consume()

	visible = true


func hide_panel():

	visible = false
