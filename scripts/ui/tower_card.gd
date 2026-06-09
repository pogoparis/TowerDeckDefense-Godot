extends TextureButton
class_name TowerCardUI

signal card_tapped(card_data, card_ui)

const TOOLTIP_SCENE = preload("res://scenes/ui/card_tooltip.tscn")

var card_data: CardData
var tooltip = null
var is_selected := false


func setup(data: CardData):
	card_data = data
	texture_normal = data.card_texture


func set_selected(value: bool):
	is_selected = value
	if is_selected:
		modulate = Color(1.4, 1.4, 0.6)   # teinte dorée = sélectionnée
		scale = Vector2(1.1, 1.1)
	else:
		modulate = Color.WHITE
		scale = Vector2(1.0, 1.0)


func _pressed():
	card_tapped.emit(card_data, self)


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered():

	if tooltip:
		return

	tooltip = TOOLTIP_SCENE.instantiate()

	var anchor = get_tree().current_scene.get_node(
		"UI/RootUI/CardTooltipAnchor"
	)

	anchor.add_child(tooltip)
	tooltip.position = Vector2.ZERO
	tooltip.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(tooltip, "modulate:a", 1.0, 0.15)
	tooltip.setup(card_data)


func _on_mouse_exited():

	if tooltip:
		tooltip.queue_free()
		tooltip = null
