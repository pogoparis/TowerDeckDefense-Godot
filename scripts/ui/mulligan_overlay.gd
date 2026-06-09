extends Control
class_name MulliganOverlay

signal validated

@onready var title_label: Label = $Content/TitleLabel
@onready var sub_label: Label = $Content/SubLabel
@onready var validate_button: Button = $Content/ValidateButton
@onready var content: VBoxContainer = $Content


func _ready():
	validate_button.pressed.connect(func(): validated.emit())

	# Le fond ne bloque pas les clics → les cartes restent cliquables
	$Background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Taille et style du contenu
	content.custom_minimum_size = Vector2(420, 0)
	content.add_theme_constant_override("separation", 16)

	title_label.add_theme_font_size_override("font_size", 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	sub_label.add_theme_font_size_override("font_size", 18)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	validate_button.custom_minimum_size = Vector2(200, 56)
	validate_button.add_theme_font_size_override("font_size", 22)

	title_label.text = "PHASE DE MULLIGAN"
	sub_label.text = "Sélectionnez les cartes à remplacer (max 3)"

	visible = false


func show_phase():
	update_count(0)
	visible = true


func hide_phase():
	visible = false


func update_count(count: int):
	if count == 0:
		sub_label.text = "Sélectionnez les cartes à remplacer (max 3)"
	else:
		sub_label.text = "%d/3 carte(s) sélectionnée(s)" % count
