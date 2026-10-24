extends DroneMob
class_name PhantomDrone
## DRONE FANTÔME — celui qui donne enfin un rôle à la Lumière.
##
## ── LE PROBLÈME QU'IL RÉSOUT ─────────────────────────────────────────────
## La Lumière était un pur amplificateur : la Luciole augmentait les dégâts des
## tours autour d'elle, et c'est tout. Un joueur pouvait finir le jeu sans
## jamais avoir de raison d'en poser une. Un élément qui n'a jamais de moment à
## lui n'est pas un élément, c'est une statistique.
##
## ── SON IDÉE ──────────────────────────────────────────────────────────────
## Il est CAMOUFLÉ : il encaisse moitié moins de tout, quelle que soit la
## source. Une seule touche de Lumière le RÉVÈLE pendant quelques secondes —
## le camouflage tombe, et sa faiblesse ×2 s'applique normalement.
##
## L'écart est donc de ×4 entre le frapper camouflé et le frapper révélé. Ce
## n'est pas un bonus marginal : sans Lumière dans le deck, il traverse.
##
## ── POURQUOI ÇA NE CASSE PAS LA RÈGLE 4 ──────────────────────────────────
## La règle dit que les amplificateurs (Lumière, Ombre) n'ont jamais de
## réaction. Elle tient toujours : révéler n'est pas une réaction entre deux
## statuts, c'est un COMPORTEMENT propre à cet ennemi. Aucune ligne n'est
## ajoutée à la matrice des réactions, et la règle « CONTRÔLE + DÉGÂTS =
## RÉACTION » reste vraie telle quelle.

## Part des dégâts encaissée tant qu'il est camouflé.
@export var cloak_reduction := 0.5
## Durée de la révélation après une touche de Lumière. Assez longue pour que
## les autres tours en profitent — sinon la Luciole devrait tout tuer seule,
## et le mob ne récompenserait pas un deck mais une tour.
@export var reveal_duration := 3.0

var _reveal_timer := 0.0
var _shimmer := 0.0


func is_revealed() -> bool:
	return _reveal_timer > 0.0


func _process(delta: float) -> void:
	super(delta)
	_shimmer += delta

	if _reveal_timer > 0.0:
		_reveal_timer = maxf(0.0, _reveal_timer - delta)
		if _reveal_timer == 0.0:
			_apply_cloak_visual()
	queue_redraw()


func _ready() -> void:
	super()
	_apply_cloak_visual()


## Le camouflage doit se VOIR : un mob à moitié transparent qui redevient net
## quand on l'éclaire raconte sa mécanique sans une ligne de texte.
func _apply_cloak_visual() -> void:
	var visual := get_node_or_null("VisualRoot")
	if visual:
		visual.modulate.a = 1.0 if is_revealed() else 0.42


## La Lumière révèle ; le reste tape dans le vide tant qu'il ne l'est pas.
##
## L'ordre compte : on révèle AVANT d'appeler la classe de base, pour que la
## touche de Lumière qui révèle bénéficie déjà elle-même du ×2. Sinon le
## premier tir de Luciole serait le seul à taper à moitié, ce qui se lirait
## comme une injustice.
func take_damage(
	amount: int,
	kind: String = "normal",
	element: ElementType.Type = ElementType.Type.NONE
) -> void:
	if _is_dying:
		return

	if element == ElementType.Type.LIGHT:
		var etait_camoufle := not is_revealed()
		_reveal_timer = reveal_duration
		_apply_cloak_visual()
		if etait_camoufle:
			FloatingTextService.spawn(
				get_tree().current_scene,
				global_position + Vector2(0, -105),
				"RÉVÉLÉ !", Color(1.0, 0.95, 0.6), 1.1
			)
	elif not is_revealed():
		amount = maxi(1, int(round(amount * cloak_reduction)))

	super(amount, kind, element)


# ══════════════════════════════════════════════════════
#            SILHOUETTE PROVISOIRE
# ══════════════════════════════════════════════════════

const SPECTRE := Color(0.62, 0.55, 0.80)

func _draw() -> void:
	if tex_south != null:
		return

	var cy := -66.0
	var revele := is_revealed()
	var corps := SPECTRE if revele else Color(SPECTRE.r, SPECTRE.g, SPECTRE.b, 0.45)

	# Corps en goutte, bas ondulé : une silhouette qui ne ressemble à aucun
	# autre mob du jeu, donc identifiable même à demi transparente.
	var pts := PackedVector2Array()
	for i in 18:
		var a := PI + PI * float(i) / 17.0
		pts.append(Vector2(cos(a) * 34.0, cy + sin(a) * 34.0))
	for i in 5:
		var t := float(i) / 4.0
		pts.append(Vector2(34.0 - 68.0 * t, cy + 30.0 + sin(_shimmer * 4.0 + t * 8.0) * 7.0))
	PlaceholderArt.draw_shape(self, pts, corps)

	# Deux yeux : ils s'allument quand il est révélé, c'est le signal que la
	# fenêtre de tir est ouverte.
	var oeil := Color(1.0, 0.95, 0.6) if revele else Color(0.35, 0.3, 0.45)
	draw_circle(Vector2(-12, cy - 4), 6.0, oeil)
	draw_circle(Vector2(12, cy - 4), 6.0, oeil)

	# Halo de révélation : il rétrécit à mesure que la fenêtre se referme, donc
	# le joueur sait combien de temps il lui reste pour frapper.
	if revele:
		var reste: float = _reveal_timer / reveal_duration
		draw_arc(Vector2(0, cy), 46.0, -PI * 0.5, -PI * 0.5 + TAU * reste, 32,
			Color(1.0, 0.95, 0.6, 0.85), 3.5, true)

	PlaceholderArt.draw_weakness_dot(self, Vector2(0, cy - 56), weak_to)
