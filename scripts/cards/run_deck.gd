extends Node
## État du deck sur la RUN en cours (autoload "RunDeck").
##
## Remis à zéro à chaque partie par le niveau. C'est ici que vivent les effets
## permanents acquis en jouant une carte, par opposition aux bonus de
## RunBonuses qui viennent des récompenses.

## Cartes gagnées en récompense pendant cette partie.
var owned_cards: Array[CardData] = []

## Caps versées à chaque fin de vague, cumulées par les cartes ÉCONOMIE.
## C'est le moteur "boule de neige" : une carte jouée vague 2 rapporte dix
## fois plus que la même jouée vague 10.
var caps_per_wave := 0


func reset() -> void:
	owned_cards.clear()
	caps_per_wave = 0
