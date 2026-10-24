extends PanelContainer
class_name CardActionPanel

## Le mécanisme CONSUME (défausser une carte → phénomène) a été retiré.
## Ce panneau est dormant en attendant le futur panneau d'actions de Sorts.

@onready var build_button: Button = $HBoxContainer/BuildButton
@onready var consume_button: Button = $HBoxContainer/ConsumeButton


func _ready():
	visible = false
	build_button.visible = false
	consume_button.visible = false


func hide_panel():
	visible = false
