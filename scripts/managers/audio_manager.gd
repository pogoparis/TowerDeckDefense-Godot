extends Node
## Gestionnaire audio central du jeu (autoload "Audio").
##
## - Musique : un lecteur unique avec fondu enchaîné (bus "Music")
## - SFX : pool de lecteurs réutilisés (bus "SFX") — peut jouer plusieurs
##   sons en même temps sans en couper aucun
## - Volumes : réglés par les sliders des menus, persistés dans
##   user://settings.cfg (survivent au redémarrage du jeu)
##
## Usage :
##   Audio.play_music(preload("res://assets/audio/music/theme.ogg"))
##   Audio.play_sfx(preload("res://assets/audio/sfx/click.wav"))

const SETTINGS_PATH := "user://settings.cfg"
const SFX_POOL_SIZE := 8

const UI_CLICK := preload("res://assets/audio/sfx/ui_click.wav")
const ERROR := preload("res://assets/audio/sfx/error.wav")

## Pistes musicales — fournies par l'utilisateur (Suno). Tant que les
## fichiers n'existent pas, les appels sont silencieusement ignorés.
## .mp3 et .ogg acceptés (le premier trouvé gagne).
const MUSIC_MENU_PATHS: Array[String] = [
	"res://assets/audio/Musics/menu_song.mp3",
]
const MUSIC_GAME_PATHS: Array[String] = [
	"res://assets/audio/Musics/music_game.mp3",
]

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _music_volume: float = 0.8
var _sfx_volume: float = 0.8


func _ready() -> void:
	# L'audio continue pendant la pause (menu pause, game over).
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)

	_load_settings()


# ── Musique ───────────────────────────────────────────────────────────────

## Lance une musique en boucle avec fondu d'entrée.
## Ne fait rien si cette musique joue déjà.
func play_music(stream: AudioStream, fade_duration: float = 0.8) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", 0.0, fade_duration)


## Musique des menus (splash, menu principal, carte du monde).
## La piste continue sans coupure d'un écran à l'autre.
func play_menu_music() -> void:
	_play_music_paths(MUSIC_MENU_PATHS)


## Musique en partie.
func play_game_music() -> void:
	_play_music_paths(MUSIC_GAME_PATHS)


func _play_music_paths(paths: Array[String]) -> void:
	for path in paths:
		if not ResourceLoader.exists(path):
			continue
		var stream: AudioStream = load(path)
		if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
			stream.loop = true
		play_music(stream)
		return


## Arrête la musique avec fondu de sortie.
func stop_music(fade_duration: float = 0.8) -> void:
	if not _music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, fade_duration)
	tween.tween_callback(_music_player.stop)


# ── Effets sonores ────────────────────────────────────────────────────────

## Joue un effet sonore. [param pitch_variation] ajoute une variation
## aléatoire de hauteur (ex. 0.1 = ±10 %) pour éviter la répétitivité.
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_variation: float = 0.0) -> void:
	if stream == null:
		return
	var player := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


## Raccourci : son de clic standard pour tous les boutons UI.
func ui_click() -> void:
	play_sfx(UI_CLICK, -6.0, 0.05)


## Raccourci : son d'erreur (action refusée, pas assez de ressources…).
func error() -> void:
	play_sfx(ERROR, -3.0, 0.0)


# ── Volumes (appelés par les sliders des menus) ───────────────────────────

func set_music_volume(linear: float) -> void:
	_music_volume = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), linear_to_db(maxf(_music_volume, 0.0001))
	)
	_save_settings()


func set_sfx_volume(linear: float) -> void:
	_sfx_volume = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"), linear_to_db(maxf(_sfx_volume, 0.0001))
	)
	_save_settings()


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume


# ── Persistance ───────────────────────────────────────────────────────────

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", _music_volume)
	config.set_value("audio", "sfx_volume", _sfx_volume)
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	set_music_volume(config.get_value("audio", "music_volume", 0.8))
	set_sfx_volume(config.get_value("audio", "sfx_volume", 0.8))
