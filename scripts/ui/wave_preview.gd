class_name WavePreview
extends PanelContainer
## Encart "prochaine vague" affiché en haut à droite pendant la préparation.
##
## Le style vient de junkriot_theme.tres (variations PreviewPanel,
## PreviewTitle, PreviewText, AlertText) — aucun style dans ce script.

@onready var title_label: Label = $VBox/TitleLabel
@onready var content_label: Label = $VBox/ContentLabel
@onready var boss_label: Label = $VBox/BossLabel


func _ready() -> void:
	hide()


func show_wave(wave_index: int, wave_data: WaveData) -> void:
	title_label.text = "— VAGUE %d —" % (wave_index + 1)

	if wave_data.groups.size() > 0:
		# Vague mixée : une ligne par groupe.
		var text := ""
		for g in wave_data.groups:
			if g == null or g.enemy_scene == null:
				continue
			if text != "":
				text += "\n"
			text += "%s  ×%d" % [_enemy_name(g.enemy_scene), g.count]
		content_label.text = text
	else:
		content_label.text = "%s  ×%d" % [_enemy_name(wave_data.enemy_scene), wave_data.enemy_count]

	boss_label.visible = wave_data.boss_scene != null
	if wave_data.boss_scene:
		boss_label.text = "⚠ MINIBOSS à la fin"

	show()


func hide_preview() -> void:
	hide()


func _enemy_name(scene: PackedScene) -> String:
	if scene == null:
		return "?"
	var path := scene.resource_path
	if "Tank" in path:
		return "Tank"
	if "Explosive" in path:
		return "Explosif"
	if "MiniBoss" in path:
		return "MiniBoss"
	if "Simple" in path:
		return "Scout"
	return "Ennemi"
