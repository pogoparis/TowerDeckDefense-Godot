class_name WorldMap
extends Control
## Carte du monde : sélection des niveaux (pattern Alien Creeps).
##
## Les pins sont positionnés en fractions de l'image de fond
## (LevelData.map_position) à l'intérieur d'un AspectRatioContainer —
## ils suivent l'image à n'importe quelle résolution (pattern ImageAnchor,
## voir docs/UI_STYLE_GUIDE.md).
##
## Pour ajouter un niveau : créer un LevelData dans resources/levels/
## et l'ajouter à la liste [member levels] dans l'inspecteur.

const PIN_SCENE := preload("res://scenes/ui/LevelPin.tscn")

## Niveaux affichés sur la carte, dans l'ordre.
@export var levels: Array[LevelData] = []
## Scène du menu principal (bouton RETOUR).
@export_file("*.tscn") var menu_scene_path: String = "res://scenes/ui/MainMenu.tscn"

@onready var pins_container: Control = $ImageAnchor/Pins
@onready var btn_back: Button = $ImageAnchor/MapUI/BtnBack
@onready var overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	overlay.color = Color(0, 0, 0, 1)
	Audio.play_menu_music()
	btn_back.pressed.connect(_on_back_pressed)
	btn_back.pressed.connect(Audio.ui_click)
	_spawn_pins()

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)


func _spawn_pins() -> void:
	for level in levels:
		var pin: LevelPin = PIN_SCENE.instantiate()
		pins_container.add_child(pin)
		pin.anchor_left = level.map_position.x
		pin.anchor_right = level.map_position.x
		pin.anchor_top = level.map_position.y
		pin.anchor_bottom = level.map_position.y
		pin.offset_left = -45.0
		pin.offset_right = 45.0
		pin.offset_top = -45.0
		pin.offset_bottom = 45.0
		pin.setup(level)
		pin.level_selected.connect(_on_level_selected)


func _on_level_selected(level: LevelData) -> void:
	Progress.current_level_id = level.level_id
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween.finished
	get_tree().change_scene_to_file(level.scene_path)


func _on_back_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween.finished
	get_tree().change_scene_to_file(menu_scene_path)
