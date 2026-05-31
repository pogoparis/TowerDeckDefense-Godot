extends TextureButton

signal tower_selected(scene: PackedScene)
@export var tower_scene: PackedScene

func _ready():
	# Taille et étirement pour afficher le contour
	custom_minimum_size = Vector2(148, 188)
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	# Ajoute un panneau de fond (les StyleBox ne s'appliquent pas aux TextureButton)
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # laisse le clic au bouton
	bg.z_index = -1  # rester derrière la texture
	bg.set_draw_behind_parent(true)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.08, 0.07, 1.0)
	stylebox.border_color = Color(1, 0.65, 0.2, 1)
	stylebox.shadow_color = Color(0, 0, 0, 0.6)
	stylebox.shadow_size = 8
	stylebox.shadow_offset = Vector2(0, 4)
	stylebox.set_border_width_all(4)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	bg.add_theme_stylebox_override("panel", stylebox)
	add_child(bg)

func _pressed():
	emit_signal("tower_selected", tower_scene)
	
	# Rend la carte invisible aux clics de souris
	mouse_filter = MOUSE_FILTER_IGNORE

# Fonction pour réactiver la carte (appelée depuis level.gd)
func reset():
	mouse_filter = MOUSE_FILTER_STOP
