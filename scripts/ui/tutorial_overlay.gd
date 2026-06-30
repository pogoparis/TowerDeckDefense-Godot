class_name TutorialOverlay
extends Control
## Tutoriel modal affiché avant la dernière vague (miniboss).
##
## Met le jeu en pause, affiche un message explicatif, et reprend quand le
## joueur clique sur « Compris ! ». Tout le texte est éditable dans l'inspecteur.
## Le style vient de junkriot_theme.tres — rien de codé ici.

signal closed

@export var title_text: String = "DERNIÈRE VAGUE !"
@export_multiline var body_text: String = (
	"Une nuée de petits ennemis arrive — tes TOURS devraient suffire à les nettoyer.\n\n"
	+ "Mais juste après débarque un MINIBOSS : il ENCAISSE les tirs des tours.\n"
	+ "Seuls les PHÉNOMÈNES peuvent l'arrêter !\n\n"
	+ "LE SECRET : superpose une FLAQUE D'EAU et un CHAMP ÉLECTRIQUE au même endroit\n"
	+ "→ ÉLECTROCUTION ⚡ = dégâts ÉNORMES !\n\n"
	+ "(Tu as de quoi déclencher deux phénomènes. Consomme tes cartes !)"
)
@export var button_text: String = "COMPRIS !"

@onready var title_label: Label = $Center/Box/Margin/VBox/TitleLabel
@onready var body_label: Label = $Center/Box/Margin/VBox/BodyLabel
@onready var continue_button: Button = $Center/Box/Margin/VBox/ContinueButton


func _ready() -> void:
	visible = false
	title_label.text = title_text
	body_label.text = body_text
	continue_button.text = button_text


## Affiche le tutoriel, met le jeu en pause, et attend le clic du joueur.
## [param title]/[param body] remplacent les textes par défaut si fournis.
func show_and_wait(title: String = "", body: String = "") -> void:
	title_label.text = title if title != "" else title_text
	body_label.text = body if body != "" else body_text
	visible = true
	get_tree().paused = true

	await continue_button.pressed

	Audio.ui_click()
	get_tree().paused = false
	visible = false
	closed.emit()
