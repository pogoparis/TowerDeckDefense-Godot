extends Node
## Game feel central (autoload "Juice").
##
## Donne du punch aux moments forts du jeu :
##   - shake()     : fait trembler le monde (le HUD reste stable)
##   - hit_stop()  : micro-gel du temps pour un impact percutant
##
## Le monde à secouer est enregistré par le niveau au démarrage :
##   Juice.register_world($World)
##
## Usage :
##   Juice.shake(12.0, 0.35)   # mort d'un ennemi normal
##   Juice.shake(26.0, 0.5)    # gros ennemi / explosion en chaîne
##   Juice.hit_stop(0.06)      # gel de 60 ms sur un kill

# Le HUD ne tremble pas → on secoue uniquement ce nœud (la scène de jeu).
var _world: Node2D = null
var _world_origin := Vector2.ZERO

var _shake_strength := 0.0
var _shake_decay := 0.0

# Évite d'empiler plusieurs hit-stops qui se marchent dessus.
var _hit_stop_active := false


func _ready() -> void:
	# Doit continuer à tourner même quand le jeu est en pause/gelé.
	process_mode = Node.PROCESS_MODE_ALWAYS


## F11 bascule plein écran / fenêtré (confort en développement).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var is_fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if is_fs else DisplayServer.WINDOW_MODE_FULLSCREEN
		)


func register_world(world: Node2D) -> void:
	_world = world
	_world_origin = world.position
	_shake_strength = 0.0


func _process(delta: float) -> void:
	if _world == null or not is_instance_valid(_world):
		return

	if _shake_strength > 0.0:
		_shake_strength = maxf(0.0, _shake_strength - _shake_decay * delta)
		var offset := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * _shake_strength
		_world.position = _world_origin + offset
	elif _world.position != _world_origin:
		_world.position = _world_origin


## Secoue le monde. [param strength] en pixels, [param duration] en secondes.
## Un shake plus fort écrase un shake plus faible en cours.
func shake(strength: float, duration: float = 0.3) -> void:
	if strength <= _shake_strength:
		return
	_shake_strength = strength
	_shake_decay = strength / maxf(duration, 0.01)


## Gèle brièvement le temps de jeu pour un impact ressenti.
## Restaure la vitesse précédente (compatible avec le bouton x2).
func hit_stop(duration: float = 0.06, freeze_scale: float = 0.05) -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true

	var previous_scale := Engine.time_scale
	Engine.time_scale = freeze_scale

	# ignore_time_scale = true → le timer se déclenche malgré le gel.
	await get_tree().create_timer(duration, true, false, true).timeout

	Engine.time_scale = previous_scale
	_hit_stop_active = false
