extends TextureButton

signal tower_selected(data: TowerData)

@export var tower_data: TowerData


func _ready() -> void:
	custom_minimum_size = Vector2(120, 140)
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_apply_background()
	pressed.connect(_on_pressed)


func _apply_background() -> void:
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -1
	bg.set_draw_behind_parent(true)
	var stylebox := StyleBoxFlat.new()
	var border := tower_data.element_color if tower_data else Color(1, 0.65, 0.2)
	stylebox.bg_color = Color(0.08, 0.1, 0.12, 0.95)
	stylebox.border_color = border
	stylebox.set_border_width_all(3)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	bg.add_theme_stylebox_override("panel", stylebox)
	add_child(bg)
	move_child(bg, 0)

	var label := Label.new()
	label.text = tower_data.display_name if tower_data else "Tour"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -28
	label.add_theme_font_size_override("font_size", 11)
	if tower_data:
		label.add_theme_color_override("font_color", tower_data.element_color)
	add_child(label)


func _on_pressed() -> void:
	if tower_data:
		emit_signal("tower_selected", tower_data)


func reset() -> void:
	mouse_filter = MOUSE_FILTER_STOP
