extends PanelContainer

@onready var active_list: VBoxContainer = $Margin/VBox/ActiveList
@onready var possible_list: VBoxContainer = $Margin/VBox/PossibleList
@onready var active_header: Label = $Margin/VBox/ActiveHeader
@onready var possible_header: Label = $Margin/VBox/PossibleHeader


func _ready() -> void:
	visible = SynergyGuideService.should_show_synergy_panel()
	if SynergyManager:
		SynergyManager.registry_changed.connect(_refresh)
	_refresh()


func _process(_delta: float) -> void:
	var should_show := SynergyGuideService.should_show_synergy_panel()
	if visible != should_show:
		visible = should_show


func _refresh() -> void:
	if not SynergyManager:
		return
	_clear_list(active_list)
	_clear_list(possible_list)

	var level := get_tree().current_scene
	var preview: Dictionary = {}
	if level and level.get("ghost_tower") and level.ghost_tower and level.get("selected_tower_data"):
		var cell: Vector2i = level.world_to_cell(level.ghost_tower.global_position)
		preview = SynergyManager.get_preview_synergies(level.selected_tower_data.element, cell)

	for inst in SynergyManager.get_active_synergies():
		_add_row(active_list, inst, false)

	for inst in preview.get("possible", []):
		_add_row(possible_list, inst, true)

	active_header.visible = active_list.get_child_count() > 0
	possible_header.visible = possible_list.get_child_count() > 0


func _clear_list(box: VBoxContainer) -> void:
	for c in box.get_children():
		c.queue_free()


func _add_row(box: VBoxContainer, inst: SynergyInstance, is_possible: bool) -> void:
	var label := Label.new()
	var prefix := "Possible : " if is_possible else "Active : "
	var name := inst.rule.display_name if inst.rule else "?"
	if inst.rule and inst.rule.visual_profile and inst.rule.visual_profile.display_label != "":
		name = inst.rule.visual_profile.display_label
	label.text = prefix + name
	label.add_theme_font_size_override("font_size", 14)
	if inst.rule and inst.rule.visual_profile:
		label.add_theme_color_override("font_color", inst.rule.visual_profile.link_color_a)
	box.add_child(label)
