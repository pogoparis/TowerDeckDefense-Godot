class_name MainMenu
extends Control
## Menu principal du jeu.
##
## Les boutons sont des zones cliquables invisibles (variation GhostButton)
## posées sur les boutons dessinés dans l'illustration de fond.
## Elles vivent dans un AspectRatioContainer (ImageAnchor) dont le ratio
## correspond à celui de l'image : les zones suivent l'image quelle que
## soit la taille de la fenêtre. Si l'image change : mettre à jour
## ImageAnchor.ratio (largeur/hauteur) et ajuster les anchors des boutons
## dans l'éditeur. Aucun style ne doit être défini dans ce script.

## Scène de jeu lancée par le bouton JOUER.
@export_file("*.tscn") var game_scene_path: String = "res://scenes/ui/level.tscn"
## Durée du fondu d'entrée (depuis le noir).
@export var fade_in_duration: float = 0.6
## Durée du fondu de sortie (vers le jeu).
@export var fade_out_duration: float = 0.4

@onready var btn_play: Button = $ImageAnchor/Buttons/BtnPlay
@onready var btn_connect: Button = $ImageAnchor/Buttons/BtnConnect
@onready var btn_options: Button = $ImageAnchor/Buttons/BtnOptions
@onready var btn_quit: Button = $ImageAnchor/Buttons/BtnQuit
@onready var panel_options: Panel = $PanelOptions
@onready var btn_back: Button = $PanelOptions/VBox/BtnBack
@onready var sfx_slider: HSlider = $PanelOptions/VBox/SFXRow/SFXSlider
@onready var music_slider: HSlider = $PanelOptions/VBox/MusicRow/MusicSlider
@onready var overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	overlay.color = Color(0, 0, 0, 1)
	panel_options.visible = false
	Audio.play_menu_music()

	btn_play.pressed.connect(_on_play_pressed)
	btn_connect.pressed.connect(_on_connect_pressed)
	btn_options.pressed.connect(func() -> void: panel_options.visible = true)
	btn_quit.pressed.connect(func() -> void: get_tree().quit())
	btn_back.pressed.connect(func() -> void: panel_options.visible = false)

	sfx_slider.value = Audio.get_sfx_volume()
	music_slider.value = Audio.get_music_volume()
	sfx_slider.value_changed.connect(Audio.set_sfx_volume)
	music_slider.value_changed.connect(Audio.set_music_volume)

	for btn: Button in [btn_play, btn_connect, btn_options, btn_quit, btn_back]:
		btn.pressed.connect(Audio.ui_click)

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, fade_in_duration).set_trans(Tween.TRANS_SINE)


func _on_play_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, fade_out_duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
	get_tree().change_scene_to_file(game_scene_path)


func _on_connect_pressed() -> void:
	# TODO: écran de connexion compte joueur.
	pass
