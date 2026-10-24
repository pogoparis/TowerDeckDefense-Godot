extends Button
class_name RewardCard
## Une des trois offres de l'écran de récompense.
##
## Deux natures très différentes cohabitent — une CARTE (qui rejoint le deck)
## et un BONUS (stat passive). Le joueur doit voir la différence avant de lire :
## d'où le bandeau de type et le liseré coloré.

signal reward_clicked(reward_data)

@onready var art: TextureRect = get_node_or_null("Art")

var reward_data: RewardData


func setup(data: RewardData):
	reward_data = data
	custom_minimum_size = Vector2(180, 240)

	if data.icon:
		if art:
			art.texture = data.icon
		# ⚠ Le bandeau de type est OBLIGATOIRE, illustration ou pas.
		#
		# Cette branche sortait directement, et _build_text_card() — qui dessine
		# « ★ AMÉLIORATION », « ✂ ÉPURATION » et le liseré — n'était appelé que
		# pour les offres SANS image. Or une amélioration reprend l'illustration
		# de la carte visée (RewardDB._pick_upgrade fait icon = card_texture) :
		# elle s'affichait donc exactement comme la carte elle-même.
		#
		# En playtest, ça donne « j'ai choisi le Punk Explosif et il n'est pas
		# arrivé dans ma main » — le joueur croyait prendre la carte, il
		# améliorait celle qu'il avait déjà. Deux récompenses aux effets
		# opposés ne doivent jamais se ressembler.
		_overlay_kind_banner(data)
		return

	# Sans illustration (les sorts pour l'instant, et tout ce qu'on créera en
	# texte), on dessine la carte : sans ça l'offre est un rectangle vide et
	# le joueur choisit à l'aveugle.
	_build_text_card(data)


## Libellé et couleur d'une offre. Source unique : le bandeau posé sur une
## illustration et la carte dessinée en texte doivent dire la MÊME chose.
func _kind_of(data: RewardData) -> Dictionary:
	match data.reward_type:
		RewardData.RewardType.CARD_REMOVE:
			return { "text": "✂  RETIRER DU DECK", "color": Color(0.95, 0.45, 0.4) }
		RewardData.RewardType.CARD_UPGRADE:
			# Formulé comme une PHRASE et pas comme une étiquette : « ★
			# AMÉLIORATION » laissait croire à une carte améliorée qu'on
			# recevrait. Ici on nomme l'effet réel — rien n'entre dans la main.
			return { "text": "★  AMÉLIORE TA CARTE", "color": Color(1.0, 0.82, 0.25) }
		RewardData.RewardType.CARD:
			if data.card_data != null and data.card_data.card_type == CardData.CardType.SPELL:
				return { "text": "SORT — NOUVELLE CARTE", "color": Color(0.78, 0.52, 1.0) }
			return { "text": "TOUR — NOUVELLE CARTE", "color": Color(0.45, 0.85, 1.0) }
	return { "text": "BONUS", "color": Color(0.95, 0.78, 0.35) }


## Pose le type PAR-DESSUS l'illustration : liseré coloré tout autour et
## bandeau lisible en bas, là où les cartes du jeu portent le moins de détail.
func _overlay_kind_banner(data: RewardData) -> void:
	var kind := _kind_of(data)

	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = kind["color"]
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	frame.add_theme_stylebox_override("panel", sb)
	add_child(frame)

	var banner := PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	banner.offset_top = -34.0
	banner.offset_bottom = -3.0
	banner.offset_left = 3.0
	banner.offset_right = -3.0
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.05, 0.04, 0.07, 0.92)
	bsb.border_color = kind["color"]
	bsb.border_width_top = 2
	bsb.set_corner_radius_all(0)
	bsb.corner_radius_bottom_left = 8
	bsb.corner_radius_bottom_right = 8
	banner.add_theme_stylebox_override("panel", bsb)
	add_child(banner)

	var label := Label.new()
	label.text = kind["text"]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", kind["color"])
	banner.add_child(label)


func _build_text_card(data: RewardData) -> void:
	if art:
		art.visible = false

	var is_upgrade := data.reward_type == RewardData.RewardType.CARD_UPGRADE
	var is_removal := data.reward_type == RewardData.RewardType.CARD_REMOVE
	var is_card := data.reward_type == RewardData.RewardType.CARD
	var is_spell := is_card and data.card_data != null \
		and data.card_data.card_type == CardData.CardType.SPELL

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var sb := StyleBoxFlat.new()
	if is_removal:
		# Rouge sombre : on RETIRE quelque chose. Le joueur doit sentir que
		# c'est un acte différent d'un gain, même si c'en est souvent un.
		sb.bg_color = Color(0.24, 0.10, 0.10); sb.border_color = Color(0.95, 0.45, 0.4)
	elif is_upgrade:
		# Or franc : l'amélioration est la récompense la plus rare et la plus
		# forte, elle ne doit jamais se confondre avec une carte ordinaire.
		sb.bg_color = Color(0.26, 0.20, 0.06); sb.border_color = Color(1.0, 0.82, 0.25)
	elif is_spell:
		sb.bg_color = Color(0.20, 0.12, 0.30); sb.border_color = Color(0.78, 0.52, 1.0)
	elif is_card:
		sb.bg_color = Color(0.12, 0.20, 0.26); sb.border_color = Color(0.45, 0.85, 1.0)
	else:
		sb.bg_color = Color(0.22, 0.18, 0.10); sb.border_color = Color(0.95, 0.78, 0.35)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 6)
	margin.add_child(vb)

	var kind := Label.new()
	kind.text = _kind_of(data)["text"]
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kind.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kind.add_theme_font_size_override("font_size", 14)
	kind.add_theme_color_override("font_color", sb.border_color)
	vb.add_child(kind)

	var title := Label.new()
	title.text = data.title.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 20)
	vb.add_child(title)

	if is_card and data.card_data != null:
		var cost := Label.new()
		cost.text = "%d caps" % data.card_data.mana_cost
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost.add_theme_font_size_override("font_size", 15)
		cost.add_theme_color_override("font_color", Color(0.9, 0.82, 0.45))
		vb.add_child(cost)

	var desc := Label.new()
	desc.text = data.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.88))
	vb.add_child(desc)


func _pressed():
	reward_clicked.emit(reward_data)
