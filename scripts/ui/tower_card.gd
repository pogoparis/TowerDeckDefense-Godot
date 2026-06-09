extends TextureButton
class_name TowerCardUI

signal card_tapped(card_data, card_ui)
signal card_drag_started(card_data, card_ui)

const TOOLTIP_SCENE = preload("res://scenes/ui/card_tooltip.tscn")
const DRAG_THRESHOLD := 15.0

var card_data: CardData
var tooltip = null
var is_selected := false

var _press_position := Vector2.ZERO
var _drag_emitted := false


func setup(data: CardData):
	card_data = data
	texture_normal = data.card_texture


func set_selected(value: bool):
	is_selected = value
	if is_selected:
		modulate = Color(1.4, 1.4, 0.6)
		scale = Vector2(1.1, 1.1)
	else:
		modulate = Color.WHITE
		scale = Vector2(1.0, 1.0)


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# Désactive le signal pressed natif — on gère tout dans _gui_input
func _pressed():
	pass


func _gui_input(event: InputEvent):

	# ── TOUCH (mobile) ──────────────────────────────────
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_position = event.position
			_drag_emitted = false
		else:
			# Relâché sans drag → tap
			if not _drag_emitted:
				card_tapped.emit(card_data, self)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		if not _drag_emitted:
			if event.position.distance_to(_press_position) > DRAG_THRESHOLD:
				_drag_emitted = true
				card_drag_started.emit(card_data, self)
		get_viewport().set_input_as_handled()
		return

	# ── SOURIS (desktop / éditeur) ───────────────────────
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_position = event.position
			_drag_emitted = false
		else:
			if not _drag_emitted:
				card_tapped.emit(card_data, self)
		return

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _drag_emitted:
			if event.position.distance_to(_press_position) > DRAG_THRESHOLD:
				_drag_emitted = true
				card_drag_started.emit(card_data, self)
		return


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
