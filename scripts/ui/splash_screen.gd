class_name SplashScreen
extends Control
## Écran de chargement affiché au lancement du jeu (scène principale du projet).
##
## Affiche l'illustration de fond, une barre de progression et des messages
## de chargement, puis enchaîne sur le menu principal.
## Un clic ou une touche passe directement au menu.
## Aucun style ne doit être défini dans ce script (voir junkriot_theme.tres).

## Scène affichée à la fin du chargement.
@export_file("*.tscn") var next_scene_path: String = "res://scenes/ui/MainMenu.tscn"
## Messages affichés pendant le faux chargement, dans l'ordre.
@export var loading_messages: PackedStringArray = [
	"Chargement en cours...",
	"Initialisation des ressources...",
	"Chargement des assets...",
	"Vérification des mises à jour...",
	"Mise à jour si nécessaire...",
	"Préparation du Scrapyard...",
]
## Durée d'affichage de chaque message (secondes).
@export var step_duration: float = 0.55
## Durée des fondus d'entrée et de sortie (secondes).
@export var fade_duration: float = 0.6

var _skipped: bool = false

@onready var overlay: ColorRect = $FadeOverlay
@onready var status_label: Label = $BottomBar/StatusLabel
@onready var progress_bar: ProgressBar = $BottomBar/ProgressBar


func _ready() -> void:
	overlay.color = Color(0, 0, 0, 1)
	status_label.text = ""
	progress_bar.value = 0.0
	Audio.play_menu_music()
	_run()


func _input(event: InputEvent) -> void:
	if _skipped:
		return
	var clicked: bool = event is InputEventMouseButton and (event as InputEventMouseButton).pressed
	var key_hit: bool = event is InputEventKey and (event as InputEventKey).pressed
	if clicked or key_hit:
		_skipped = true


func _run() -> void:
	var tween_in := create_tween()
	tween_in.tween_property(overlay, "color:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE)
	await tween_in.finished

	var step_count: int = loading_messages.size()
	for i in step_count:
		if _skipped:
			break
		status_label.text = loading_messages[i]
		var target: float = float(i + 1) / float(step_count)
		var tween := create_tween()
		tween.tween_property(progress_bar, "value", target, step_duration) \
			.set_trans(Tween.TRANS_QUAD)
		if not is_inside_tree():
			return
		await get_tree().create_timer(step_duration).timeout

	_go_to_next_scene()


func _go_to_next_scene() -> void:
	status_label.text = ""
	var tween_out := create_tween()
	tween_out.tween_property(overlay, "color:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE)
	await tween_out.finished
	get_tree().change_scene_to_file(next_scene_path)
