extends Node2D
class_name EnemyBase

@export var max_hp := 30
@export var speed := 120.0
@export var scrap_reward := 5
@export var leak_damage := 1
@export var death_explosion_scene: PackedScene

@export_group("Mort — game feel")
## Taille du BOOM à la mort. 1.0 = normal, 1.8 = gros ennemi, 2.5 = boss.
@export var death_boom_scale := 1.0
## Taille des VISUELS d'explosion (feu/onde/étincelles). Plus petit = plus discret.
@export var death_explosion_scale := 0.65
## Intensité du tremblement d'écran à la mort (pixels).
@export var death_shake := 12.0

@onready var enemy_manager: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")
@onready var status_icons: StatusIconContainer = $StatusIcons
@onready var hp_fill: ColorRect = get_node_or_null("HPBarContainer/HPFill")
@onready var hp_background: ColorRect = get_node_or_null("HPBarContainer/HPBackground")

var hp := 0
var slow_multiplier := 1.0
var slow_timer := 0.0

# Throttle anti-surcharge : une seule onomatopée à la fois sur cet ennemi.
var _onomatopoeia_cooldown := 0.0
const ONOMATOPOEIA_COOLDOWN := 1
var status_effects: Dictionary = {}

var _knockback_cooldown := 0.0
const KNOCKBACK_COOLDOWN := 3.0   # secondes entre deux knockbacks

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
func take_damage(amount: int, kind: String = "normal"):

	hp -= amount

	if hp < 0:
		hp = 0

	update_hp_bar()

	if kind != "silent" and amount > 0:
		_spawn_damage_number(amount, kind)

	if hp <= 0:
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

func _process(delta):

	update_statuses(delta)

	if _knockback_cooldown > 0.0:
		_knockback_cooldown -= delta

	if _onomatopoeia_cooldown > 0.0:
		_onomatopoeia_cooldown -= delta

	# Flaque Toxique : WET inflige des dégâts si le bonus est actif
	if has_status(StatusIds.WET):
		var wet_dmg := RunBonuses.get_wet_tick_damage()
		if wet_dmg > 0:
			_wet_tick_timer -= delta
			if _wet_tick_timer <= 0.0:
				_wet_tick_timer = WET_TICK_INTERVAL
				take_damage(wet_dmg, "tick")

	# BURNING : dégâts sur la durée (toujours actifs, pas besoin de bonus)
	if has_status(StatusIds.BURNING):
		_burn_tick_timer -= delta
		if _burn_tick_timer <= 0.0:
			_burn_tick_timer = BURN_TICK_INTERVAL
			take_damage(BURN_TICK_DAMAGE, "tick")

	if slow_timer > 0:

		slow_timer -= delta

		if slow_timer <= 0:

			slow_multiplier = 1.0

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

	# BOOM ! = mort d'un ennemi.
	var effects_root := get_tree().current_scene.get_node_or_null("World/EffectsContainer")
	if effects_root:
		OnomatopoeiaPop.spawn(effects_root, global_position, "boom", 170.0 * death_boom_scale)

	if scrap_reward > 0:
		Player.add_ferraille(scrap_reward)

	if enemy_manager:
		enemy_manager.unregister_enemy(self)

	# Libérer aussi le PathFollow2D parent pour qu'il ne continue pas jusqu'à la fin
	var pf := get_parent()
	if pf is PathFollow2D:
		pf.queue_free()
	else:
		queue_free()
