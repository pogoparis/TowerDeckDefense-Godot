class_name MulliganOverlay
extends Control
## Overlay de la phase de mulligan (sélection des cartes à remplacer).
##
## Le fond et l'overlay ne bloquent pas les clics (mouse_filter = IGNORE
## dans la scène) afin que les cartes en main restent cliquables.
## Tout le style vient de junkriot_theme.tres — rien dans ce script.

signal validated

## Titre affiché pour le mulligan complet de début de partie.
@export var full_mulligan_title: String = "PHASE DE MULLIGAN"
## Titre affiché pour l'échange d'une carte entre les vagues.
@export var exchange_title: String = "ÉCHANGE INTER-VAGUE"

var _max_cards: int = 3

@onready var title_label: Label = $Content/TitleLabel
@onready var sub_label: Label = $Content/SubLabel
@onready var validate_button: Button = $Content/ValidateButton


func _ready() -> void:
	visible = false
	validate_button.pressed.connect(func() -> void: validated.emit())
	validate_button.pressed.connect(Audio.ui_click)


## Affiche l'overlay. [param max_cards] = nombre maximum de cartes échangeables.
func show_phase(max_cards: int = 3) -> void:
	_max_cards = max_cards
	title_label.text = full_mulligan_title if max_cards >= 3 else exchange_title
	update_count(0)
	visible = true


func hide_phase() -> void:
	visible = false


## Met à jour le compteur de cartes sélectionnées.
func update_count(count: int) -> void:
	if count == 0:
		sub_label.text = "Sélectionnez jusqu'à %d carte(s) à remplacer" % _max_cards
	else:
		sub_label.text = "%d/%d carte(s) sélectionnée(s)" % [count, _max_cards]
