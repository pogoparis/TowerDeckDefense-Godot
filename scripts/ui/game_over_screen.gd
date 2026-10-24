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
	sub_label.text = _defeat_debrief()
	Audio.play_sfx(preload("res://assets/audio/sfx/defeat.wav"))
	_show()


## Débriefing de défaite.
##
## Une défaite qui dit seulement « DÉFAITE » décourage ; une défaite qui dit
## POURQUOI enseigne, et donne envie de relancer avec une idée en tête. On
## affiche la vague atteinte, le nombre de fuites, et — le plus important — la
## comparaison entre ce que le niveau demandait et ce que le deck couvrait.
func _defeat_debrief() -> String:
	var lines: Array[String] = []
	lines.append("Vague %d  ·  %d fuite%s" % [
		Player.current_wave, Player.leaks, "s" if Player.leaks > 1 else ""
	])

	var keys := WaveLibrary.get_key_elements(Progress.current_level_id)
	if not keys.is_empty():
		var el: ElementType.Type = keys[0]["element"]
		var share := int(round(float(keys[0]["share"]) * 100.0))
		lines.append("Ce niveau demandait %s %s (%d %% de ses PV)" % [
			ElementType.icon(el), ElementType.label(el), share
		])

		var deck := Progress.selected_deck
		if deck != null:
			var coverage := WaveLibrary.get_deck_coverage(
				Progress.current_level_id, _deck_elements(deck)
			)
			lines.append("Ton deck en couvrait %d %%" % int(round(coverage * 100.0)))

	return "\n".join(lines)


func _deck_elements(deck: StartingDeckData) -> Dictionary:
	var seen := {}
	for card in deck.cards:
		if card == null:
			continue
		var element := ElementType.Type.NONE
		if card.spell_data != null:
			element = card.spell_data.element
		elif card.tower_scene != null:
			var probe = card.tower_scene.instantiate()
			if probe is BaseTower:
				element = probe.element_type
			probe.free()
		if element != ElementType.Type.NONE:
			seen[element] = true
	return seen


func show_victory() -> void:
	_is_victory = true
	big_label.text = victory_text
	big_label.add_theme_color_override("font_color", victory_color)
	big_label.add_theme_color_override("font_shadow_color", victory_shadow_color)
	sub_label.text = _victory_debrief()
	Audio.play_sfx(preload("res://assets/audio/sfx/victory.wav"))
	_show()


## Récapitulatif de victoire : étoiles obtenues et cartes débloquées.
## Une victoire doit PROMETTRE quelque chose pour la partie suivante, sinon
## il n'y a aucune raison d'enchaîner sur le niveau d'après.
func _victory_debrief() -> String:
	var lines: Array[String] = []

	var stars := Progress.get_stars(Progress.current_level_id)
	lines.append("★".repeat(stars) + "☆".repeat(3 - stars))

	var unlocked := _unlocked_names()
	if not unlocked.is_empty():
		lines.append("")
		lines.append("NOUVELLES CARTES DÉBLOQUÉES")
		lines.append(" · ".join(unlocked))
		lines.append("Elles apparaîtront dans tes prochaines récompenses.")

	lines.append("")
	lines.append("Clique pour continuer")
	return "
".join(lines)


## Noms lisibles des cartes que la victoire vient de débloquer.
func _unlocked_names() -> Array[String]:
	var out: Array[String] = []
	var wm = get_tree().current_scene.get("wave_manager")
	if wm == null:
		return out
	for card_id in wm._unlocked_this_run:
		var card = load("res://resources/cards/%s.tres" % card_id)
		if card is CardData:
			out.append(card.card_name)
	return out


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
