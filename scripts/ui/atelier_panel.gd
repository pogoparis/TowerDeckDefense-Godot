class_name AtelierPanel
extends CanvasLayer
## L'ATELIER — le niveau bac à sable où l'on REGARDE les mobs.
##
## ── POURQUOI CE NIVEAU EXISTE ─────────────────────────────────────────────
## Un mob se juge en mouvement : sa silhouette à 100 px, la façon dont il
## tourne aux angles, sa vitesse ressentie, et — pour la Fournaise — sa montée
## en régime. Rien de tout ça ne se voit sur un PNG, et le vérifier en jouant
## une vraie partie demande de survivre jusqu'à la vague 7 avec le bon deck.
## On passait donc plus de temps à atteindre le mob qu'à le regarder.
##
## L'Atelier lâche n'importe quel mob du catalogue, tout de suite, seul, avec
## des PV infinis si on veut le suivre sur tout le trajet.
##
## ── CE QU'IL N'EST PAS ────────────────────────────────────────────────────
## Ce n'est pas un mode de jeu : pas de vagues, pas de score, pas d'étoiles.
## Il est branché sur le niveau 99 pour ne jamais entrer dans la numérotation
## des vrais niveaux — quel que soit le nombre de niveaux créés un jour, il
## n'y aura pas de collision, et il n'a pas besoin d'être débloqué.

const LEVEL_ID := 99

## PV donnés en mode « infini » : assez pour traverser toute la carte sous le
## feu de plusieurs tours, sans utiliser une valeur qui casse la barre de vie.
const IMMORTAL_HP := 999999

var _path: Path2D
var _wave_manager: WaveManager
var _enemy_manager: EnemyManager
var _immortal := false
var _count := 1

var _info: Label


func setup(path: Path2D, wave_manager: WaveManager,
		enemy_manager: EnemyManager) -> void:
	_path = path
	_wave_manager = wave_manager
	_enemy_manager = enemy_manager
	_build_ui()


# ══════════════════════════════════════════════════════
#                    L'INTERFACE
# ══════════════════════════════════════════════════════
#
# Construite en code et pas en .tscn : elle liste le catalogue d'ennemis, qui
# change à chaque nouveau mob. Une scène devrait être rouverte et re-remplie à
# la main à chaque fois — l'outil se périmerait exactement au moment où il sert.

func _build_ui() -> void:
	layer = 60

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(240, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.09, 0.92)
	style.border_color = Color(1.0, 0.55, 0.15, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	box.add_child(_title("⚒  ATELIER", Color(1.0, 0.72, 0.3), 18))
	box.add_child(_hint("Clique un mob pour le lâcher."))
	box.add_child(HSeparator.new())

	for id in WaveLibrary.ENEMIES:
		box.add_child(_enemy_button(id))

	box.add_child(HSeparator.new())

	# Nombre lâché par clic : voir UN mob renseigne sur son design, en voir
	# quinze renseigne sur la lisibilité d'une vague — deux questions
	# différentes, et il faut pouvoir passer de l'une à l'autre.
	var counts := HBoxContainer.new()
	counts.add_theme_constant_override("separation", 4)
	for n: int in [1, 5, 15]:
		var b := Button.new()
		b.text = "×%d" % n
		b.custom_minimum_size = Vector2(50, 0)
		b.toggle_mode = true
		b.button_pressed = (n == 1)
		b.pressed.connect(_on_count_pressed.bind(n, counts))
		counts.add_child(b)
	box.add_child(_label("Par clic"))
	box.add_child(counts)

	# PV infinis : sans ça, un mob bien défendu meurt au premier virage et on
	# ne voit jamais ses vues Nord et Ouest.
	var immortal := CheckButton.new()
	immortal.text = "PV infinis"
	immortal.tooltip_text = "Le mob traverse toute la carte : on voit ses 4 vues."
	immortal.toggled.connect(func(on: bool): _immortal = on)
	box.add_child(immortal)

	box.add_child(_label("Vitesse du temps"))
	var speed := HSlider.new()
	speed.min_value = 0.1
	speed.max_value = 4.0
	speed.step = 0.1
	speed.value = 1.0
	speed.custom_minimum_size = Vector2(0, 20)
	speed.value_changed.connect(_on_speed_changed)
	box.add_child(speed)

	box.add_child(HSeparator.new())

	# Le givre est le seul contre de la Fournaise : il faut pouvoir l'appliquer
	# sans monter une tour de glace pour vérifier qu'elle refroidit bien.
	box.add_child(_action("❄  Givrer tout le monde", _on_chill_all))
	box.add_child(_action("💰  +500 caps", _on_caps))
	box.add_child(_action("🧹  Nettoyer", _on_clear))
	box.add_child(_action("←  Quitter l'atelier", _on_quit))

	_info = _hint("")
	_info.custom_minimum_size = Vector2(220, 0)
	box.add_child(_info)


func _enemy_button(id: String) -> Button:
	var entry: Dictionary = WaveLibrary.ENEMIES[id]
	var b := Button.new()
	b.text = entry.get("name", id)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.tooltip_text = _describe(id)
	b.pressed.connect(_on_spawn.bind(id))
	return b


## Fiche du mob, lue sur sa scène : jamais recopiée, donc jamais fausse.
func _describe(id: String) -> String:
	var entry: Dictionary = WaveLibrary.ENEMIES.get(id, {})
	if not entry.has("scene"):
		return id
	var probe = entry["scene"].instantiate()
	var txt := id
	if probe is EnemyBase:
		txt = "%d PV · %.0f px/s\nfaible : %s\nrésiste : %s" % [
			probe.max_hp, probe.speed,
			ElementType.label(probe.weak_to), ElementType.label(probe.resists),
		]
	probe.free()
	return txt


# ══════════════════════════════════════════════════════
#                     LES ACTIONS
# ══════════════════════════════════════════════════════

func _on_spawn(id: String) -> void:
	var entry: Dictionary = WaveLibrary.ENEMIES.get(id, {})
	if not entry.has("scene") or _path == null or _wave_manager == null:
		return

	for i in _count:
		var pf: PathFollow2D = _wave_manager._spawn_enemy_instance(entry["scene"])
		if pf == null:
			continue
		_path.add_child(pf)
		pf.progress = 0.0

		if _immortal and pf.get_child_count() > 0:
			var enemy = pf.get_child(0)
			if enemy is EnemyBase:
				enemy.max_hp = IMMORTAL_HP
				enemy.hp = IMMORTAL_HP
				enemy.update_hp_bar()

		# Espacés, sinon ils se superposent exactement et on n'en voit qu'un.
		if i < _count - 1:
			await get_tree().create_timer(0.45).timeout

	_info.text = _describe(id)


func _on_count_pressed(n: int, row: HBoxContainer) -> void:
	_count = n
	for child in row.get_children():
		if child is Button:
			child.button_pressed = (child.text == "×%d" % n)


func _on_speed_changed(v: float) -> void:
	Engine.time_scale = v


func _on_chill_all() -> void:
	for e in _living():
		e.add_chill(0.3, 4.0)


func _on_caps() -> void:
	Player.add_caps(500)


## Retire les mobs SANS les tuer : pas de caps gagnés, pas d'explosion, pas de
## scission en petits. Un « nettoyer » qui déclenche les morts remplirait
## l'écran de débris et fausserait l'observation suivante.
##
## Il faut désenregistrer à la main et libérer le PathFollow2D parent : c'est
## die() qui fait normalement les deux, et un simple queue_free() sur l'ennemi
## laissait un chemin fantôme et un compteur qui ne redescendait jamais.
func _on_clear() -> void:
	for e in _living():
		if _enemy_manager != null:
			_enemy_manager.unregister_enemy(e)
		var pf: Node = e.get_parent()
		if pf is PathFollow2D:
			pf.queue_free()
		else:
			e.queue_free()


## Les ennemis vivants. On copie la liste : queue_free() la modifie pendant
## qu'on la parcourt, et un ennemi sur deux serait sauté.
func _living() -> Array:
	if _enemy_manager == null:
		return []
	var out := []
	for e in _enemy_manager.get_all_enemies():
		if is_instance_valid(e) and e is EnemyBase:
			out.append(e)
	return out


func _on_quit() -> void:
	# Le facteur de temps est global : le laisser à 3× empoisonnerait la partie
	# suivante, et le bug serait très difficile à relier à l'atelier.
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/ui/WorldMap.tscn")


# ══════════════════════════════════════════════════════
#                      HELPERS
# ══════════════════════════════════════════════════════

func _title(text: String, color: Color, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l


func _label(text: String) -> Label:
	return _title(text, Color(0.62, 0.60, 0.68), 12)


func _hint(text: String) -> Label:
	var l := _title(text, Color(0.62, 0.60, 0.68), 12)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _action(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	return b
