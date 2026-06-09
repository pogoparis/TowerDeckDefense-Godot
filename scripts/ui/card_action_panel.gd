extends PanelContainer
class_name CardActionPanel

signal consume_pressed

@onready var build_button: Button = $HBoxContainer/BuildButton
@onready var consume_button: Button = $HBoxContainer/ConsumeButton


func _ready():
	# Le BUILD se fait par drag — ce panel ne sert qu'à CONSOMMER
	build_button.visible = false
	consume_button.pressed.connect(func(): consume_pressed.emit())


func show_for_card(card_data: CardData, card_ui: Control):

	if not card_data.can_consume():
		return

	var card_global_pos = card_ui.get_global_rect().get_center()
	global_position = card_global_pos + Vector2(-size.x / 2.0, -size.y - 80)

	visible = true


func hide_panel():

	visible = false
