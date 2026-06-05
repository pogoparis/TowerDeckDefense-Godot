extends Node

enum GuideLevel {
	FULL,
	REDUCED,
	TERRAIN_ONLY,
}

const SAVE_PATH := "user://synergy_guide.json"

@export var force_guide_level: int = -1

var runs_completed: int = 0


func _ready() -> void:
	_load()


func get_guide_level() -> GuideLevel:
	if force_guide_level >= 0:
		return clampi(force_guide_level, 0, 2) as GuideLevel
	if runs_completed <= 2:
		return GuideLevel.FULL
	if runs_completed <= 5:
		return GuideLevel.REDUCED
	return GuideLevel.TERRAIN_ONLY


func should_show_placement_halos() -> bool:
	return get_guide_level() != GuideLevel.TERRAIN_ONLY


func should_show_synergy_panel() -> bool:
	return get_guide_level() == GuideLevel.FULL


func should_show_link_icons() -> bool:
	return get_guide_level() == GuideLevel.FULL


func should_show_floating_text() -> bool:
	return get_guide_level() != GuideLevel.TERRAIN_ONLY


func should_show_partner_dimming() -> bool:
	return get_guide_level() != GuideLevel.TERRAIN_ONLY


func record_run_completed() -> void:
	runs_completed += 1
	_save()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) == OK:
		var data: Variant = json.data
		if data is Dictionary and data.has("runs_completed"):
			runs_completed = int(data["runs_completed"])


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not f:
		return
	f.store_string(JSON.stringify({"runs_completed": runs_completed}))
