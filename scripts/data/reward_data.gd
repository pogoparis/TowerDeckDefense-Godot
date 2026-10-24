extends Resource
class_name RewardData

enum RewardType
{
	CARD,
	BONUS,
	RELIC,
	## Améliore une carte DÉJÀ dans le deck du joueur (card_data pointe dessus).
	## Pas de sélecteur de carte : l'offre NOMME la carte à améliorer, donc le
	## choix se fait parmi les trois propositions comme n'importe quelle autre
	## récompense. Même décision, zéro interface en plus.
	CARD_UPGRADE,
	## RETIRE une carte du deck (card_data pointe dessus). Le pendant de
	## l'amélioration : sans épuration, un deck ne peut que grossir, donc
	## devenir de moins en moins fiable. Retirer sa 3e Chouette pour piocher
	## plus souvent son Gardien est une décision de deckbuilder pure.
	CARD_REMOVE
}

@export var reward_type : RewardType

@export var title : String
@export_multiline var description : String
@export var icon : Texture2D

@export var card_data : CardData
@export var bonus_data : BonusData
