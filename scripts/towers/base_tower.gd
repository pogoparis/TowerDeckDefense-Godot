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

@export_group("Amélioration (ferraille)")
## Nombre max d'améliorations achetables (1 = un seul palier Lv1→Lv2).
@export var max_upgrade_level := 1
## Coût en ferraille d'une amélioration.
@export var upgrade_cost := 10
## Dégâts ajoutés par niveau d'amélioration.
@export var upgrade_damage_bonus := 4
## Multiplicateur de cadence par niveau (< 1.0 = tire plus vite).
@export var upgrade_fire_rate_mult := 0.85

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

@export_group("Sprites 4 directions (personnage)")
## Si les 4 sont remplies, la tour regarde l'ennemi via 4 sprites (E/S/O/N),
## avec un switch stabilisé (pas de tremblement quand une cible meurt).
@export var tex_east: Texture2D
@export var tex_south: Texture2D
@export var tex_west: Texture2D
@export var tex_north: Texture2D

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
var laser_guide_active := false
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

	# Mode 4 directions (E/S/O/N) avec stabilisation.
	if _has_4dir():
		_update_4dir_facing(delta)
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

func upgrade_price() -> int:
	return upgrade_cost

## Tente d'acheter une amélioration. Retourne true si réussi.
func try_upgrade() -> bool:
	if not can_upgrade():
		return false
	if not Player.spend_ferraille(upgrade_price()):
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
		_upgrade_badge.add_theme_font_size_override("font_size", 28)
		_upgrade_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		_upgrade_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_upgrade_badge.add_theme_constant_override("outline_size", 6)
		_upgrade_badge.z_index = 50
		add_child(_upgrade_badge)
	_upgrade_badge.text = "★".repeat(upgrade_level)
	_upgrade_badge.position = Vector2(-12 * upgrade_level, -70)


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

func find_target() -> Node2D:

	if not enemy_manager:
		return null

	var enemies = enemy_manager.get_all_enemies()

	var valid_target: Node2D = null

	for enemy in enemies:

		if not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)

		if dist <= attack_range:

			valid_target = enemy
			break

	return valid_target
	
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

func apply_run_bonuses():

	damage = base_damage
	attack_range = base_range
	fire_rate = base_fire_rate

	# Améliorations achetées par le joueur — réappliquées ici pour persister
	# à travers chaque recalcul (synergies, adjacence…).
	damage += upgrade_damage_bonus * upgrade_level
	for _i in upgrade_level:
		fire_rate *= upgrade_fire_rate_mult

	for bonus in RunBonuses.owned_bonuses:
		damage += bonus.damage_bonus
		attack_range += bonus.range_bonus
		fire_rate *= bonus.fire_rate_mult

	# Synergie : suralimentée tant qu'elle est dans un phénomène actif.
	if phenomenon_buffed:
		damage = int(damage * phenomenon_damage_mult)
		fire_rate *= phenomenon_fire_rate_mult

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
