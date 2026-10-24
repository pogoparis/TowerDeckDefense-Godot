extends DroneMob
class_name FurnaceDrone
## DRONE FOURNAISE — le mob qui s'emballe.
##
## ── SON IDÉE ──────────────────────────────────────────────────────────────
## Son réacteur monte en pression : il ACCÉLÈRE en continu tout au long du
## chemin. Plus il avance, plus il devient incontrôlable — et plus il passe
## vite sous le feu des tours, donc plus il devient difficile à tuer.
##
## Sa faiblesse est la Glace, et ce n'est pas un choix arbitraire : le GIVRE est
## la seule chose qui refroidit son réacteur et fait retomber la pression.
## Sa mécanique et sa faiblesse sont le MÊME axe — le joueur n'a rien à
## apprendre par cœur, il le comprend en le regardant.
##
## ── POURQUOI LA LISIBILITÉ VIENT DU CODE ─────────────────────────────────
## Un sprite fixe ne peut pas montrer une montée en régime. À 120 px de haut,
## les détails peints (manomètre, rivets) sont invisibles. C'est donc le
## MOUVEMENT qui porte l'information : la flamme enfle, le métal rougeoie, le
## drone tremble quand il approche de sa vitesse maximale.

## Vitesse gagnée par seconde, en fraction de la vitesse de base.
## 0.14 → il double sa vitesse en ~7 s, soit à peu près la moitié du chemin.
@export var heat_rate := 0.14
## Plafond, en multiple de la vitesse de base. Au-delà il deviendrait
## impossible à toucher, et le niveau ne serait plus une question de placement.
@export var heat_max := 2.2

## Pression actuelle : 0 = froid (vitesse de base), 1 = régime maximal.
var heat := 0.0

var _base_speed := 0.0
var _flame_pulse := 0.0


func _ready() -> void:
	super()
	_base_speed = speed


func _process(delta: float) -> void:
	super(delta)
	_flame_pulse += delta * 8.0

	# LE GIVRE REFROIDIT. C'est le seul contre, et il est immédiat : le joueur
	# doit voir sa Glace agir, pas attendre que le compteur redescende.
	if has_status(StatusIds.CHILLED):
		heat = maxf(0.0, heat - delta * heat_rate * 3.0)
	else:
		heat = minf(1.0, heat + delta * heat_rate)

	speed = _base_speed * lerpf(1.0, heat_max, heat)

	# Le métal chauffe : la teinte passe au rouge-blanc avec la pression.
	var visual := get_node_or_null("VisualRoot")
	if visual:
		visual.modulate = Color(1.0, 1.0 - heat * 0.35, 1.0 - heat * 0.55)
		# Tremblement dans le dernier tiers : le signal « il va nous échapper ».
		if heat > 0.66:
			var shake: float = (heat - 0.66) * 9.0
			visual.position.x = sin(_flame_pulse * 3.0) * shake

	queue_redraw()


## Surchauffe dessinée AUTOUR du sprite, jamais par-dessus.
##
## ── CE QUE LE CODE NE DOIT PAS FAIRE ─────────────────────────────────────
## La première version peignait une grosse flamme à trois couches au sommet.
## Mais les sprites ont DÉJÀ leurs flammes de cheminée peintes, et elles ne
## sont pas au même endroit selon la vue : la flamme de code s'y superposait
## en double, décalée. Deux flammes valent moins qu'une.
##
## Le code ne dessine donc que ce qu'un sprite fixe ne peut pas montrer : la
## chaleur qui MONTE. Le halo enfle, le métal rougit (_process), le drone
## tremble. Les flammes peintes, elles, restent les siennes.
func _draw() -> void:
	if heat <= 0.05:
		return

	# Halo de chaleur : il grandit et se densifie avec la pression. C'est le
	# signal lisible à 112 px — bien plus qu'un détail au sommet.
	var breathe := 1.0 + sin(_flame_pulse * 0.5) * 0.06
	var radius := (46.0 + 34.0 * heat) * breathe
	draw_circle(Vector2(0, -56), radius, Color(1.0, 0.35, 0.05, 0.05 + 0.10 * heat))
	draw_circle(Vector2(0, -56), radius * 0.62, Color(1.0, 0.55, 0.15, 0.04 + 0.09 * heat))

	# Au régime maximal, une couronne nette : le joueur doit pouvoir dire
	# « celui-là est lancé » d'un seul coup d'œil dans une vague de vingt.
	if heat > 0.7:
		var peak: float = (heat - 0.7) / 0.3
		draw_arc(Vector2(0, -56), radius * 0.9, 0.0, TAU, 28,
			Color(1.0, 0.75, 0.25, 0.35 * peak), 2.5, true)
