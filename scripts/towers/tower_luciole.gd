extends ProjectileTower
class_name TowerLuciole
## Tour LUMIÈRE — la Luciole et son ventre lanterne.
##
## Rôle : SUPPORT côté allié. Elle projette un HALO : toutes les tours dans
## son rayon gagnent des dégâts et tirent plus vite (voir light_damage_mult /
## light_fire_rate_mult sur BaseTower).
##
## C'est le miroir de l'Ombre : le Vampire affaiblit les ENNEMIS, la Luciole
## renforce TES TOURS. Ses propres dégâts sont faibles — sa valeur est
## entièrement dans le placement de son halo.

## Rayon du halo (en pixels monde). Les tours à l'intérieur sont renforcées.
@export var aura_radius := 190.0

const AURA_REFRESH := 0.2
var _aura_timer := 0.0


func _ready():
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)
	if is_ghost:
		return

	_aura_timer -= delta
	if _aura_timer <= 0.0:
		_aura_timer = AURA_REFRESH
		_recompute_light_auras()

	queue_redraw()


## Recalcule le halo de TOUTES les tours à partir de TOUTES les Lucioles.
## Idempotent : plusieurs Lucioles ne se marchent pas dessus (on recalcule
## l'état complet à chaque passe au lieu d'empiler des on/off).
func _recompute_light_auras() -> void:
	var towers := get_tree().get_nodes_in_group("towers")

	var lamps: Array = []
	for n in towers:
		var lamp := n as TowerLuciole
		if lamp != null and not lamp.is_ghost:
			lamps.append(lamp)

	for n in towers:
		var t := n as BaseTower
		if t == null or t.is_ghost:
			continue
		var lit := false
		for lamp in lamps:
			if lamp == t:
				continue   # la Luciole ne se booste pas elle-même
			if t.global_position.distance_to(lamp.global_position) <= lamp.aura_radius:
				lit = true
				break
		t.set_light_buff(lit)


## Halo visible : le joueur doit VOIR quelles tours il éclaire pour décider
## où poser la Luciole.
func _draw() -> void:
	if is_ghost:
		return
	# ⚠ PAS de cercle à bordure nette : le cercle de SÉLECTION d'une tour est un
	# arc orange (1, 0.6, 0) de 2 px, et l'ancien halo était un arc doré de
	# 2.5 px — même teinte, même forme, on ne distinguait plus "cette tour est
	# sélectionnée" de "cette tour éclaire la zone".
	#
	# Un halo doit se lire comme de la LUMIÈRE, pas comme une portée : dégradé
	# doux du centre vers l'extérieur, sans contour, et blanc chaud plutôt
	# qu'orange pour trancher avec la sélection.
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.0015) * 0.02
	var r := aura_radius * pulse

	# Cercles concentriques de faible opacité : la superposition crée une
	# décroissance progressive vers les bords, sans jamais dessiner de ligne.
	var layers := 12
	for i in layers:
		var t := float(i) / float(layers)          # 0 = bord, 1 = centre
		draw_circle(Vector2.ZERO, r * (1.0 - t * 0.92), Color(1.0, 0.96, 0.78, 0.016))
