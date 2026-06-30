class_name TopHUD
extends Control
## Barre d'information principale en haut de l'écran pendant une partie.
##
## Affiche : vague courante, kills, PV de la base, caps, bouton vitesse,
## bouton paramètres, barre de progression de vague et label de statut.
## Tout le style visuel vient de res://resources/themes/junkriot_theme.tres —
## aucun style ne doit être défini dans ce script.

## Points de vie maximum de la base (utilisé pour le code couleur des PV).
@export var max_base_hp: int = 20

## Couleur des PV au-dessus de [member hp_warning_threshold].
@export var hp_color_high: Color = Color(0.35, 1.0, 0.45)
## Couleur des PV entre les deux seuils.
@export var hp_color_medium: Color = Color(1.0, 0.7, 0.15)
## Couleur des PV sous [member hp_critical_threshold].
@export var hp_color_low: Color = Color(1.0, 0.25, 0.25)
## Ratio de PV sous lequel la couleur passe en "warning".
@export_range(0.0, 1.0) var hp_warning_threshold: float = 0.6
## Ratio de PV sous lequel la couleur passe en "critique".
@export_range(0.0, 1.0) var hp_critical_threshold: float = 0.3

var _enemy_manager: EnemyManager = null
var _wave_total: int = 0
var _spawned_count: int = 0
var _leaked_count: int = 0
var _prep_total: int = 0
var _in_prep: bool = false

@onready var wave_label: Label = $Panel/VBox/StatsRow/WaveSection/WaveNum
@onready var enemy_label: Label = $Panel/VBox/StatsRow/EnemySection/EnemyCount
@onready var base_hp_label: Label = $Panel/VBox/StatsRow/HPSection/HPCount
@onready var caps_label: Label = $Panel/VBox/StatsRow/CapsSection/CapsCount
@onready var ferraille_label: Label = $Panel/VBox/StatsRow/FerrailleSection/FerrailleCount
@onready var speed_button: Button = $Panel/VBox/StatsRow/SpeedButton
@onready var settings_button: Button = $Panel/VBox/StatsRow/SettingsButton
@onready var wave_bar: ProgressBar = $Panel/VBox/WaveBar
@onready var status_label: Label = $Panel/VBox/StatusLabel


func _ready() -> void:
	set_base_hp(max_base_hp)


func _process(_delta: float) -> void:
	if _in_prep or _enemy_manager == null or _wave_total == 0:
		return
	var alive: int = _enemy_manager.get_all_enemies().size()
	var killed: int = maxi(0, _spawned_count - alive - _leaked_count)
	enemy_label.text = "%d / %d" % [killed, _wave_total]


## Connecte le HUD aux signaux de jeu. À appeler une fois depuis le level.
func setup(enemy_manager: EnemyManager) -> void:
	_enemy_manager = enemy_manager
	enemy_manager.enemy_leaked.connect(_on_enemy_leaked)
	Player.base_hp_changed.connect(_on_base_hp_changed)


func set_wave(current: int, total: int) -> void:
	wave_label.text = "%d / %d" % [current, total]


func set_base_hp(hp: int) -> void:
	base_hp_label.text = str(hp)
	var ratio: float = float(hp) / float(max_base_hp)
	var color: Color = hp_color_high
	if ratio <= hp_critical_threshold:
		color = hp_color_low
	elif ratio <= hp_warning_threshold:
		color = hp_color_medium
	base_hp_label.add_theme_color_override("font_color", color)


func set_caps(amount: int) -> void:
	caps_label.text = str(amount)


func set_ferraille(amount: int) -> void:
	ferraille_label.text = str(amount)


## Initialise la barre de vague : [param total] = nombre d'ennemis à spawner.
func set_wave_total(total: int) -> void:
	_wave_total = total
	_spawned_count = 0
	_leaked_count = 0
	_in_prep = false
	wave_bar.max_value = float(maxi(total, 1))
	wave_bar.value = 0.0
	enemy_label.text = "0 / %d" % total


## À appeler à chaque spawn d'ennemi : la barre se remplit au fil des spawns.
func on_enemy_spawned() -> void:
	_spawned_count += 1
	wave_bar.value = float(_spawned_count)


## Mode préparation : la barre se remplit au fil du compte à rebours.
func set_prep_countdown(seconds: int) -> void:
	if not _in_prep:
		_in_prep = true
		_prep_total = seconds
		wave_bar.max_value = float(maxi(seconds, 1))
	status_label.text = "PROCHAINE VAGUE DANS : %02d" % seconds
	wave_bar.value = float(_prep_total - seconds)


func set_wave_status(text: String) -> void:
	_in_prep = false
	status_label.text = text


func _on_enemy_leaked() -> void:
	_leaked_count += 1


func _on_base_hp_changed(hp: int) -> void:
	if hp > 0:
		return
	var level := get_tree().current_scene
	if level and level.has_method("show_defeat"):
		level.show_defeat()
	else:
		set_wave_status("DEFAITE !")
