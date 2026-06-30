class_name LevelPin
extends Control
## Pin cliquable d'un niveau sur la carte du monde.
##
## Trois états : verrouillé (grisé, non cliquable), jouable, terminé
## (avec étoiles). Visuel placeholder en attendant les images
## pin_locked / pin_unlocked / pin_done (voir UI_STYLE_GUIDE.md).

signal level_selected(level: LevelData)

var _level: LevelData = null

@onready var button: Button = $Button
@onready var name_label: Label = $NameLabel
@onready var stars_label: Label = $StarsLabel


func _ready() -> void:
	button.pressed.connect(_on_pressed)


## Configure le pin depuis les données du niveau et la progression.
func setup(level: LevelData) -> void:
	_level = level
	var unlocked: bool = Progress.is_unlocked(level.level_id)
	var stars: int = Progress.get_stars(level.level_id)

	name_label.text = level.display_name
	stars_label.text = "%d/3" % stars if stars > 0 else ""
	stars_label.visible = stars > 0

	if unlocked:
		button.text = str(level.level_id)
		button.disabled = false
		modulate = Color.WHITE
	else:
		button.text = "X"
		button.disabled = true
		modulate = Color(0.55, 0.55, 0.55, 0.8)


func _on_pressed() -> void:
	Audio.ui_click()
	level_selected.emit(_level)
