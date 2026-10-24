extends PanelContainer
## Tooltip détaillé d'une carte (nom, coûts, description, synergies).
##
## Le style vient de junkriot_theme.tres (variations TooltipPanel,
## CardNameLabel, StatusText, TooltipBody, SynergyText) —
## aucun style dans ce script.
##
## PanelContainer et pas Panel : un Panel garde la hauteur qu'on lui donne, et
## celle-ci était figée à 180 px — une carte à cinq réactions, comme le Requin
## Cracheur, voyait sa dernière ligne coupée en deux. Un PanelContainer prend
## la taille de son contenu.

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel
@onready var description_label: RichTextLabel = $VBoxContainer/DescriptionLabel
@onready var synergy_label: RichTextLabel = $VBoxContainer/SynergyLabel


func setup(card: CardData):
	# ── Nom ──────────────────────────────────────────
	name_label.text = card.card_name.to_upper()

	# ── Coût ─────────────────────────────────────────
	cost_label.text = "🔧 Poser : %d caps" % card.mana_cost

	# ── Description ──────────────────────────────────
	description_label.text = card.description

	# ── Réactions élémentaires ────────────────────────
	# C'est ici que le joueur DÉCOUVRE les combos. Sans cet affichage, la
	# difficulté du niveau 2 repose sur des interactions qu'il ne peut trouver
	# que par hasard.
	var element := _tower_element(card)
	var text := ""
	if element != ElementType.Type.NONE:
		text += "%s %s\n" % [ElementType.icon(element), ElementType.label(element).to_upper()]

	for reaction in SynergyLibrary.get_reactions_for(element):
		var partner: ElementType.Type = reaction["partner"]
		text += "\n⚙ %s — avec %s %s\n" % [
			reaction["name"], ElementType.icon(partner), ElementType.label(partner)
		]
		text += "  " + reaction["effect"] + "\n"

	synergy_label.text = text
	synergy_label.visible = text != ""


## Élément de la tour posée par cette carte, lu sur sa scène.
func _tower_element(card: CardData) -> ElementType.Type:
	if card.tower_scene == null:
		return ElementType.Type.NONE
	var probe = card.tower_scene.instantiate()
	var element: ElementType.Type = ElementType.Type.NONE
	if probe is BaseTower:
		element = probe.element_type
	probe.free()
	return element
