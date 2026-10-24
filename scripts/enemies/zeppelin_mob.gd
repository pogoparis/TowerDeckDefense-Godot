extends DroneMob
class_name ZeppelinMob
## ZEPPELIN — le gros morceau de l'Air.
##
## ── SON IDÉE ──────────────────────────────────────────────────────────────
## Un ballon de fortune : beaucoup de PV, lent, et surtout SANS BLINDAGE — de
## la toile, pas de la tôle. Il ne punit donc pas les tours qui tapent vite et
## faible, contrairement au Drone Jaune : c'est un mur de points de vie, pas un
## test de calibre.
##
## Ce qui le rend intéressant, c'est sa masse ridicule face au vent. Le
## Souffle-Chouette et la Bourrasque le renvoient beaucoup plus loin que
## n'importe qui d'autre : contre lui, repousser vaut mieux que taper.
##
## ── POURQUOI ÇA N'EST PAS UNE NOUVELLE MÉCANIQUE ─────────────────────────
## La repoussée existe déjà (EnemyBase.apply_knockback). On ne fait que donner
## à ce mob un multiplicateur qui lui est propre. Aucune règle nouvelle à
## apprendre pour le joueur : il voit juste que le vent le renvoie trois fois
## plus loin, et il en tire la conclusion tout seul.
##
## ── SA PLACE ──────────────────────────────────────────────────────────────
## 250 PV × 70 px/s = 17,5k de menace, soit un cran au-dessus du Drone Jaune.
## Il est au niveau 5 ce que le Drone Punk est à l'Eau : la grosse cible qui
## désigne son élément.

## Facteur appliqué à toute repoussée. 3,0 = trois fois la distance normale.
## Au-delà, une seule Chouette bien placée bloquerait le mob indéfiniment et le
## niveau n'aurait plus d'enjeu.
@export var push_multiplier := 3.0

## Le ballon roule sur lui-même quand il est poussé — c'est le signe visuel
## que la repoussée l'affecte plus que les autres.
var _roll := 0.0
var _roll_speed := 0.0


## Un ballon n'a pas d'inertie : on multiplie la force AVANT de laisser la
## classe de base gérer le recul, le cooldown et le gel du mouvement.
func apply_knockback(force: float) -> void:
	# Le cooldown est vérifié par la base : on ne lance l'effet visuel que si
	# la poussée va réellement avoir lieu, sinon le ballon tournerait dans le
	# vide pendant son immunité.
	if _knockback_cooldown > 0.0:
		return
	_roll_speed = 7.0
	super(force * push_multiplier)


func _process(delta: float) -> void:
	super(delta)
	if _roll_speed > 0.0:
		_roll += _roll_speed * delta
		_roll_speed = maxf(0.0, _roll_speed - delta * 3.0)
		var visual := get_node_or_null("VisualRoot")
		if visual:
			visual.rotation = sin(_roll) * 0.22 * (_roll_speed / 7.0)
		queue_redraw()


# ══════════════════════════════════════════════════════
#            SILHOUETTE PROVISOIRE
# ══════════════════════════════════════════════════════

const TOILE := Color(0.78, 0.70, 0.55)
const NACELLE := Color(0.42, 0.33, 0.24)

func _draw() -> void:
	# Dès que les sprites existent, ce dessin s'efface tout seul.
	if tex_south != null:
		return

	var cy := -74.0
	# Le ballon : large ellipse horizontale, la forme la plus reconnaissable
	# à petite taille et la plus éloignée des drones existants.
	PlaceholderArt.draw_ellipse(self, Vector2(0, cy), Vector2(52, 30), TOILE)
	# Empennage arrière, pour qu'on lise le sens de déplacement.
	PlaceholderArt.draw_shape(self, PackedVector2Array([
		Vector2(-48, cy), Vector2(-70, cy - 16), Vector2(-70, cy + 16),
	]), TOILE.darkened(0.15))
	# Nacelle suspendue : elle ancre la silhouette vers le bas et évite que le
	# ballon flotte comme une bulle sans poids.
	PlaceholderArt.draw_box(self, Vector2(0, cy + 40), Vector2(34, 20), NACELLE)
	draw_line(Vector2(-12, cy + 26), Vector2(-12, cy + 32), PlaceholderArt.EDGE, 2.0)
	draw_line(Vector2(12, cy + 26), Vector2(12, cy + 32), PlaceholderArt.EDGE, 2.0)

	PlaceholderArt.draw_weakness_dot(self, Vector2(0, cy - 46), weak_to)
