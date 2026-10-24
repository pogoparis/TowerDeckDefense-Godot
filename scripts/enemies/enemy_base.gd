extends Node2D
class_name EnemyBase

## Même script que celui utilisé par WaveManager pour faire avancer les ennemis :
## les enfants d'une scission doivent se déplacer exactement comme les autres.
const PATH_FOLLOW_SCRIPT = preload("res://scripts/core/path_follow_2d.gd")

@export var max_hp := 30
@export var speed := 120.0
## Caps gagnées en tuant cet ennemi. Chaque kill DOIT payer (feeling BTD6 :
## "chaque pop rapporte") — c'est le moteur du snowball économique.
##
## Ces valeurs ont ABSORBÉ l'ancien butin de Ferraille : deux monnaies qui
## servaient à acheter des choses différentes ne se disputaient rien, donc
## aucun arbitrage n'existait. Une seule monnaie, et chaque fin de vague repose
## la question de BTD6 : une tour de plus, ou une tour meilleure ?
@export var cap_reward := 1
@export var leak_damage := 1
## Blindage : dégâts retirés à CHAQUE coup reçu (voir take_damage).
## 0 = pas de blindage. À réserver aux mobs tardifs.
@export var armor := 0
## Part des dégâts qui passe TOUJOURS, quel que soit le blindage. Garde-fou
## indispensable avec des dégâts de base à un chiffre : sans lui, `armor` ne
## réduit pas les petites tours, il les supprime.
const ARMOR_MIN_RATIO := 0.45

@export_group("Faiblesses élémentaires")
## Élément contre lequel ce mob s'effondre (dégâts ×[member weakness_mult]).
## C'est LE levier qui donne un sens au choix de deck avant un niveau : le
## joueur doit pouvoir se dire "ce niveau est plein de drones, je prends
## l'Électricité". NONE = aucune faiblesse.
@export var weak_to: ElementType.Type = ElementType.Type.NONE
## Élément qui glisse sur lui (dégâts ×[member resistance_mult]). NONE = aucune.
@export var resists: ElementType.Type = ElementType.Type.NONE
## ×2 : assez fort pour qu'on le SENTE sans lecture de tableau. En dessous
## (×1.3), le joueur ne perçoit pas la différence et le système ne sert à rien.
@export var weakness_mult := 2.0
## ×0.5 : la mauvaise réponse coûte cher, mais reste jouable. Jamais 0 — un
## élément totalement inutile rendrait un deck injouable sur un niveau.
@export var resistance_mult := 0.5
@export var death_explosion_scene: PackedScene

@export_group("Scission à la mort")
## Ennemi libéré quand celui-ci meurt, et en quelle quantité. C'est le patron
## des céramiques/MOAB de BTD6 : tuer la grosse cible n'est pas la fin, c'est le
## début du vrai problème. Ça évite qu'un mob à gros PV ne soit qu'une barre de
## vie plus longue.
@export var death_spawn_scene: PackedScene
@export var death_spawn_count := 0
## Écart de progression entre les enfants, en pixels le long du chemin : sans
## lui ils sortiraient tous empilés au même point.
@export var death_spawn_spread := 45.0

## Multiplicateur de PV de la vague, mémorisé pour que les enfants d'une
## scission héritent de la même montée en puissance. Sans ça, un mob scindé en
## vague 12 lâcherait des enfants au niveau de la vague 1.
var wave_scale := 1.0

@export_group("Mort — game feel")
## Taille du BOOM à la mort. 1.0 = normal, 1.8 = gros ennemi, 2.5 = boss.
@export var death_boom_scale := 1.0
## Taille des VISUELS d'explosion (feu/onde/étincelles). Plus petit = plus discret.
@export var death_explosion_scale := 0.65
## Intensité du tremblement d'écran à la mort (pixels).
@export var death_shake := 12.0
## Seuil de death_boom_scale au-dessus duquel la mort mérite un "BOUM !".
## 1.2 → Pillards et Kamikazés (1.0) meurent en silence ; Drone (1.3),
## Tank (1.8), Drone Punk (2.0) et MiniBoss (2.5) sont annoncés.
const BOOM_ONOMATOPOEIA_MIN_SCALE := 1.2

@onready var enemy_manager: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")
@onready var status_icons: StatusIconContainer = $StatusIcons
@onready var hp_fill: ColorRect = get_node_or_null("HPBarContainer/HPFill")
@onready var hp_background: ColorRect = get_node_or_null("HPBarContainer/HPBackground")

var hp := 0
## Vrai dès que l'ennemi entame sa mort — évite les dégâts/die() en double
## (ex : explosions en chaîne d'ExplosiveMob → récursion infinie).
var _is_dying := false
var slow_multiplier := 1.0
var slow_timer := 0.0

## ── GIVRE (Glace) ────────────────────────────────────────────
## Volontairement SÉPARÉ de slow_multiplier. `apply_slow()` écrase la valeur
## courante : deux sources de ralentissement s'annulent l'une l'autre, et le
## Requin doit déjà se protéger avec un `if slow_multiplier > …`. Un gel
## cumulatif branché là-dessus serait effacé par le premier tir d'eau venu.
## Ici le givre s'empile dans son propre canal, et la vitesse finale prend le
## PLUS FORT des deux ralentissements (voir [method speed_multiplier]).
var chill_multiplier := 1.0
var chill_timer := 0.0
## Perte de vitesse par impact. Plancher à CHILL_FLOOR : un ennemi totalement
## immobile serait ingérable (les vagues s'empileraient à l'entrée du chemin).
const CHILL_FLOOR := 0.4

# Throttle anti-surcharge : une seule onomatopée à la fois sur cet ennemi.
var _onomatopoeia_cooldown := 0.0
const ONOMATOPOEIA_COOLDOWN := 1
var status_effects: Dictionary = {}

var _knockback_cooldown := 0.0
const KNOCKBACK_COOLDOWN := 3.0   # secondes entre deux knockbacks

## Multiplicateur de dégâts subis quand l'ennemi porte la Marque d'Ombre.
const MARKED_DAMAGE_MULT := 1.4

func _ready():
	add_status("test", 3.0)

	if not hp_fill:
		push_error("HPFill introuvable dans " + str(name))
		return

	hp = max_hp

	update_hp_bar()

	if enemy_manager:
		enemy_manager.register_enemy(self)

func add_status(
	status_id: String,
	duration: float = 3.0
):

	if has_status(status_id):
		return

	status_effects[status_id] = duration

	if status_icons:
		status_icons.update_statuses(
			status_effects
		)


## PROLONGE un statut déjà présent (ou l'applique s'il ne l'est pas).
##
## `add_status` sort immédiatement si le statut existe déjà — c'est voulu pour
## les tirs répétés, mais ça rend impossible toute réaction qui ALLONGE un
## effet. On ne raccourcit jamais une durée en cours.
func extend_status(status_id: String, duration: float) -> void:
	if not has_status(status_id):
		add_status(status_id, duration)
		return
	status_effects[status_id] = maxf(status_effects[status_id], duration)


## Applique un debuff et affiche son onomatopée comic UNIQUEMENT si le
## statut est nouveau sur cet ennemi (évite le spam d'images cartoon).
func apply_debuff(status_id: String, duration: float, pop_key: String = "") -> void:
	var was_present := has_status(status_id)

	add_status(status_id, duration)

	if not was_present:
		try_spawn_onomatopoeia(pop_key)


## Affiche une onomatopée au-dessus de l'ennemi — UNE SEULE à la fois.
## Si une vient d'apparaître sur ce mob (cooldown actif), on ignore : ça évite
## que deux tours qui tirent ensemble empilent deux images sur le même ennemi.
func try_spawn_onomatopoeia(pop_key: String, width: float = 120.0) -> void:
	if pop_key == "" or _onomatopoeia_cooldown > 0.0:
		return

	_onomatopoeia_cooldown = ONOMATOPOEIA_COOLDOWN

	var effects := get_tree().current_scene.get_node_or_null("World/EffectsContainer")
	if effects:
		OnomatopoeiaPop.spawn(
			effects,
			global_position + Vector2(0, -50),
			pop_key,
			width,
			1.4
		)
	
func remove_status(status_id: String):

	status_effects.erase(status_id)

	if status_icons:
		status_icons.update_statuses(
			status_effects
		)

func get_status_time(
	status_id: String
) -> float:

	if not status_effects.has(status_id):
		return 0.0

	return status_effects[status_id]

func has_status(status_id: String) -> bool:

	return (
		status_effects.has(status_id)
		and
		status_effects[status_id] > 0.0
	)



## [param kind] contrôle le chiffre de dégâts flottant :
##   "normal" = coup direct (bien visible)
##   "tick"   = dégâts sur la durée (petit, discret)
##   "silent" = aucun chiffre (l'appelant affiche déjà son propre texte)
func take_damage(
	amount: int,
	kind: String = "normal",
	element: ElementType.Type = ElementType.Type.NONE
):

	# Déjà en train de mourir → on ignore (stoppe les explosions en chaîne récursives).
	if _is_dying:
		return

	# AFFINITÉ ÉLÉMENTAIRE — avant le blindage, pour que la faiblesse aide
	# vraiment à percer une armure (sinon on soustrait d'abord, on double
	# ensuite, et le bon élément ne récompense presque plus).
	var affinity := 1.0
	if element != ElementType.Type.NONE:
		if element == weak_to:
			affinity = weakness_mult
		elif element == resists:
			affinity = resistance_mult
	if affinity != 1.0:
		amount = int(round(amount * affinity))

	# BLINDAGE : réduction FORFAITAIRE par coup, appliquée avant tout multiplicateur.
	# C'est un axe de difficulté différent des PV : une tour qui tape vite et
	# faible (Chouette, Luciole) voit ses dégâts s'effondrer, alors qu'une grosse
	# frappe (Gardien, Punk Explosif) perd à peine. Ça force à VARIER son deck au
	# lieu d'empiler la même tour — l'équivalent des céramiques de BTD6.
	# ⚠ Le plancher n'est PAS à 1 mais à ARMOR_MIN_RATIO des dégâts entrants.
	# Les dégâts de ce jeu sont petits (4 à 16) : une soustraction forfaitaire
	# de 4 retire 75 % à une Luciole et, cumulée à une résistance ×0.5, ramenait
	# le Gardien de 16 à 4 contre un Drone. Le blindage doit pénaliser les tirs
	# faibles, pas les annuler — sinon un mob blindé devient increvable pour la
	# moitié du roster et le deck qui le croise n'a plus de partie à jouer.
	if armor > 0 and amount > 0:
		amount = maxi(int(ceil(amount * ARMOR_MIN_RATIO)), amount - armor)

	# Marque d'Ombre : l'ennemi marqué encaisse plus de dégâts de TOUTES les
	# sources (tours, zones, DoT…). C'est le rôle "amplificateur" du Vampire.
	# Après le blindage : le Vampire amplifie ce qui PASSE réellement.
	if has_status(StatusIds.MARKED):
		amount = int(round(amount * MARKED_DAMAGE_MULT))

	hp -= amount

	if hp < 0:
		hp = 0

	update_hp_bar()

	if kind != "silent" and amount > 0:
		# Un système de faiblesse invisible n'existe pas pour le joueur : le
		# chiffre change de tête quand l'élément est le bon (ou le mauvais).
		if affinity > 1.0 and kind == "normal":
			_spawn_damage_number(amount, "weak")
		elif affinity < 1.0 and kind == "normal":
			_spawn_damage_number(amount, "resist")
		else:
			_spawn_damage_number(amount, kind)

	if hp <= 0:
		_is_dying = true
		die()


func _spawn_damage_number(amount: int, kind: String) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var color: Color
	var text_scale: float
	if kind == "tick":
		color = Color(1.0, 0.55, 0.1, 0.85)   # orange, discret
		text_scale = 0.7
	elif kind == "weak":
		color = Color(0.4, 1.0, 0.5)           # vert vif : "c'est le bon élément"
		text_scale = 1.5
	elif kind == "resist":
		color = Color(0.6, 0.62, 0.7)          # gris terne : "ça glisse dessus"
		text_scale = 0.85
	else:
		color = Color(1.0, 0.95, 0.4)          # jaune vif, bien visible
		text_scale = 1.15

	var offset := Vector2(randf_range(-14.0, 14.0), -38.0)
	FloatingTextService.spawn(scene, global_position + offset, str(amount), color, text_scale)

func update_hp_bar():

	if not hp_fill:
		return

	var ratio := float(hp) / float(max_hp)
	var bar_width := hp_background.offset_right if hp_background else 40.0

	hp_fill.offset_right = bar_width * ratio

	if ratio > 0.6:
		hp_fill.color = Color(0.2, 1, 0.2)
	elif ratio > 0.3:
		hp_fill.color = Color(1, 0.7, 0.2)
	else:
		hp_fill.color = Color(1, 0.2, 0.2)

func apply_slow(multiplier: float, duration: float):

	slow_multiplier = multiplier
	slow_timer = duration


## Applique un cran de GIVRE. Chaque impact multiplie la vitesse par
## [param step] (0.9 = −10 %), jusqu'au plancher CHILL_FLOOR, et rafraîchit la
## durée. C'est le rôle propre de la Glace : là où l'Eau et l'Air agissent par
## à-coups, elle INSTALLE un état qui s'aggrave tant qu'on tire dessus — ce qui
## récompense le fait de poser deux tours Glace dont les zones se recouvrent.
func add_chill(step: float, duration: float) -> void:
	chill_multiplier = maxf(CHILL_FLOOR, chill_multiplier * step)
	# On ne raccourcit jamais un givre plus long déjà en place.
	chill_timer = maxf(chill_timer, duration)
	# Pas d'onomatopée : "brr" n'existe pas encore dans OnomatopoeiaPop.TEXTURES.
	# Le jour où un assets/FX/brr.png est ajouté au dictionnaire, il suffit de
	# passer "brr" en 3e argument ici.
	apply_debuff(StatusIds.CHILLED, chill_timer)


## Vitesse effective = le ralentissement le plus FORT en vigueur.
## On ne multiplie pas les deux : cumuler un gel à ×0.4 avec la Vapeur à ×0.2
## donnerait ×0.08, soit un ennemi à l'arrêt — et la file d'attente qui va avec.
func speed_multiplier() -> float:
	# ENRACINÉ : arrêt net. C'est le seul statut qui immobilise vraiment —
	# la Chouette repousse d'un coup, le Pingouin ralentit, le Bosquet ARRÊTE.
	# Le statut se renouvelle tant que l'ennemi reste dans les ronces et expire
	# 3 s après en être sorti (voir Phenomenon.apply_contamination).
	if has_status(StatusIds.ROOTED):
		return 0.0
	return minf(slow_multiplier, chill_multiplier)


func apply_knockback(force: float):
	if _knockback_cooldown > 0.0:
		return   # Immunité temporaire

	var pf := get_parent()
	if not (pf is PathFollow2D):
		return

	# Recul instantané sur le progress (pas de tween : _physics_process
	# ajoute progress chaque frame et annulerait le tween)
	pf.progress = max(0.0, pf.progress - force)

	# Gèle le mouvement pendant 0.3s le temps que le recul soit visible
	apply_slow(0.0, 0.3)

	# Shake du visuel
	_shake_visual(0.4)

	# Déclenche le cooldown
	_knockback_cooldown = KNOCKBACK_COOLDOWN

## WET : le mob dérape et se bloque net un court instant (sol glissant).
func _do_wet_slip() -> void:
	apply_slow(0.0, WET_SLIP_STOP)
	var visual := get_node_or_null("VisualRoot")
	if visual:
		var t := create_tween()
		t.tween_property(visual, "rotation_degrees", 14.0, 0.1).set_trans(Tween.TRANS_SINE)
		t.tween_property(visual, "rotation_degrees", 0.0, 0.3) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _shake_visual(duration: float):
	var visual := get_node_or_null("VisualRoot")
	if not visual:
		return

	var origin: Vector2 = visual.position
	var shake_tween := create_tween()

	# Oscille rapidement en X (recul ressenti)
	var steps := 6
	for i in steps:
		var t: float = float(i) / steps
		var strength: float = lerp(14.0, 0.0, t)   # décroît avec le temps
		var offset_x: float = strength * (-1.0 if i % 2 == 0 else 1.0)
		var offset_y: float = randf_range(-strength * 0.3, strength * 0.3)
		shake_tween.tween_property(visual, "position",
			origin + Vector2(offset_x, offset_y),
			duration / steps
		).set_trans(Tween.TRANS_SINE)

	# Retour en position initiale
	shake_tween.tween_property(visual, "position", origin, 0.05)


var _wet_tick_timer := 0.0
const WET_TICK_INTERVAL := 1.0

# BURNING : dégâts sur la durée infligés en continu tant que le statut dure.
var _burn_tick_timer := 0.0
const BURN_TICK_INTERVAL := 0.5
const BURN_TICK_DAMAGE := 4

## POISON — en POURCENTAGE des PV max, là où le feu fait un forfait.
## Refaire un BURNING vert n'aurait servi à rien : ici le poison est ridicule
## sur un Pillard (40 PV → moins d'1 point) et mord sur un Tank ou un Drone
## Punk. Ça donne au Panda un rôle propre — le tueur de GROS — face au Punk
## Explosif qui est le tueur de foule.
var _poison_tick_timer := 0.0
const POISON_TICK_INTERVAL := 0.6
const POISON_MAX_HP_RATIO := 0.025
## Plancher à 1 : sinon le poison ne ferait littéralement rien sur les petits,
## et un statut qui n'a aucun effet visible est un statut qui ment.
const POISON_MIN_DAMAGE := 1

# WET = sol glissant : de temps en temps (rare) le mob dérape et se bloque net.
var _wet_slip_timer := 0.0
const WET_SLIP_INTERVAL := 1.0   # on tente un dérapage ~chaque seconde
const WET_SLIP_CHANCE := 0.15    # 15% → rare mais visible
const WET_SLIP_STOP := 0.45      # durée du blocage

func _process(delta):

	update_statuses(delta)

	if _knockback_cooldown > 0.0:
		_knockback_cooldown -= delta

	if _onomatopoeia_cooldown > 0.0:
		_onomatopoeia_cooldown -= delta

	# WET : sol glissant + Flaque Toxique (dégâts si bonus actif)
	if has_status(StatusIds.WET):
		var wet_dmg := RunBonuses.get_wet_tick_damage()
		if wet_dmg > 0:
			_wet_tick_timer -= delta
			if _wet_tick_timer <= 0.0:
				_wet_tick_timer = WET_TICK_INTERVAL
				take_damage(wet_dmg, "tick")

		# Dérapage : de temps en temps le mob glisse et se bloque net.
		_wet_slip_timer -= delta
		if _wet_slip_timer <= 0.0:
			_wet_slip_timer = WET_SLIP_INTERVAL
			if randf() < WET_SLIP_CHANCE:
				_do_wet_slip()

	# BURNING : dégâts sur la durée (toujours actifs, pas besoin de bonus)
	if has_status(StatusIds.BURNING):
		_burn_tick_timer -= delta
		if _burn_tick_timer <= 0.0:
			_burn_tick_timer = BURN_TICK_INTERVAL
			take_damage(BURN_TICK_DAMAGE, "tick", ElementType.Type.FIRE)

	# POISON : proportionnel aux PV MAX, donc constant en pourcentage quelle que
	# soit la vague — il ne se dévalue pas quand les ennemis grossissent.
	if has_status(StatusIds.POISONED):
		_poison_tick_timer -= delta
		if _poison_tick_timer <= 0.0:
			_poison_tick_timer = POISON_TICK_INTERVAL
			var dmg: int = maxi(POISON_MIN_DAMAGE, int(round(max_hp * POISON_MAX_HP_RATIO)))
			take_damage(dmg, "tick", ElementType.Type.NATURE)

	if slow_timer > 0:

		slow_timer -= delta

		if slow_timer <= 0:

			slow_multiplier = 1.0

	# Le givre se dissipe d'un coup à l'échéance (et non progressivement) :
	# le joueur doit voir un ennemi "repartir", c'est ce qui lui dit qu'il faut
	# entretenir le gel.
	if chill_timer > 0.0:
		chill_timer -= delta
		if chill_timer <= 0.0:
			chill_multiplier = 1.0
			remove_status(StatusIds.CHILLED)

func update_statuses(delta):

	var expired := []
	
	for status_id in status_effects.keys():
		
		status_effects[status_id] -= delta

		if status_effects[status_id] <= 0.0:

			expired.append(status_id)

	for status_id in expired:

		status_effects.erase(status_id)
	
	if expired.size() > 0 and status_icons:

		status_icons.update_statuses(
			status_effects
		)
	
func die():
	# ── GROS BOOM ────────────────────────────────────────────
	Audio.play_sfx(preload("res://assets/audio/sfx/enemy_death.wav"), -4.0, 0.12)
	Audio.play_sfx(
		preload("res://assets/audio/sfx/explosion.wav"),
		-6.0 + death_boom_scale * 2.0,
		0.1
	)

	# Tremblement d'écran + micro-gel proportionnels à la taille.
	Juice.shake(death_shake * death_boom_scale, 0.35)
	Juice.hit_stop(0.05 + (death_boom_scale - 1.0) * 0.03)

	if death_explosion_scene:

		var explosion = death_explosion_scene.instantiate() as Node2D
		var effects = get_tree().current_scene.get_node("World/EffectsContainer")

		# Taille définie AVANT add_child : le _ready dessine les visuels avec.
		if "size" in explosion:
			explosion.size = death_boom_scale * death_explosion_scale

		effects.add_child(explosion)

		explosion.global_position = global_position
		explosion.z_index = 100

	# BOOM ! — réservé aux morts NOTABLES (Tank, Drone, Drone Punk, MiniBoss).
	# Il partait sur chaque mort, Pillards compris : en vague 10, une trentaine
	# de mobs meurent en quelques secondes et l'écran devient illisible. Un
	# BOUM doit signaler un évènement ; s'il accompagne tout, il ne signale
	# plus rien. Le seuil suit death_boom_scale, qui dit déjà "ce mob est gros".
	if death_boom_scale >= BOOM_ONOMATOPOEIA_MIN_SCALE:
		var effects_root := get_tree().current_scene.get_node_or_null("World/EffectsContainer")
		if effects_root:
			OnomatopoeiaPop.spawn(effects_root, global_position, "boom", 170.0 * death_boom_scale)

	if cap_reward > 0:
		Player.add_caps(cap_reward)

	if enemy_manager:
		enemy_manager.unregister_enemy(self)

	# La scission AVANT de libérer le parent : on a besoin de sa progression
	# pour placer les enfants là où la grosse cible est tombée.
	_spawn_death_children()

	# Libérer aussi le PathFollow2D parent pour qu'il ne continue pas jusqu'à la fin
	var pf := get_parent()
	if pf is PathFollow2D:
		pf.queue_free()
	else:
		queue_free()


## Libère les enfants sur le chemin, à la position de la mort.
func _spawn_death_children() -> void:
	if death_spawn_scene == null or death_spawn_count <= 0:
		return

	var pf := get_parent()
	if not (pf is PathFollow2D):
		return
	var path := pf.get_parent()
	if not (path is Path2D):
		return

	var origin: float = pf.progress

	for i in death_spawn_count:
		var child_pf := PathFollow2D.new()
		child_pf.set_script(PATH_FOLLOW_SCRIPT)
		child_pf.rotates = false
		child_pf.loop = false

		var child := death_spawn_scene.instantiate() as EnemyBase
		if child == null:
			child_pf.queue_free()
			return
		child_pf.add_child(child)
		path.add_child(child_pf)

		# Étalés EN ARRIÈRE du point de mort : jamais devant, sinon la scission
		# ferait gagner du terrain aux ennemis et punirait le joueur d'avoir tué.
		child_pf.progress = maxf(0.0, origin - death_spawn_spread * i)

		# Les enfants héritent de la montée en puissance de la vague.
		child.wave_scale = wave_scale
		if wave_scale > 1.0:
			child.max_hp = int(round(child.max_hp * wave_scale))
			child.hp = child.max_hp
			child.update_hp_bar()

		var top_hud := get_tree().current_scene.get_node_or_null("UI/RootUI/TopHUD")
		if top_hud and top_hud.has_method("on_enemy_spawned"):
			top_hud.on_enemy_spawned()
