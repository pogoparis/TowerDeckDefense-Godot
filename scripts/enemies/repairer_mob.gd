extends DroneMob
class_name RepairerMob
## RÉPARATEUR — le soigneur, et l'entrée de la Nature dans le jeu.
##
## ── SON IDÉE ──────────────────────────────────────────────────────────────
## Il ne frappe pas, il rend le reste de la vague plus dur à tuer : toutes les
## quelques secondes, il rend un pourcentage de leurs PV MAX aux mobs autour de
## lui. Tant qu'il vit, le paquet se stabilise et les tours n'avancent plus.
##
## C'est le premier ennemi qui change la question posée au joueur. Jusqu'ici on
## demandait « as-tu assez de dégâts ? ». Lui demande « sais-tu où frapper ? » —
## et c'est exactement à ça que sert la priorité de ciblage.
##
## ── POURQUOI IL EST FAIBLE À LA NATURE ───────────────────────────────────
## Ce n'est pas un choix arbitraire de couleur : la rouille et les spores
## grippent ses bras de réparation. La mécanique et la faiblesse racontent la
## même chose, donc le joueur n'a rien à mémoriser — le Panda Punk et la Nuée
## de Spores sont l'outil évident, et il le comprend en le voyant.
##
## ── CE QU'IL NE FAIT PAS ─────────────────────────────────────────────────
## Il ne SE soigne pas lui-même. Deux Réparateurs côte à côte se maintiendraient
## mutuellement à plein et deviendraient une paire increvable : le joueur
## n'aurait plus de solution, seulement un mur. Un soigneur doit rester fragile,
## c'est ce qui fait de sa mort la bonne réponse.

## Part des PV MAX rendue à chaque impulsion. En % du max et non en points
## fixes, pour qu'il compte autant sur un Pillard que sur un Tank — sinon il
## serait ridicule en fin de partie, exactement quand il devrait être menaçant.
@export var heal_ratio := 0.08
## Secondes entre deux impulsions.
@export var heal_period := 2.5
## Portée du soin. Assez large pour couvrir un groupe qui avance ensemble,
## assez courte pour qu'écarter la vague — repoussée, ralentissement — la casse.
@export var heal_radius := 130.0

var _heal_timer := 0.0
## Cibles de la dernière impulsion, pour tracer les faisceaux de soin.
var _beams: Array[Vector2] = []
var _beam_life := 0.0
var _pulse := 0.0


func _process(delta: float) -> void:
	super(delta)
	_pulse += delta

	if _beam_life > 0.0:
		_beam_life = maxf(0.0, _beam_life - delta)
		queue_redraw()

	_heal_timer -= delta
	if _heal_timer <= 0.0:
		_heal_timer = heal_period
		_pulse_heal()


## Une impulsion de soin sur les voisins vivants.
func _pulse_heal() -> void:
	if _is_dying:
		return

	var manager = _enemy_manager()
	if manager == null:
		return

	_beams.clear()
	for other in manager.get_all_enemies():
		if other == self or not is_instance_valid(other) or not other is EnemyBase:
			continue
		if other._is_dying or other.hp >= other.max_hp:
			continue
		if global_position.distance_to(other.global_position) > heal_radius:
			continue

		var soin: int = maxi(1, int(round(other.max_hp * heal_ratio)))
		other.hp = mini(other.max_hp, other.hp + soin)
		other.update_hp_bar()
		_beams.append(other.global_position - global_position)

	if _beams.is_empty():
		return

	# Le joueur doit VOIR pourquoi ses dégâts n'avancent plus. Sans ce retour,
	# un soigneur se lit comme un bug d'équilibrage.
	_beam_life = 0.45
	FloatingTextService.spawn(
		get_tree().current_scene,
		global_position + Vector2(0, -110),
		"+RÉPARE ×%d" % _beams.size(), Color(0.45, 0.9, 0.4), 1.0
	)
	queue_redraw()


## L'EnemyManager n'est pas un autoload : on le lit sur la scène de niveau.
func _enemy_manager() -> EnemyManager:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get("enemy_manager") as EnemyManager


# ══════════════════════════════════════════════════════
#            SILHOUETTE PROVISOIRE
# ══════════════════════════════════════════════════════

const CHASSIS := Color(0.55, 0.58, 0.52)
const VERT := Color(0.40, 0.85, 0.35)

func _draw() -> void:
	# Les faisceaux se dessinent même quand les sprites existeront : ils sont
	# l'information, pas la décoration.
	if _beam_life > 0.0:
		var a: float = _beam_life / 0.45
		for offset in _beams:
			draw_line(Vector2(0, -70), offset + Vector2(0, -50),
				Color(VERT.r, VERT.g, VERT.b, 0.55 * a), 3.0, true)

	# Auréole de portée, discrète, qui bat au rythme des impulsions : elle dit
	# QUI est soigné sans qu'il faille lire un tableau.
	var phase: float = 1.0 - fmod(_heal_timer, heal_period) / heal_period
	draw_circle(Vector2(0, -50), heal_radius * phase,
		Color(VERT.r, VERT.g, VERT.b, 0.05))

	if tex_south != null:
		return

	var cy := -70.0
	PlaceholderArt.draw_box(self, Vector2(0, cy), Vector2(56, 46), CHASSIS)
	# Les deux bras de réparation : c'est eux que la Nature grippe.
	PlaceholderArt.draw_box(self, Vector2(-40, cy + 6), Vector2(26, 12), CHASSIS.darkened(0.2))
	PlaceholderArt.draw_box(self, Vector2(40, cy + 6), Vector2(26, 12), CHASSIS.darkened(0.2))
	# Croix de soin : le symbole se lit instantanément, même à 110 px.
	var battement := 1.0 + sin(_pulse * 3.0) * 0.12
	PlaceholderArt.draw_box(self, Vector2(0, cy), Vector2(28 * battement, 9), VERT)
	PlaceholderArt.draw_box(self, Vector2(0, cy), Vector2(9, 28 * battement), VERT)

	PlaceholderArt.draw_weakness_dot(self, Vector2(0, cy - 44), weak_to)
