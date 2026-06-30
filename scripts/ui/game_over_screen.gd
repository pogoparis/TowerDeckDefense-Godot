class_name GameOverScreen
extends Control
## Écran de fin de partie : grand "VICTOIRE !" ou "DÉFAITE" plein écran.
##
## S'affiche au-dessus de tout le gameplay, puis retourne au menu principal
## au premier clic ou appui de touche.
## Seules les couleurs dynamiques (victoire/défaite) sont définies ici en
## @export — tout le reste du style vient de junkriot_theme.tres.

## Scène affichée après le clic (par défaut : la carte du monde).
@export_file("*.tscn") var menu_scene_path: String = "res://scenes/ui/WorldMap.tscn"

@export_group("Défaite")
@export var defeat_text: String = "DÉFAITE"
@export var defeat_color: Color = Color(0.95, 0.18, 0.12)
@export var defeat_shadow_color: Color = Color(0.4, 0.0, 0.0, 0.9)

@export_group("Victoire")
@export var victory_text: String = "VICTOIRE !"
@export var victory_color: Color = Color(1.0, 0.85, 0.08)
@export var victory_shadow_color: Color = Color(0.5, 0.3, 0.0, 0.9)

signal victory_acknowledged

var _ready_to_click: bool = false
var _is_victory: bool = false

@onready var overlay: ColorRect = $Overlay
@onready var big_label: Label = $Center/BigLabel
@onready var sub_label: Label = $Center/SubLabel


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not _ready_to_click:
		return
	var clicked: bool = event is InputEventMouseButton and (event as InputEventMouseButton).pressed
	var key_hit: bool = event is InputEventKey and (event as InputEventKey).pressed
	if clicked or key_hit:
		if _is_victory:
			_ready_to_click = false
			visible = false
			victory_acknowledged.emit()
		else:
			_go_to_menu()


func show_defeat() -> void:
	big_label.text = defeat_text
	big_label.add_theme_color_override("font_color", defeat_color)
	big_label.add_theme_color_override("font_shadow_color", defeat_shadow_color)
	Audio.play_sfx(preload("res://assets/audio/sfx/defeat.wav"))
	_show()


func show_victory() -> void:
	_is_victory = true
	big_label.text = victory_text
	big_label.add_theme_color_override("font_color", victory_color)
	big_label.add_theme_color_override("font_shadow_color", victory_shadow_color)
	Audio.play_sfx(preload("res://assets/audio/sfx/victory.wav"))
	_show()


func _show() -> void:
	get_tree().paused = false
	visible = true
	mouse_filter = MOUSE_FILTER_STOP

	overlay.modulate.a = 0.0
	big_label.modulate.a = 0.0
	big_label.scale = Vector2(0.6, 0.6)
	sub_label.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(big_label, "modulate:a", 1.0, 0.6).set_delay(0.2) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(big_label, "scale", Vector2.ONE, 0.4).set_delay(0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sub_label, "modulate:a", 1.0, 0.4).set_delay(0.7) \
		.set_trans(Tween.TRANS_SINE)
	await tween.finished

	_ready_to_click = true


func _go_to_menu() -> void:
	_ready_to_click = false
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_scene_path)
