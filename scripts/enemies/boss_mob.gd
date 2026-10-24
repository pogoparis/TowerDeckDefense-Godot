extends EnemyBase
class_name BossMob
## MINIBOSS — le climax du niveau.
##
## ── POURQUOI CE SCRIPT EXISTE ─────────────────────────────────────────────
## Le MiniBoss était un EnemyBase avec 900 PV : aucune phase, aucune capacité,
## aucun comportement. Un sac à points de vie. Or le boss est le moment où le
## joueur doit MESURER ce qu'il a construit — et un mur de PV ne mesure rien,
## il ne fait que durer.
##
## Sa mécanique : un BOUCLIER ÉLÉMENTAIRE TOURNANT. Il devient presque immunisé
## à un élément, qui change toutes les quelques secondes et s'affiche au-dessus
## de lui.
##
## C'est la mécanique choisie parmi trois parce qu'elle exerce l'IDENTITÉ du
## jeu : elle punit le mono-élément, récompense les decks variés, et oblige le
## joueur à REGARDER le boss au lieu de regarder sa barre de vie descendre.

## Éléments que le bouclier peut prendre. On ne met que ceux dont une tour
## existe, sinon le boucler serait parfois « immunisé à rien ».
const SHIELD_POOL: Array[ElementType.Type] = [
	ElementType.Type.FIRE,
	ElementType.Type.ELECTRIC,
	ElementType.Type.EARTH,
	ElementType.Type.NATURE,
	ElementType.Type.WATER,
	ElementType.Type.ICE,
]

## Durée d'un bouclier. 5 s : assez long pour que le joueur ait le temps de le
## lire et de réagir, assez court pour que la rotation reste un rythme.
@export var shield_duration := 5.0
## Ce qui passe malgré le bouclier. Pas 0 : un élément totalement inutile
## rendrait un deck mono-élément incapable de finir le niveau, ce qui punirait
## un choix fait AVANT d'avoir l'information.
@export var shield_damage_ratio := 0.15

var shield_element: ElementType.Type = ElementType.Type.NONE
var _shield_timer := 0.0
var _shield_label: Label


func _ready() -> void:
	super()
	_build_shield_label()
	_rotate_shield()


func _process(delta: float) -> void:
	super(delta)
	_shield_timer -= delta
	if _shield_timer <= 0.0:
		_rotate_shield()
	_update_shield_label()


func _rotate_shield() -> void:
	# Jamais deux fois le même d'affilée : sinon le joueur croit que la
	# mécanique est cassée.
	var previous := shield_element
	var candidates := SHIELD_POOL.duplicate()
	candidates.erase(previous)
	shield_element = candidates[randi() % candidates.size()]
	_shield_timer = shield_duration

	Juice.shake(5.0, 0.15)
	var scene := get_tree().current_scene
	if scene:
		FloatingTextService.spawn(
			scene, global_position + Vector2(0, -120),
			"BOUCLIER %s" % ElementType.label(shield_element).to_upper(),
			ElementType.color(shield_element), 1.2
		)


## Le bouclier réduit fortement l'élément affiché. Appliqué AVANT tout le reste
## (affinité, blindage, marque) : c'est une propriété du boss, pas un modificateur.
func take_damage(
	amount: int,
	kind: String = "normal",
	element: ElementType.Type = ElementType.Type.NONE
):
	if element != ElementType.Type.NONE and element == shield_element:
		amount = maxi(1, int(round(amount * shield_damage_ratio)))
		kind = "resist"
	super(amount, kind, element)


# ── Affichage du bouclier ─────────────────────────────
# Sans repère visible, la mécanique est invisible : le joueur constaterait
# seulement que ses dégâts « varient bizarrement ».

func _build_shield_label() -> void:
	_shield_label = Label.new()
	_shield_label.add_theme_font_size_override("font_size", 30)
	_shield_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_shield_label.add_theme_constant_override("outline_size", 6)
	_shield_label.z_index = 40
	# Compense le scale racine du boss (1.6) pour une taille constante à l'écran.
	var s: float = scale.y if scale.y != 0.0 else 1.0
	_shield_label.scale = Vector2(1.0 / s, 1.0 / s)
	_shield_label.position = Vector2(-30.0 / s, -150.0 / s)
	add_child(_shield_label)


func _update_shield_label() -> void:
	if _shield_label == null:
		return
	_shield_label.text = "🛡 %s" % ElementType.icon(shield_element)
	# Il pulse pendant la dernière seconde : le joueur anticipe le changement.
	var alpha := 1.0
	if _shield_timer < 1.0:
		alpha = 0.4 + 0.6 * absf(sin(Time.get_ticks_msec() * 0.012))
	_shield_label.modulate = ElementType.color(shield_element)
	_shield_label.modulate.a = alpha
