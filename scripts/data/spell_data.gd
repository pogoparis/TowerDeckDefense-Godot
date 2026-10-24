extends Resource
class_name SpellData
## Effet d'une carte SORT.
##
## Un sort est une carte de la main, jouée PENDANT la vague, consommée à
## l'usage, payée en Caps. C'est le verbe qui manquait au joueur : une fois la
## vague lancée, il ne pouvait que poser, améliorer et déclencher une Charge —
## soit un clic toutes les 15 secondes au mieux.
##
## Tous les sorts se lancent de la même façon : on vise un POINT du monde et
## l'effet s'applique dans un rayon. Une seule façon de viser = rien à
## apprendre, et l'interface de pose des tours est réutilisée telle quelle.
##
## RÈGLE DE CONCEPTION : le contrôle est bon marché, les dégâts sont chers.
## Un sort qui tue est une béquille ; un sort qui PERMET de tuer est une
## décision. C'est aussi ce qui empêche les sorts de rendre les tours inutiles.

enum Effect {
	## Dégâts immédiats dans le rayon, avec un élément (donc soumis aux
	## faiblesses et au blindage, comme n'importe quelle source).
	DAMAGE,
	## Immobilise et étourdit dans le rayon.
	STUN,
	## Fait apparaître un phénomène de zone — c'est LE sort qui transforme les
	## réactions élémentaires de subies en exécutées : le joueur pose lui-même
	## la moitié manquante d'une combinaison, là où il la veut.
	PHENOMENON,
	## Dope les tours du rayon pendant un temps.
	TOWER_BUFF,
}

@export var effect: Effect = Effect.DAMAGE
## Rayon d'action en pixels (une case fait 96 px).
@export var radius := 140.0

@export_group("Dégâts")
@export var damage := 0
## Élément des dégâts : ils profitent des faiblesses ennemies comme un tir.
@export var element: ElementType.Type = ElementType.Type.NONE

@export_group("Contrôle")
## Durée du stun, du buff, ou du phénomène posé (secondes).
@export var duration := 3.0
## Ralentissement appliqué (1.0 = aucun). Cumulable avec le stun.
@export var slow_multiplier := 1.0

@export_group("Phénomène")
@export var phenomenon: PhenomenonType.Type = PhenomenonType.Type.NONE

@export_group("Buff de tours")
@export var buff_damage_mult := 1.0
@export var buff_fire_rate_mult := 1.0

@export_group("Présentation")
## Texte flottant affiché au lancement. Le joueur doit VOIR que son sort a agi,
## sinon il ne saura pas s'il a servi à quelque chose.
@export var cast_label := ""
@export var cast_color := Color(1, 1, 1)
## Intensité du tremblement d'écran au lancement.
@export var shake := 6.0
