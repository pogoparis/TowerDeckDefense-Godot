extends Control
class_name DangerOverlay
## Mise en scène de la FUITE et du danger de mort.
##
## ── POURQUOI ÇA EXISTE ────────────────────────────────────────────────────
## Perdre un PV était presque silencieux : un son discret et un chiffre qui
## changeait dans un coin du HUD. Or c'est le SEUL moment de tension du jeu.
## Un joueur qui ne sent pas qu'il est en train de perdre ne ressent pas non
## plus qu'il se rattrape — et la remontada, qui est l'un des cinq moteurs de
## hype, n'existe tout simplement pas.
##
## Deux langages distincts, à ne pas confondre :
##   • la FUITE est un ÉVÈNEMENT   → un flash bref et violent
##   • le DANGER est un ÉTAT        → une bordure qui respire, en continu

## PV en dessous desquels la bordure de danger s'allume en continu.
const DANGER_HP := 6

var _flash := 0.0
var _pulse := 0.0


func _ready() -> void:
	# L'overlay ne doit JAMAIS intercepter un clic : le joueur continue de
	# jouer pendant qu'il clignote.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 90
	Player.leaked.connect(_on_leaked)
	Player.base_hp_changed.connect(func(_hp): queue_redraw())


func _process(delta: float) -> void:
	_pulse += delta
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 2.2)
		queue_redraw()
	elif Player.base_hp <= DANGER_HP and Player.base_hp > 0:
		queue_redraw()


func _on_leaked(amount: int, remaining: int) -> void:
	_flash = 1.0

	# Micro-gel + secousse : le jeu S'ARRÊTE une fraction de seconde. C'est ce
	# qui transforme « j'ai perdu un point » en « je viens de me faire avoir ».
	# Proportionnel aux dégâts : un MiniBoss qui passe doit faire bien plus mal
	# qu'un Pillard.
	Juice.hit_stop(0.06 + 0.02 * amount)
	Juice.shake(10.0 + 4.0 * amount, 0.35)

	var scene := get_tree().current_scene
	if scene is Node2D:
		FloatingTextService.spawn(
			scene,
			Vector2(get_viewport().get_visible_rect().size * Vector2(0.5, 0.35)),
			"−%d PV  ·  %d restants" % [amount, remaining],
			Color(1.0, 0.25, 0.2), 1.8
		)


func _draw() -> void:
	var rect := get_viewport_rect()

	# ── FUITE : un flash rouge qui s'estompe vite ─────────────────────────
	if _flash > 0.0:
		var a: float = _flash * _flash * 0.35      # décroissance en courbe :
		draw_rect(rect, Color(0.9, 0.05, 0.05, a)) # violent puis vite oublié

	# ── DANGER : bordure qui respire tant que les PV sont bas ─────────────
	if Player.base_hp <= DANGER_HP and Player.base_hp > 0:
		# Plus les PV sont bas, plus le souffle est rapide et intense.
		var severity: float = 1.0 - float(Player.base_hp) / float(DANGER_HP)
		var breath: float = 0.5 + 0.5 * sin(_pulse * (3.0 + severity * 4.0))
		var alpha: float = (0.18 + 0.35 * severity) * breath
		var thickness: float = 26.0 + 34.0 * severity

		# Un cadre, pas un voile : on ne masque jamais le terrain de jeu.
		for i in 8:
			var t: float = float(i) / 8.0
			var inset: float = thickness * t
			draw_rect(
				Rect2(rect.position + Vector2(inset, inset),
					rect.size - Vector2(inset, inset) * 2.0),
				Color(1.0, 0.12, 0.08, alpha / 8.0),
				false, thickness / 8.0
			)
