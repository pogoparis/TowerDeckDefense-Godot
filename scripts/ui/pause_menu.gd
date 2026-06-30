class_name PauseMenu
extends Control
## Menu pause en jeu (Échap sur PC, bouton ⚙ du TopHUD sur mobile).
##
## Met le jeu en pause (get_tree().paused) tant qu'il est visible.
## Le style visuel vient entièrement de junkriot_theme.tres —
## aucun style ne doit être défini dans ce script.

signal resumed

## Scène affichée par "QUITTER AU MENU" (par défaut : la carte du monde).
@export_file("*.tscn") var menu_scene_path: String = "res://scenes/ui/WorldMap.tscn"
## Scène de jeu (rechargée via "RECOMMENCER").
@export_file("*.tscn") var game_scene_path: String = "res://scenes/ui/level.tscn"
## Niveaux de qualité graphique proposés dans les paramètres.
@export var quality_options: PackedStringArray = ["FAIBLE", "MOYEN", "ELEVE"]
## Index de qualité sélectionné par défaut.
@export var default_quality_index: int = 2

@onready var panel: Panel = $Panel
@onready var btn_resume: Button = $Panel/VBox/BtnResume
@onready var btn_restart: Button = $Panel/VBox/BtnRestart
@onready var btn_settings: Button = $Panel/VBox/BtnSettings
@onready var btn_menu: Button = $Panel/VBox/BtnMenu
@onready var panel_settings: Panel = $PanelSettings
@onready var btn_back: Button = $PanelSettings/VBox/BtnBack
@onready var sfx_slider: HSlider = $PanelSettings/VBox/SFXRow/SFXSlider
@onready var music_slider: HSlider = $PanelSettings/VBox/MusicRow/MusicSlider
@onready var graphics_option: OptionButton = $PanelSettings/VBox/GraphicsRow/GraphicsOption


func _ready() -> void:
	visible = false
	panel_settings.visible = false

	for option in quality_options:
		graphics_option.add_item(option)
	graphics_option.selected = default_quality_index

	btn_resume.pressed.connect(hide_menu)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_settings.pressed.connect(_show_settings)
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_back.pressed.connect(_show_main)

	sfx_slider.value = Audio.get_sfx_volume()
	music_slider.value = Audio.get_music_volume()
	sfx_slider.value_changed.connect(Audio.set_sfx_volume)
	music_slider.value_changed.connect(Audio.set_music_volume)

	for btn: Button in [btn_resume, btn_restart, btn_settings, btn_menu, btn_back]:
		btn.pressed.connect(Audio.ui_click)


## Affiche le menu pause et fige le jeu.
func show_menu() -> void:
	visible = true
	_show_main()
	get_tree().paused = true


## Cache le menu pause et relance le jeu.
func hide_menu() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()


func _show_main() -> void:
	panel.visible = true
	panel_settings.visible = false


func _show_settings() -> void:
	panel.visible = false
	panel_settings.visible = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(game_scene_path)


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_scene_path)
