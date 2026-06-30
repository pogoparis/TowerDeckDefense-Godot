extends Resource
class_name StartingDeckData

@export var deck_name : String
@export var cards : Array

## Si true, la pioche n'est PAS mélangée : les cartes sont tirées dans l'ordre
## exact du tableau (tutoriel scripté = "faux aléatoire"). Le mulligan est aussi
## désactivé pour ce deck afin de garantir la séquence imposée au joueur.
@export var scripted_order : bool = false
