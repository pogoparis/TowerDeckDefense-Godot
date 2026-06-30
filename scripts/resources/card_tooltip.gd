extends Panel
## Tooltip détaillé d'une carte (nom, coûts, description, synergies).
##
## Le style vient de junkriot_theme.tres (variations TooltipPanel,
## CardNameLabel, StatusText, TooltipBody, SynergyText) —
## aucun style dans ce script.

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel
@onready var description_label: RichTextLabel = $VBoxContainer/DescriptionLabel
@onready var synergy_label: RichTextLabel = $VBoxContainer/SynergyLabel


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
		consume_info = "\n⚡ Défausser → %s\n  Rayon : %.0fpx — Durée : %.0fs" % [
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
		synergy_text += "⚙ SYNERGIE — " + synergy.synergy_name + "\n"
		synergy_text += "  " + " + ".join(synergy.required_tower_names) + "\n"
		synergy_text += "  " + synergy.description + "\n"
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
