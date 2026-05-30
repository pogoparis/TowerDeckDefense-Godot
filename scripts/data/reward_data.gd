extends Resource
class_name RewardData

enum RewardType
{
	CARD,
	BONUS,
	RELIC
}

@export var reward_type : RewardType

@export var title : String
@export_multiline var description : String
@export var icon : Texture2D

@export var card_data : CardData
@export var bonus_data : BonusData
