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

@export var mana_cost := 1

@export var icon: Texture2D

# ==============================
#       GAMEPLAY LINKS
# ==============================

@export var tower_scene: PackedScene
@export var bonus_data: BonusData
