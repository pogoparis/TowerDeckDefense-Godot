extends TextureButton
class_name TowerCardUI

signal card_tapped(card_data, card_ui)
signal card_drag_started(card_data, card_ui)

const TOOLTIP_SCENE = preload("res://scenes/ui/card_tooltip.tscn")
const DRAG_THRESHOLD := 15.0

var card_data: CardData
var tooltip = null
var is_selected := false

var _press_position := Vector2.ZERO
var _drag_emitted := false


## Taille uniforme de TOUTES les cartes en main (ratio ~2:3), indépendante
## de la taille native du PNG de chaque carte.
const CARD_SIZE := Vector2(150, 224)

func setup(data: CardData):
	card_data = data
	texture_normal = data.card_texture
	# ignore_texture_size : le bouton ne prend PLUS la taille du PNG mais CARD_SIZE.
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = HOVER_PIVOT
	_build_placeholder_if_needed()
	_build_cost_badge()
	_build_star_badge()


## Liseré doré + étoile pour une carte ★. Sans repère visuel, le joueur ne
## saurait pas laquelle de ses cartes il a améliorée — et l'amélioration
## perdrait la moitié de sa valeur, qui est de SAVOIR qu'on l'a.
func _build_star_badge() -> void:
	if card_data == null or not card_data.upgraded:
		return

	var frame := Panel.new()
	frame.name = "StarFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(1.0, 0.82, 0.25)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	frame.add_theme_stylebox_override("panel", sb)
	add_child(frame)

	var star := Label.new()
	star.name = "StarMark"
	star.text = "★"
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.add_theme_font_size_override("font_size", 30)
	star.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	star.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	star.add_theme_constant_override("outline_size", 5)
	star.position = Vector2(CARD_SIZE.x - 34, 4)
	add_child(star)


## Carte sans illustration → visuel de repli dessiné en code.
##
## Sans ça, une carte dont `card_texture` est vide s'affiche comme un rectangle
## invisible : injouable, et impossible de savoir qu'on l'a en main. Ce repli
## permet de créer tout le contenu (sorts, nouvelles tours) en texte et de
## brancher les illustrations plus tard, sans jamais bloquer le design.
func _build_placeholder_if_needed() -> void:
	if card_data == null or card_data.card_texture != null:
		return

	var is_spell := card_data.card_type == CardData.CardType.SPELL

	var panel := Panel.new()
	panel.name = "Placeholder"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var sb := StyleBoxFlat.new()
	# Violet pour les sorts, gris pour le reste : la couleur dit le TYPE avant
	# même qu'on lise le nom — c'est aussi le violet de la visée en jeu.
	sb.bg_color = Color(0.20, 0.12, 0.30) if is_spell else Color(0.16, 0.16, 0.19)
	sb.border_color = Color(0.75, 0.50, 1.0) if is_spell else Color(0.55, 0.55, 0.6)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	# Laisse la place au badge de coût, en haut à gauche.
	margin.add_theme_constant_override("margin_top", 46)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 6)
	margin.add_child(vb)

	var kind := Label.new()
	kind.text = "SORT" if is_spell else "CARTE"
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kind.add_theme_font_size_override("font_size", 13)
	kind.add_theme_color_override("font_color",
		Color(0.8, 0.6, 1.0) if is_spell else Color(0.6, 0.6, 0.66))
	vb.add_child(kind)

	var title := Label.new()
	title.text = card_data.card_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 19)
	vb.add_child(title)


## Le chiffre du coût est PEINT dans le PNG de chaque carte : à chaque
## rééquilibrage il devient faux (les cartes disent encore "2" ou "3" alors que
## l'éco est passée à 20-40 caps). Plutôt que de ré-exporter tout l'art à chaque
## réglage, on recouvre le badge d'origine et on affiche `mana_cost`, qui est la
## seule source de vérité (c'est lui que `spend_caps` débite).
func _build_cost_badge() -> void:
	if card_data == null:
		return

	var existing := get_node_or_null("CostBadge")
	if existing:
		existing.queue_free()

	# Position/taille calées sur le badge peint en haut à gauche de l'art
	# (≈ 12 % de la largeur, 8 % de la hauteur, en fraction de l'image source).
	const BADGE_SIZE := Vector2(34, 34)
	var badge_center := Vector2(CARD_SIZE.x * 0.123, CARD_SIZE.y * 0.088)

	var badge := Panel.new()
	badge.name = "CostBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size = BADGE_SIZE
	badge.position = badge_center - BADGE_SIZE * 0.5

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.09, 0.11)
	sb.set_corner_radius_all(9)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.72, 0.72, 0.76)
	badge.add_theme_stylebox_override("panel", sb)

	var label := Label.new()
	label.text = str(card_data.mana_cost)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 2 chiffres dans 34 px : on serre un peu la police par rapport à 1 chiffre.
	label.add_theme_font_size_override("font_size", 15 if card_data.mana_cost >= 10 else 19)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	badge.add_child(label)

	add_child(badge)


func set_selected(value: bool):
	is_selected = value
	if is_selected:
		modulate = Color(1.4, 1.4, 0.6)
		scale = Vector2(1.1, 1.1)
	else:
		modulate = Color.WHITE
		scale = Vector2(1.0, 1.0)


var _tuto_tween: Tween

## Surbrillance pulsée pour le tutoriel : montre quelle carte jouer.
func set_tutorial_highlight(value: bool):
	if value:
		if _tuto_tween and _tuto_tween.is_valid():
			return
		modulate = Color(1.6, 1.6, 0.7)
		_tuto_tween = create_tween().set_loops()
		_tuto_tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.5).set_trans(Tween.TRANS_SINE)
		_tuto_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
	else:
		if _tuto_tween and _tuto_tween.is_valid():
			_tuto_tween.kill()
		_tuto_tween = null
		modulate = Color.WHITE
		scale = Vector2.ONE


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# Désactive le signal pressed natif — on gère tout dans _gui_input
func _pressed():
	pass


func _gui_input(event: InputEvent):

	# ── TOUCH (mobile) ──────────────────────────────────
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_position = event.position
			_drag_emitted = false
		else:
			# Relâché sans drag → tap
			if not _drag_emitted:
				card_tapped.emit(card_data, self)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		if not _drag_emitted:
			if event.position.distance_to(_press_position) > DRAG_THRESHOLD:
				_drag_emitted = true
				card_drag_started.emit(card_data, self)
		get_viewport().set_input_as_handled()
		return

	# ── SOURIS (desktop / éditeur) ───────────────────────
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_position = event.position
			_drag_emitted = false
		else:
			if not _drag_emitted:
				card_tapped.emit(card_data, self)
		return

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _drag_emitted:
			if event.position.distance_to(_press_position) > DRAG_THRESHOLD:
				_drag_emitted = true
				card_drag_started.emit(card_data, self)
		return


## Grossissement au survol.
##
## ── POURQUOI L'ÉCHELLE ET PAS LA POSITION ────────────────────────────────
## Les cartes vivent dans un HBoxContainer, qui repositionne ses enfants à
## chaque tri : un déplacement serait annulé au premier rafraîchissement de la
## main. Le conteneur, lui, ne touche jamais à l'échelle.
##
## ── POURQUOI LE PIVOT EST SUR LE BORD BAS ────────────────────────────────
## Il a d'abord été placé SOUS la carte, pour la soulever en même temps qu'elle
## grossissait — les cartes débordaient alors de l'écran et leur pied était
## coupé. Elles ont depuis été remontées et tiennent entièrement à l'écran :
## le soulèvement n'a plus lieu d'être, et une carte qui bouge sous le curseur
## est plus dure à viser qu'une carte qui gonfle sur place.
##
## Pivot sur le bord bas : le pied reste ancré, la carte grandit vers le haut,
## et elle ne peut pas repartir sous le bas de l'écran — ce qui arriverait avec
## un pivot centré, faute des 27 px de marge qu'il réclamerait.
const HOVER_SCALE := 1.24
const HOVER_TIME := 0.14
const HOVER_PIVOT := Vector2(CARD_SIZE.x * 0.5, CARD_SIZE.y)

var _hover_tween: Tween = null


func _scale_to(target: float) -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", Vector2(target, target), HOVER_TIME) 		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_mouse_entered():

	# z_index relatif eleve : sans ca, la carte agrandie passerait SOUS sa
	# voisine de droite et on verrait une carte coupee en deux.
	z_index = 20
	pivot_offset = HOVER_PIVOT
	_scale_to(HOVER_SCALE)

	if tooltip:
		return

	tooltip = TOOLTIP_SCENE.instantiate()

	var anchor = get_tree().current_scene.get_node(
		"UI/RootUI/CardTooltipAnchor"
	)

	anchor.add_child(tooltip)
	tooltip.modulate.a = 0.0
	tooltip.setup(card_data)

	# Ancrage par le bas : la bulle grandit vers le haut, jamais sur la main.
	tooltip.anchor_top = 1.0
	tooltip.anchor_bottom = 1.0
	tooltip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tooltip.offset_top = 0.0
	tooltip.offset_bottom = 0.0

	var tween = create_tween()
	tween.tween_property(tooltip, "modulate:a", 1.0, 0.15)


func _on_mouse_exited():

	z_index = 0
	_scale_to(1.0)

	if tooltip:
		tooltip.queue_free()
		tooltip = null
