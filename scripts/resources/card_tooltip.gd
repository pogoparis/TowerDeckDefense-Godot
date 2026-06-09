extends Panel

@onready var name_label      : Label        = $VBoxContainer/NameLabel
@onready var cost_label      : Label        = $VBoxContainer/CostLabel
@onready var description_label : RichTextLabel = $VBoxContainer/DescriptionLabel
@onready var synergy_label   : RichTextLabel = $VBoxContainer/SynergyLabel


func _ready():
	_apply_panel_style()
	_apply_label_styles()


# ══════════════════════════════════════════════════════
# STYLE DU PANNEAU
# ══════════════════════════════════════════════════════
func _apply_panel_style():
	var style := StyleBoxFlat.new()
	style.bg_color          = Color(0.08, 0.08, 0.12, 0.96)
	style.border_color      = Color(0.75, 0.55, 0.15, 1.0)   # bordure dorée
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	# Ombre portée
	style.shadow_color  = Color(0.0, 0.0, 0.0, 0.6)
	style.shadow_size   = 8
	style.shadow_offset = Vector2(3, 4)
	# Padding interne
	style.content_margin_left   = 14
	style.content_margin_right  = 14
	style.content_margin_top    = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)

	custom_minimum_size = Vector2(280, 0)


# ══════════════════════════════════════════════════════
# STYLE DES LABELS
# ══════════════════════════════════════════════════════
func _apply_label_styles():
	# Nom de la carte — grand, doré
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))

	# Coût — petit, gris clair
	cost_label.add_theme_font_size_override("font_size", 13)
	cost_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))

	# Description — blanc doux
	description_label.add_theme_font_size_override("normal_font_size", 14)
	description_label.add_theme_color_override("default_color", Color(0.92, 0.92, 0.95))

	# Synergies — accent cyan
	synergy_label.add_theme_font_size_override("normal_font_size", 13)
	synergy_label.add_theme_color_override("default_color", Color(0.4, 0.9, 1.0))


# ══════════════════════════════════════════════════════
# DONNÉES
# ══════════════════════════════════════════════════════
func setup(card: CardData):
	# ── Nom ──────────────────────────────────────────
	name_label.text = card.card_name.to_upper()

	# ── Coût BUILD + CONSUME ─────────────────────────
	var cost_text := "🔧 Poser : %d caps" % card.mana_cost
	if card.can_consume():
		cost_text += "   |   💥 Défausser : %d caps" % card.consume_cost
	cost_label.text = cost_text

	# ── Description ──────────────────────────────────
	description_label.text = card.description

	# ── Phénomène lié (si consommable) ───────────────
	var consume_info := ""
	if card.can_consume():
		var ph_name := _phenomenon_name(card.consume_phenomenon_type)
		var ph_color := _phenomenon_color(card.consume_phenomenon_type)
		consume_info = "\n[color=%s]⚡ Défausser → %s[/color]\n  Rayon : %.0fpx — Durée : %.0fs" % [
			ph_color,
			ph_name,
			card.consume_radius,
			card.consume_duration
		]
	description_label.text = card.description + consume_info

	# ── Synergies ─────────────────────────────────────
	var synergy_text := ""
	for synergy in SynergyLibrary.get_all():
		if not synergy.required_towers.has(card.tower_id):
			continue
		synergy_text += "[b]⚙ SYNERGIE[/b] — " + synergy.synergy_name + "\n"
		synergy_text += "  " + " + ".join(synergy.required_tower_names) + "\n"
		synergy_text += "  [i]" + synergy.description + "[/i]\n"
	synergy_label.text = synergy_text
	synergy_label.visible = synergy_text != ""


func _phenomenon_name(type: PhenomenonType.Type) -> String:
	match type:
		PhenomenonType.Type.WATER_POOL:     return "Flaque d'eau"
		PhenomenonType.Type.ELECTRIC_FIELD: return "Champ électrique"
		PhenomenonType.Type.FIRE_ZONE:      return "Zone de feu"
		PhenomenonType.Type.THORN_PATCH:    return "Zone d'épines"
		PhenomenonType.Type.WIND_CURRENT:   return "Courant de vent"
	return "Phénomène"


func _phenomenon_color(type: PhenomenonType.Type) -> String:
	match type:
		PhenomenonType.Type.WATER_POOL:     return "#4db8ff"
		PhenomenonType.Type.ELECTRIC_FIELD: return "#ffe033"
		PhenomenonType.Type.FIRE_ZONE:      return "#ff6622"
		PhenomenonType.Type.THORN_PATCH:    return "#44ee44"
		PhenomenonType.Type.WIND_CURRENT:   return "#aaffee"
	return "#ffffff"
