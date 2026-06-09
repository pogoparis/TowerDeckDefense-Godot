extends Resource
class_name CardData

enum CardType {
	TOWER,
	SPELL,
	UPGRADE,
	TACTIC,
	ECONOMY,
	RELIC
}


@export var card_name: String
@export_multiline var description: String

@export var card_type: CardType
@export var card_texture : Texture2D
@export var mana_cost := 1
@export var tower_id: String
@export var icon: Texture2D

# ==============================
#       GAMEPLAY LINKS
# ==============================

@export var tower_scene: PackedScene
@export var bonus_data: BonusData

# ==============================
#       CONSUME (BUILD/CONSUME)
# ==============================

@export var consume_cost := 2
@export var consume_phenomenon_type: PhenomenonType.Type = PhenomenonType.Type.NONE
@export var consume_radius := 96.0
@export var consume_duration := 6.0

func can_consume() -> bool:
	return consume_phenomenon_type != PhenomenonType.Type.NONE
