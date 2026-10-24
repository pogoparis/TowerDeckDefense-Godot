extends Node2D
class_name BaseTower

## Tourelle — la partie rotative. Cherche "Turret" (nouveau) ou "Sprite2D" (ancien).
@onready var sprite: Sprite2D = get_node_or_null("Turret") if has_node("Turret") else get_node_or_null("Sprite2D")
## Socle — sprite statique en dessous, ne tourne jamais (optionnel).
@onready var base_sprite: Sprite2D = get_node_or_null("Base")

enum TowerFamily {
	IRONCLAD,
	SPARK,
	GHOST
}

# ==============================
#          STATS BASE
# ==============================

@export var base_damage: int = 10
@export var base_fire_rate: float = 0.8
@export var base_range: float = 120.0
@export var family: TowerFamily
@export var tower_tags: Array[String] = []
@export var element_type: ElementType.Type = ElementType.Type.NONE
@export var phenomenon_radius := 64.0

@export_group("Amélioration")
## Nombre max d'améliorations achetables. 2 = trois paliers au total
## (Niv.1 de base → Niv.2 → Niv.3), comme le GDD.
@export var max_upgrade_level := 2
## Coût en CAPS de chaque palier (index 0 = passage au Niv.2).
##
## ⚠ MÊME MONNAIE QUE LES TOURS — c'est tout l'intérêt. Tant que les
## améliorations se payaient en Ferraille, elles ne se disputaient rien avec la
## pose : on achetait les deux dès qu'on pouvait. Avec une monnaie unique,
## chaque fin de vague repose la question centrale de BTD6 : « une tour de
## plus, ou une tour meilleure ? »
##
## Calibrage : une partie rapporte ~1060 Caps. Poser ~10 tours et lancer ~8
## sorts en consomme ~500. Il en reste ~560, soit environ 5 tours maxées à
## 115 Caps — sur une dizaine posées. Le joueur doit donc CHOISIR lesquelles.
@export var upgrade_costs: Array[int] = [35, 80]
## Multiplicateur de dégâts par palier. Combiné à la cadence, ça donne
## environ ×1.8 de DPS par niveau — la montée en puissance "machine" de BTD6.
@export var upgrade_damage_mult := 1.6
## Multiplicateur de cadence par palier (< 1.0 = tire plus vite).
@export var upgrade_fire_rate_mult := 0.88
## Multiplicateur de portée par palier.
@export var upgrade_range_mult := 1.12

## Niveau d'amélioration acheté (0 = tour de base).
var upgrade_level := 0
var _initial_scale := Vector2.ONE
var _upgrade_badge: Label

@export_group("Synergie phénomène")
## Multiplicateur de dégâts quand la tour est dans un phénomène actif.
@export var phenomenon_damage_mult := 1.5
## Multiplicateur de cadence dans un phénomène (< 1.0 = tire plus vite).
@export var phenomenon_fire_rate_mult := 0.6
## Vrai tant que la tour est dans la zone d'un phénomène actif.
var phenomenon_buffed := false

@export_group("Halo de Lumière")
## Multiplicateur de dégâts quand la tour est dans le halo d'une Luciole.
@export var light_damage_mult := 1.25
## Multiplicateur de cadence dans un halo (< 1.0 = tire plus vite).
@export var light_fire_rate_mult := 0.8
## Vrai tant que la tour est éclairée par le halo d'une tour Lumière.
var light_buffed := false

@export_group("Charge (tour signature)")
## Cette tour porte une jauge de Charge (tour signature). Sinon : pas de jauge.
@export var is_signature := false
## AUTOMATIQUE : la Charge part toute seule dès la jauge pleine, sans bouton.
##
## Deux langages de tour pour un seul mécanisme :
##   • auto = false → SIGNATURE. Jauge dorée, bouton DÉCLENCHER, effet
##     spectaculaire, comptée dans le plafond de 3 sur le terrain.
##   • auto = true  → RYTHME. Jauge discrète, effet plus modeste mais régulier,
##     zéro charge cognitive, PAS comptée dans le plafond.
##
## Sans cette distinction, chaque nouvelle tour à jauge criait aussi fort que
## les autres : à cinq jauges à l'écran, "DÉCLENCHER" devient du clic de
## routine et l'attention du joueur ne vaut plus rien. En réservant le bouton à
## trois tours, on lui rend son statut d'évènement.
@export var charge_auto := false
## Barres de Charge max au niveau 1 (chaque amélioration ajoute +1 barre).
@export var charge_max_base := 5
## Hauteur (px écran) de la jauge au-dessus de la tour (compensée du scale).
@export var charge_bar_offset_y := -115.0

## Cooldown après déclenchement. 15 s pour une signature : son effet est
## spectaculaire, il doit rester rare. Une tour AUTOMATIQUE veut au contraire un
## cooldown court (1-3 s) — c'est le nombre de tirs qui doit cadencer son
## rythme, pas une attente qui la rendrait muette la moitié du temps.
@export var charge_cooldown_time := 15.0
## Barres accumulées (0 → charge_max()).
var charge_current := 0
## Temps de cooldown restant (0 = prête à se recharger).
var charge_cooldown := 0.0
## Verrou : si faux, pas de jauge, pas d'accumulation, pas de déclenchement.
## (Utilisé par le tuto pour n'activer la Charge qu'à la bonne vague.)
var charge_enabled := true

@export_group("Orientation visuelle")
## Rotation max vers la cible (°). 0 = désactivé. Ignoré si directional_textures est rempli.
@export_range(0.0, 90.0, 1.0) var max_aim_degrees: float = 45.0
## Angle de base du sprite (mode rotation 2D uniquement).
@export_range(-180.0, 180.0, 1.0) var sprite_base_angle_deg: float = 0.0

@export_group("Sprites directionnels 3D")
## 8 textures rendues depuis Blender. Si rempli, remplace la rotation 2D.
## Ordre : ennemi à droite, bas-droite, bas, bas-gauche, gauche, haut-gauche, haut, haut-droite.
## Pour Water Cannon : W, SW, S, SE, E, NE, N, NW
@export var directional_textures: Array[Texture2D] = []
## Décalage en secteurs (0-7) si les sprites sont mal alignés. Augmenter de 1 jusqu'à ce que ce soit bon.
@export_range(0, 7, 1) var direction_offset: int = 0

## Hauteur d'affichage cible du sprite en pixels (0 = garder le scale de la scène).
## Calcule automatiquement le scale selon la taille du PNG → toutes les tours
## peuvent avoir des images de tailles différentes et s'afficher à la même taille.
@export var display_height: float = 0.0

## Ancrage vertical dans la case (voir _anchor_feet).
## FOOT_RATIO : distance centre-du-PNG → pieds, en fraction de la hauteur du
## PNG. 0.455 sur le canevas normalisé du projet (572×500, pieds à y≈478) —
## mesuré sur les 9 tours, elles sont toutes entre 0.448 et 0.460.
const FOOT_RATIO := 0.455
## Pieds à 34 px sous le centre d'une case de 96 : la tour REMPLIT sa case au
## lieu de flotter dans sa moitié haute, sans déborder sur la case du dessous.
const FOOT_IN_CELL := 34.0

@export_group("Sprites 4 directions (personnage)")
## Si les 4 sont remplies, la tour regarde l'ennemi via 4 sprites (E/S/O/N),
## avec un switch stabilisé (pas de tremblement quand une cible meurt).
@export var tex_east: Texture2D
@export var tex_south: Texture2D
@export var tex_west: Texture2D
@export var tex_north: Texture2D

## Animation jouée UNIQUEMENT quand la tour regarde le Sud (repos).
## Vide = sprite Sud statique. (ex : la chouette qui bat des ailes)
@export var south_anim_frames: Array[Texture2D] = []
@export var south_anim_fps := 6.0
var _anim_time := 0.0

# Direction affichée : 0=Est, 1=Sud, 2=Ouest, 3=Nord. Défaut Sud (face caméra).
var _facing_dir := 1
var _pending_dir := 1
var _pending_time := 0.0
## Temps de stabilité requis avant de changer de direction (anti-jitter).
const FACING_DEBOUNCE := 0.18

@export_group("Tour personnage (2 frames)")
## Image au repos (visée). Si remplie, active le mode personnage : flip gauche/droite + flash de tir.
@export var idle_texture: Texture2D
## Image de tir (flashée brièvement à chaque tir).
@export var fire_texture: Texture2D
## Durée d'affichage de la frame de tir (secondes).
@export var fire_frame_duration := 0.12
## Le sprite regarde la droite par défaut ? (false = il regarde la gauche)
@export var faces_right_by_default := true
## Anticipation d'orientation : la tour se tourne vers l'ennemi dès qu'il entre
## dans (portée × ce facteur), AVANT d'être à portée de tir. 1.0 = pas d'anticipation.
@export var facing_anticipation := 1.5
## Au repos, la tour regarde automatiquement vers l'ENTRÉE du chemin (d'où
## viennent les ennemis) → s'adapte au niveau. Si false, utilise rest_faces_left.
@export var rest_faces_spawn := true
## Direction de repos manuelle (utilisée seulement si rest_faces_spawn = false).
@export var rest_faces_left := true

# ==============================
#        STATS ACTUELLES
# ==============================
var is_ghost := false
var damage: int
var fire_rate: float
var attack_range: float
var enemy_manager: EnemyManager
var grid_cell: Vector2i
var tower_manager
var adjacency_damage_mult := 1.0
var adjacency_range_mult := 1.0
var status_effects: Dictionary = {}
var buff_visual_active := false
var was_buffed := false

# ==============================
#            NODES
# ==============================
@onready var halo_sprite: Sprite2D = get_node_or_null("HaloSprite")
@onready var timer: Timer = get_node_or_null("Timer")
@onready var sprite_material := sprite.material if sprite else null

# ==============================
#            READY
# ==============================

func _ready():

	damage = base_damage
	fire_rate = base_fire_rate
	attack_range = base_range

	_initial_scale = scale

	add_to_group("towers")

	apply_run_bonuses()

	if sprite and sprite.material:

		sprite.material = sprite.material.duplicate()

		sprite_material = sprite.material

	if sprite_material:

		sprite_material.set_shader_parameter(
			"outline_size",
			0.0
		)

	if timer:
		timer.wait_time = fire_rate

	# Mode 4 directions : sprite Sud par défaut (face caméra).
	if sprite and _has_4dir():
		sprite.texture = tex_south
		_facing_dir = 1

	# Mode personnage : image au repos + orientation de repos (vers l'entrée).
	elif sprite and idle_texture:
		sprite.texture = idle_texture
		_cache_spawn_x()
		_face_rest()

	# Normalise la taille à l'écran quelle que soit la taille du PNG source.
	_apply_display_height()


func _process(delta: float) -> void:
	if is_ghost or enemy_manager == null:
		return

	_tick_temp_buff(delta)

	# Charge : décompte du cooldown + pulsation visuelle quand prête.
	if is_signature:
		if charge_cooldown > 0.0:
			charge_cooldown = max(0.0, charge_cooldown - delta)
			if charge_cooldown == 0.0:
				queue_redraw()
		elif is_charge_ready():
			queue_redraw()

	# Mode 4 directions (E/S/O/N) avec stabilisation.
	if _has_4dir():
		_update_4dir_facing(delta)
		_update_south_anim(delta)
		return

	# Mode personnage 2 frames : oriente vers l'ennemi qui approche, sinon repos.
	if idle_texture == null:
		return
	var anticipated := _find_facing_target()
	if anticipated:
		_face_character(anticipated.global_position)
	else:
		_face_rest()


## Ennemi le plus avancé dans la portée élargie (anticipation d'orientation).
func _find_facing_target() -> Node2D:
	var look_range := attack_range * facing_anticipation
	var best: Node2D = null
	var best_progress := -1.0
	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > look_range:
			continue
		var pf := enemy.get_parent() as PathFollow2D
		var progress: float = pf.progress if pf != null else 0.0
		if progress > best_progress:
			best_progress = progress
			best = enemy
	return best


# ==============================
#       APPLY UPGRADE
# ==============================
func apply_upgrade(data: Dictionary):
	damage += data.get("damage", 0)
	attack_range += data.get("range", 0)

	var fire_mult: float = data.get("fire_rate_mult", 1.0)
	fire_rate *= fire_mult

	if timer:
		timer.wait_time = fire_rate
		timer.stop()
		timer.start()
		update_visual_feedback()

# ==============================
#     AMELIORATION JOUEUR
# ==============================

func can_upgrade() -> bool:
	return upgrade_level < max_upgrade_level

## Coût du PROCHAIN palier, en Caps.
func upgrade_price() -> int:
	if upgrade_costs.is_empty():
		return 999
	if upgrade_level < upgrade_costs.size():
		return upgrade_costs[upgrade_level]
	return upgrade_costs[upgrade_costs.size() - 1]

## Tente d'acheter une amélioration. Retourne true si réussi.
func try_upgrade() -> bool:
	if not can_upgrade():
		return false
	if not Player.spend_caps(upgrade_price()):
		return false

	upgrade_level += 1
	recalculate_stats()
	if timer:
		timer.wait_time = fire_rate

	_play_upgrade_feedback()
	return true


func _play_upgrade_feedback() -> void:
	# Son
	Audio.play_sfx(preload("res://assets/audio/sfx/UpgradeTower.wav"), 0.0)

	# Taille persistante + punch
	var target_scale := _initial_scale * (1.0 + 0.1 * upgrade_level)
	scale = target_scale * 1.25
	var t := create_tween()
	t.tween_property(self, "scale", target_scale, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Flash de contour
	if sprite_material:
		sprite_material.set_shader_parameter("outline_size", 4.0)
		var flash := get_tree().create_timer(0.3)
		flash.timeout.connect(func() -> void:
			if sprite_material and not buff_visual_active:
				sprite_material.set_shader_parameter("outline_size", 0.0)
		)

	_update_upgrade_badge()


## Affiche les étoiles de niveau au-dessus de la tour (★ par niveau).
func _update_upgrade_badge() -> void:
	if upgrade_level <= 0:
		return
	if _upgrade_badge == null:
		_upgrade_badge = Label.new()
		_upgrade_badge.add_theme_font_size_override("font_size", 44)
		_upgrade_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		_upgrade_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_upgrade_badge.add_theme_constant_override("outline_size", 6)
		_upgrade_badge.z_index = 50
		add_child(_upgrade_badge)
	_upgrade_badge.text = "★".repeat(upgrade_level)
	# Compense le scale racine de la tour (ex : Ours Éclair à 0.65) pour que
	# l'étoile ait la MÊME taille et la MÊME hauteur à l'écran sur toutes les tours.
	var sx: float = scale.x if scale.x != 0.0 else 1.0
	var sy: float = scale.y if scale.y != 0.0 else 1.0
	_upgrade_badge.scale = Vector2(1.0 / sx, 1.0 / sy)
	if is_signature:
		# À GAUCHE de la jauge, au même niveau (mêmes unités écran que _draw).
		var cmax := charge_max()
		var gauge_half := (cmax * 13.0 + (cmax - 1) * 3.0) * 0.5
		var star_x := -gauge_half - 18.0 - 22.0 * upgrade_level
		_upgrade_badge.position = Vector2(star_x / sx, (charge_bar_offset_y - 14.0) / sy)
	else:
		# Tour sans jauge : au-dessus de la tête.
		_upgrade_badge.position = Vector2(-16 * upgrade_level / sx, -140.0 / sy)


# ==============================
#   SYNERGIE PHENOMENE
# ==============================

## Active/désactive le boost de la tour selon qu'elle est dans un phénomène.
## Ne recalcule que sur changement d'état (appelé chaque frame par le manager).
func set_phenomenon_buff(active: bool) -> void:
	if active == phenomenon_buffed:
		return
	phenomenon_buffed = active
	recalculate_stats()
	if timer:
		timer.wait_time = fire_rate
	set_buff_visual(active)


## Active/désactive le halo de Lumière sur cette tour (piloté par les Lucioles).
## Ne recalcule que sur changement d'état.
func set_light_buff(active: bool) -> void:
	if active == light_buffed:
		return
	light_buffed = active
	recalculate_stats()
	if timer:
		timer.wait_time = fire_rate
	# Le contour reste allumé si un phénomène la booste aussi.
	set_buff_visual(active or phenomenon_buffed)


func get_outline_size() -> float:
	return 4.0

func set_buff_visual(active: bool):

	buff_visual_active = active

	if sprite_material == null:
		return

	if active:
		sprite_material.set_shader_parameter(
			"outline_size",
			4
		)
	else:
		sprite_material.set_shader_parameter(
			"outline_size",
			0.0
		)

# ==============================
#            CHARGE
# ==============================

## Barres max selon le niveau d'amélioration (5 → 6 → 7…).
func charge_max() -> int:
	# Le bonus de carte ★ RETIRE des barres : la Charge part plus vite.
	# Plancher à 2, sinon une carte doublement améliorée déclencherait en boucle.
	return maxi(2, charge_max_base + upgrade_level - card_charge_bonus)


## Vrai quand la Charge est pleine, hors cooldown (déclenchable).
func is_charge_ready() -> bool:
	return is_signature and charge_enabled and charge_cooldown <= 0.0 and charge_current >= charge_max()


## +[param amount] barres, si tour signature et hors cooldown. Ignoré sinon.
func add_charge(amount: int) -> void:
	if not is_signature or not charge_enabled or charge_cooldown > 0.0:
		return
	var before := charge_current
	charge_current = mini(charge_max(), charge_current + amount)
	if charge_current != before:
		queue_redraw()

	# Mode automatique : elle se déclenche elle-même dès qu'elle est pleine.
	if charge_auto and is_charge_ready():
		trigger_charge()


## Déclenche l'effet de Charge si prête : vide la jauge + lance le cooldown.
func trigger_charge() -> bool:
	if not is_charge_ready():
		return false
	charge_current = 0
	charge_cooldown = charge_cooldown_time
	_charge_effect()
	queue_redraw()
	return true


## Effet de Charge — surchargé par chaque tour signature.
func _charge_effect() -> void:
	pass


## Récupère le PhenomenonManager de la scène (service de zones), ou null.
func get_phenomenon_manager() -> PhenomenonManager:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("PhenomenonManager") as PhenomenonManager


## Jauge de Charge dessinée au-dessus des tours signatures.
func _draw() -> void:
	if is_ghost or not is_signature or not charge_enabled:
		return
	var cmax := charge_max()
	if cmax <= 0:
		return

	# Compense le scale racine de la tour (ex : Ours Éclair 0.65) → jauge de
	# taille et hauteur CONSTANTES à l'écran, alignée avec l'étoile compensée.
	var s: float = scale.y if scale.y != 0.0 else 1.0
	var inv := 1.0 / s

	# La jauge AUTOMATIQUE est délibérément plus petite et plus terne : elle
	# informe d'un rythme, elle ne réclame pas d'action. Une jauge automatique
	# aussi voyante qu'une signature entraînerait le joueur à cliquer dessus
	# pour rien — et diluerait le signal des vraies Charges.
	var mini_gauge := charge_auto
	var seg_w := (8.0 if mini_gauge else 13.0) * inv
	var seg_h := (5.0 if mini_gauge else 9.0) * inv
	var gap := (2.0 if mini_gauge else 3.0) * inv
	var total_w := cmax * seg_w + (cmax - 1) * gap
	var start_x := -total_w * 0.5
	var y := charge_bar_offset_y * inv   # charge_bar_offset_y est en px écran
	var on_cd := charge_cooldown > 0.0
	var charge_ready := is_charge_ready()

	for i in cmax:
		var x := start_x + i * (seg_w + gap)
		var rect := Rect2(x, y, seg_w, seg_h)
		var filled := i < charge_current
		var col: Color
		if on_cd:
			col = Color(0.30, 0.30, 0.35, 0.6)
		elif filled:
			if mini_gauge:
				col = Color(0.55, 0.85, 0.65, 0.85)   # vert sourd : ça travaille
			else:
				col = Color(1.0, 0.95, 0.3) if charge_ready else Color(0.4, 0.8, 1.0)
		else:
			col = Color(0.15, 0.2, 0.3, 0.5 if mini_gauge else 0.7)
		draw_rect(rect, col, true)
		draw_rect(rect, Color(0, 0, 0, 0.6), false, 1.0)

	# Halo pulsant quand la Charge est prête à être déclenchée. Jamais en mode
	# automatique : il n'y a rien à déclencher, l'appel à l'action serait faux.
	if charge_ready and not mini_gauge:
		var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		var pad := 3.0 * inv
		draw_rect(Rect2(start_x - pad, y - pad, total_w + pad * 2.0, seg_h + pad * 2.0),
			Color(1.0, 0.9, 0.2, 0.45 * glow), false, 2.0)


# ══════════════════════════════════════════════════════
#                  PRIORITÉ DE CIBLAGE
# ══════════════════════════════════════════════════════
#
# Le ciblage prenait le PREMIER ennemi trouvé dans la liste — c'est-à-dire un
# ennemi arbitraire. Deux problèmes : les tours visaient n'importe quoi, et le
# joueur n'avait aucune prise dessus une fois la vague lancée.
#
# C'est le système le plus rentable de BTD6 : quelques lignes d'interface, une
# profondeur sans fond, et il récompense la CONNAISSANCE du jeu. Savoir qu'un
# Gardien doit viser le plus costaud et une Chouette le plus avancé, c'est de
# l'expertise que le joueur acquiert en jouant.

enum Targeting { SPECIAL, FIRST, LAST, CLOSEST, STRONGEST }

## Mode de ciblage. SPECIAL = la logique propre à la tour (le Gardien vise le
## plus résistant, le Vampire ce qui n'est pas encore marqué…). Les tours qui
## n'en ont pas retombent sur FIRST, le mode par défaut du genre.
var targeting_mode: Targeting = Targeting.SPECIAL

const TARGETING_LABELS := {
	Targeting.SPECIAL: "SPÉCIAL",
	Targeting.FIRST: "PREMIER",
	Targeting.LAST: "DERNIER",
	Targeting.CLOSEST: "PROCHE",
	Targeting.STRONGEST: "COSTAUD",
}


func cycle_targeting() -> void:
	targeting_mode = ((targeting_mode + 1) % Targeting.size()) as Targeting


func targeting_label() -> String:
	return TARGETING_LABELS.get(targeting_mode, "?")


func find_target() -> Node2D:
	if not enemy_manager:
		return null

	if targeting_mode == Targeting.SPECIAL:
		var special := _find_target_special()
		if special:
			return special
		# Aucune cible « spéciale » : on ne reste pas muet, on tire sur le plus
		# avancé — sinon une tour pourrait ne jamais tirer faute de cible idéale.
		return _find_by(Targeting.FIRST)

	return _find_by(targeting_mode)


## Logique de ciblage propre à la tour. Surchargée par les tours qui en ont une
## (Gardien, Vampire, Panda…). Par défaut : aucune, on retombe sur FIRST.
func _find_target_special() -> Node2D:
	return null


## Meilleure cible à portée selon un mode. Un seul parcours, un seul score —
## ajouter un mode revient à ajouter une ligne.
func _find_by(mode: Targeting) -> Node2D:
	var best: Node2D = null
	var best_score := -INF

	for enemy in enemy_manager.get_all_enemies():
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist > attack_range:
			continue

		var score := 0.0
		match mode:
			Targeting.FIRST:
				score = _path_progress(enemy)          # le plus avancé
			Targeting.LAST:
				score = -_path_progress(enemy)         # le moins avancé
			Targeting.CLOSEST:
				score = -dist
			Targeting.STRONGEST:
				score = float(enemy.hp) if enemy is EnemyBase else 0.0
			_:
				score = _path_progress(enemy)

		if score > best_score:
			best_score = score
			best = enemy

	return best


## Distance parcourue sur le chemin — c'est elle qui dit « le plus avancé »,
## et non la distance à la base, qui serait fausse sur un chemin en zigzag.
func _path_progress(enemy: Node2D) -> float:
	var pf := enemy.get_parent() as PathFollow2D
	return pf.progress if pf != null else 0.0


# ==============================
#          SELECTION
# ==============================

var is_selected := false

func set_selected(value: bool):

	is_selected = value
	queue_redraw()


func find_target_with_status(status_id: String) -> Node2D:

	if not enemy_manager:
		return null

	for enemy in enemy_manager.get_all_enemies():

		if not is_instance_valid(enemy):
			continue

		if not enemy.has_status(status_id):
			continue

		var dist = global_position.distance_to(enemy.global_position)

		if dist <= attack_range:
			return enemy

	return null

# ==============================
#        VISUAL FEEDBACK
# ==============================

func update_visual_feedback():
	pass

func disable_behaviors():

	if timer:
		timer.stop()

# ── Dopage temporaire (sorts) ─────────────────────────
var _temp_damage_mult := 1.0
var _temp_fire_rate_mult := 1.0
var _temp_buff_timer := 0.0


## Dope la tour pendant [param duration]. Un second lancement REMPLACE le
## précédent au lieu de s'y ajouter : deux Overdrive empilés donneraient une
## tour hors de contrôle, et le joueur ne saurait plus ce qui est actif.
func apply_temp_buff(damage_mult: float, fire_rate_mult: float, duration: float) -> void:
	_temp_damage_mult = damage_mult
	_temp_fire_rate_mult = fire_rate_mult
	_temp_buff_timer = maxf(_temp_buff_timer, duration)
	recalculate_stats()
	if timer:
		timer.wait_time = fire_rate
	set_buff_visual(true)


func _tick_temp_buff(delta: float) -> void:
	if _temp_buff_timer <= 0.0:
		return
	_temp_buff_timer -= delta
	if _temp_buff_timer <= 0.0:
		_temp_buff_timer = 0.0
		_temp_damage_mult = 1.0
		_temp_fire_rate_mult = 1.0
		recalculate_stats()
		if timer:
			timer.wait_time = fire_rate
		# Le contour reste allumé si un phénomène ou un halo la booste aussi.
		set_buff_visual(phenomenon_buffed or light_buffed)


# ── Carte ★ ───────────────────────────────────────────
## Bonus permanents apportés par une carte améliorée. Stockés sur la tour et
## réappliqués à chaque recalcul (améliorations, halos, synergies), sinon le
## premier recalcul les effacerait.
var card_damage_mult := 1.0
var card_fire_rate_mult := 1.0
var card_range_mult := 1.0
var card_charge_bonus := 0


func apply_card_upgrade(dmg: float, rate: float, rng: float, charge: int) -> void:
	card_damage_mult = dmg
	card_fire_rate_mult = rate
	card_range_mult = rng
	card_charge_bonus = charge
	recalculate_stats()
	if timer:
		timer.wait_time = fire_rate
	_raise_upgrade_prices()
	_show_star_badge()


## Une tour ★ arrive déjà renforcée : ses améliorations payantes coûtent plus
## cher, mais elle garde ses DEUX paliers.
##
## L'alternative — la faire démarrer au niveau 1 — donnait bien un prix de 80,
## mais lui retirait un palier : la carte ★ aurait échangé une amélioration
## contre ses bonus au lieu de s'y ajouter, ce qui en fait une récompense
## presque neutre alors que c'est la plus rare de l'offre.
##
## Le facteur suit le gain réel de la carte (+35 % de dégâts) arrondi au
## multiple de 5, pour que les prix restent des nombres ronds et lisibles.
const STAR_PRICE_MULT := 2.3

func _raise_upgrade_prices() -> void:
	var raised: Array[int] = []
	for price in upgrade_costs:
		raised.append(int(round(price * STAR_PRICE_MULT / 5.0)) * 5)
	upgrade_costs = raised


## Badge ★ permanent sur une tour posée depuis une carte améliorée.
##
## ── POURQUOI PAS LE CONTOUR DE BUFF ──────────────────────────────────────
## Le marqueur était `set_buff_visual(true)`, c'est-à-dire le MÊME contour que
## le dopage temporaire d'un sort. Deux problèmes, et le second est fatal :
##   • un contour ne dit pas « améliorée », il dit « il se passe quelque
##     chose » — indiscernable d'une Luciole qui éclaire la tour ;
##   • surtout, il était effacé aussitôt : synergy_manager appelle
##     set_buff_visual(false) à chaque recalcul, et recalculate_stats() le
##     remet sur `phenomenon_buffed or light_buffed`. La marque disparaissait
##     donc dans la seconde qui suivait la pose.
##
## Un nœud dédié ne peut être effacé par aucun de ces recalculs.
func _show_star_badge() -> void:
	if has_node("StarBadge"):
		return

	var badge := Label.new()
	badge.name = "StarBadge"
	badge.text = "★"
	badge.z_index = 12
	badge.add_theme_font_size_override("font_size", 26)
	badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	# Contour sombre : l'étoile doit rester lisible sur un sprite clair comme
	# sur le décor, sans halo qui la ferait passer pour un effet en cours.
	badge.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02))
	badge.add_theme_constant_override("outline_size", 6)
	# Posée en haut à droite de la tour, hors de la silhouette et sous la
	# jauge de Charge, qui occupe le centre.
	badge.position = Vector2(20, -display_height - 6)
	add_child(badge)


func apply_run_bonuses():

	damage = base_damage
	attack_range = base_range
	fire_rate = base_fire_rate

	# Améliorations achetées par le joueur — réappliquées ici pour persister
	# à travers chaque recalcul (synergies, adjacence…).
	# Multiplicatif : chaque palier vaut ~×1.8 de DPS (montée BTD6).
	for _i in upgrade_level:
		damage = int(round(damage * upgrade_damage_mult))
		fire_rate *= upgrade_fire_rate_mult
		attack_range *= upgrade_range_mult

	for bonus in RunBonuses.owned_bonuses:
		damage += bonus.damage_bonus
		attack_range += bonus.range_bonus
		fire_rate *= bonus.fire_rate_mult

	# Synergie : suralimentée tant qu'elle est dans un phénomène actif.
	if phenomenon_buffed:
		damage = int(damage * phenomenon_damage_mult)
		fire_rate *= phenomenon_fire_rate_mult

	# Halo de Lumière : renforcée tant qu'une Luciole l'éclaire.
	if light_buffed:
		damage = int(damage * light_damage_mult)
		fire_rate *= light_fire_rate_mult

	# Carte ★ : bonus permanent de la carte améliorée. Avant le dopage
	# temporaire, donc les deux se composent.
	if card_damage_mult != 1.0 or card_fire_rate_mult != 1.0 or card_range_mult != 1.0:
		damage = int(round(damage * card_damage_mult))
		fire_rate *= card_fire_rate_mult
		attack_range *= card_range_mult

	# Dopage temporaire (sort Overdrive). En dernier, donc il multiplie tout le
	# reste — c'est ce qui en fait un sort de FINITION : on le lance sur un
	# groupe déjà buffé, pas au hasard.
	if _temp_buff_timer > 0.0:
		damage = int(damage * _temp_damage_mult)
		fire_rate *= _temp_fire_rate_mult

	if timer:
		timer.wait_time = fire_rate

func add_status(status_id: String):
	status_effects[status_id] = true

func remove_status(status_id: String):
	status_effects.erase(status_id)

func has_status(status_id: String) -> bool:
	return status_effects.has(status_id)

func recalculate_stats():

	apply_run_bonuses()

	damage = int(damage * adjacency_damage_mult)
	attack_range = attack_range * adjacency_range_mult


# ==============================
#     ORIENTATION VISUELLE
# ==============================

# ==============================
#     FACING 4 DIRECTIONS
# ==============================

func _has_4dir() -> bool:
	return tex_east != null and tex_south != null and tex_west != null and tex_north != null


## Secteur (0=E, 1=S, 2=O, 3=N) à partir d'un angle en degrés
## (0 = droite, 90 = bas/sud car Y pointe vers le bas en 2D).
func _sector_from_angle(a: float) -> int:
	if a >= -45.0 and a < 45.0:
		return 0   # Est
	if a >= 45.0 and a < 135.0:
		return 1   # Sud
	if a >= -135.0 and a < -45.0:
		return 3   # Nord
	return 2       # Ouest


## Met à jour la direction affichée vers la cible, avec debounce anti-jitter :
## le changement n'est validé que si la nouvelle direction reste désirée
## pendant FACING_DEBOUNCE. Sans cible, on garde la dernière direction.
func _update_4dir_facing(delta: float) -> void:
	var target := _find_facing_target()
	if target == null:
		_pending_time = 0.0
		return   # pas de cible → on garde la direction courante (pas de snap)

	var ang := rad_to_deg((target.global_position - global_position).angle())
	var desired := _sector_from_angle(ang)

	if desired == _facing_dir:
		_pending_time = 0.0
		return

	# La direction voulue doit être stable un court instant avant de basculer.
	if desired == _pending_dir:
		_pending_time += delta
	else:
		_pending_dir = desired
		_pending_time = 0.0

	if _pending_time >= FACING_DEBOUNCE:
		_set_facing_dir(desired)
		_pending_time = 0.0


## Anime la face Sud (bat d'ailes…) seulement quand la tour regarde le Sud.
func _update_south_anim(delta: float) -> void:
	if south_anim_frames.is_empty() or _facing_dir != 1 or sprite == null:
		return
	_anim_time += delta
	var frame := int(_anim_time * south_anim_fps) % south_anim_frames.size()
	var tex: Texture2D = south_anim_frames[frame]
	if sprite.texture != tex:
		sprite.texture = tex
		_apply_display_height()


func _set_facing_dir(dir: int) -> void:
	if sprite == null:
		return
	_facing_dir = dir
	match dir:
		0: sprite.texture = tex_east
		1: sprite.texture = tex_south
		2: sprite.texture = tex_west
		3: sprite.texture = tex_north
	# Re-normalise la taille (gère des sprites de hauteurs différentes par direction).
	_apply_display_height()


## Ajuste le scale du sprite pour atteindre display_height à l'écran,
## quelle que soit la taille du PNG courant. 0 = on garde le scale de la scène.
func _apply_display_height() -> void:
	if sprite == null or sprite.texture == null or display_height <= 0.0:
		return
	var tex_h := float(sprite.texture.get_height())
	var root_y: float = scale.y if scale.y != 0.0 else 1.0
	if tex_h > 0.0:
		var s: float = display_height / (tex_h * root_y)
		sprite.scale = Vector2(s, s)
		_anchor_feet(root_y)


## Place le sprite pour que les PIEDS tombent à FOOT_IN_CELL px sous le centre
## de la case, quelle que soit display_height.
##
## Cet offset était écrit en dur dans chaque .tscn (position.y = -44), calibré
## pour display_height = 150. Quand la grille est passée en cases de 96 px et
## display_height à 112, les pieds ont silencieusement remonté de 18 px et
## toutes les tours se sont mises à flotter en haut de leur case. Le calculer
## ici garantit que ça ne peut plus se désynchroniser à la prochaine retouche.
func _anchor_feet(root_y: float) -> void:
	if sprite == null:
		return
	# Position locale : divisée par le scale racine (l'Ours Éclair est à 0.65),
	# pour que le résultat soit le même en pixels ÉCRAN sur toutes les tours.
	sprite.position.y = (FOOT_IN_CELL - FOOT_RATIO * display_height) / root_y


## Point d'entrée principal : choisit le mode (4 dirs / 3D sprites / 2 frames / rotation 2D).
func face_target(target_global_pos: Vector2) -> void:
	if _has_4dir():
		return  # facing géré en continu dans _process
	if directional_textures.size() == 8:
		_face_3d(target_global_pos)
	elif idle_texture != null and fire_texture != null:
		pass  # orientation gérée en continu dans _process (anticipation) — pas de flip au tir
	elif sprite != null and max_aim_degrees > 0.0:
		_face_2d(target_global_pos)


## Mode personnage — pas de rotation, juste un flip gauche/droite vers la cible.
func _face_character(target_global_pos: Vector2) -> void:
	_set_facing(target_global_pos.x < global_position.x)


## Oriente le sprite : [param want_left] = doit regarder à gauche.
func _set_facing(want_left: bool) -> void:
	if sprite == null:
		return
	# Image dessinée vers la droite → flip_h pour regarder à gauche.
	sprite.flip_h = want_left if faces_right_by_default else not want_left


# Position X de l'entrée du chemin (d'où viennent les ennemis), pour le repos.
var _spawn_world_x := 0.0
var _has_spawn := false

func _cache_spawn_x() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var path := scene.get_node_or_null("World/Path2D") as Path2D
	if path and path.curve and path.curve.point_count > 0:
		_spawn_world_x = path.to_global(path.curve.get_point_position(0)).x
		_has_spawn = true


## Orientation de repos : vers l'entrée du chemin (auto) ou direction manuelle.
func _face_rest() -> void:
	if rest_faces_spawn and _has_spawn:
		_set_facing(_spawn_world_x < global_position.x)
	else:
		_set_facing(rest_faces_left)


## Flash de la frame de tir, puis retour à l'image au repos.
func play_fire_frame() -> void:
	if sprite == null or fire_texture == null or idle_texture == null:
		return
	sprite.texture = fire_texture
	var t := get_tree().create_timer(fire_frame_duration)
	t.timeout.connect(func() -> void:
		if is_instance_valid(sprite):
			sprite.texture = idle_texture
	)


## Mode 3D — swape la texture selon l'angle vers la cible (8 secteurs de 45°).
func _face_3d(target_global_pos: Vector2) -> void:
	if sprite == null:
		return
	var dir := (target_global_pos - global_position).normalized()
	# Angle normalisé [0, 2PI], 0 = droite, PI/2 = bas, PI = gauche, 3PI/2 = haut
	var angle := fmod(dir.angle() + TAU, TAU)
	# Secteur 0=droite, 1=bas-droite, 2=bas, 3=bas-gauche, 4=gauche, 5=haut-gauche, 6=haut, 7=haut-droite
	var sector := (int((angle + PI / 8.0) / (PI / 4.0)) + direction_offset) % 8
	sprite.texture = directional_textures[sector]
	sprite.rotation = 0.0


## Mode 2D — rotation clampée du sprite (fallback si pas de sprites 3D).
func _face_2d(target_global_pos: Vector2) -> void:
	var dir := (target_global_pos - global_position).normalized()
	var raw_deg := rad_to_deg(dir.angle()) - sprite_base_angle_deg
	raw_deg = fmod(raw_deg + 180.0, 360.0) - 180.0
	var clamped_deg := clampf(raw_deg, -max_aim_degrees, max_aim_degrees)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(sprite, "rotation_degrees", clamped_deg, 0.12)


## Retour à l'orientation par défaut quand il n'y a plus de cible.
func reset_aim() -> void:
	if sprite == null:
		return
	if _has_4dir():
		return  # mode 4 dirs : on garde la dernière direction (pas de snap au repos)
	if directional_textures.size() == 8:
		sprite.texture = directional_textures[6]  # secteur 6 = haut = front de la tour
	else:
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(sprite, "rotation_degrees", 0.0, 0.3)
