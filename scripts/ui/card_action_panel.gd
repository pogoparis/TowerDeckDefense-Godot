extends PanelContainer
class_name CardActionPanel

signal consume_pressed

@onready var build_button: Button = $HBoxContainer/BuildButton
@onready var consume_button: Button = $HBoxContainer/ConsumeButton

## Nom affiché du phénomène créé en CONSUME, selon le type de la carte.
const PHENOMENON_NAMES := {
	PhenomenonType.Type.WATER_POOL: "Flaque d'Eau",
	PhenomenonType.Type.ELECTRIC_FIELD: "Champ Électrique",
	PhenomenonType.Type.FIRE_ZONE: "Zone de Feu",
	PhenomenonType.Type.THORN_PATCH: "Ronces",
	PhenomenonType.Type.WIND_CURRENT: "Bourrasque",
}


func _ready():
	# Le BUILD se fait par drag — ce panel ne sert qu'à CONSOMMER
	build_button.visible = false
	consume_button.pressed.connect(func(): consume_pressed.emit())


func show_for_card(card_data: CardData, card_ui: Control):

	if not card_data.can_consume():
		return

	# Le bouton affiche le NOM DU PHÉNOMÈNE au lieu de "Défausser".
	consume_button.text = PHENOMENON_NAMES.get(card_data.consume_phenomenon_type, "Consommer")

	# Recalcule la taille selon le texte AVANT de centrer.
	reset_size()

	# Centré horizontalement sur la carte, juste au-dessus de son bord haut.
	var rect := card_ui.get_global_rect()
	global_position = Vector2(
		rect.get_center().x - size.x / 2.0,
		rect.position.y - size.y - 10.0
	)

	visible = true


func hide_panel():

	visible = false
