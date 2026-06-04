extends Panel

@onready var name_label = $VBoxContainer/NameLabel
@onready var cost_label = $VBoxContainer/CostLabel
@onready var description_label = $VBoxContainer/DescriptionLabel
@onready var synergy_label = $VBoxContainer/SynergyLabel


func _ready():

	size = Vector2(300, 200)

	modulate = Color.RED

	print("TOOLTIP READY")
	print("POSITION = ", position)
	print("SIZE = ", size)

func setup(card: CardData):

	print("TOOLTIP FOR :", card.card_name)

	name_label.text = card.card_name
	cost_label.text = "Cost : %d" % card.mana_cost
	description_label.text = card.description

	var text := ""

	for synergy in SynergyLibrary.get_all():

		if not synergy.required_towers.has(card.tower_id):
			continue
	
		text += "\n=== SYNERGIES ===\n"

		text += synergy.synergy_name + "\n"

		text += " + ".join(
			synergy.required_tower_names
		)
		text += "\n"
		text += synergy.description + "\n"

	synergy_label.text = text
