class_name PhenomenonBase
extends Node2D

enum PhenomenonType {
	PUDDLE,
	CHARGED_ZONE,
	AIR_CURRENT,
}

@export var element: JunkElement.Type = JunkElement.Type.WATER
@export var phenomenon_type: PhenomenonType = PhenomenonType.PUDDLE
@export var radius: float = 28.0
@export var max_duration: float = 5.0
@export var tint: Color = Color.WHITE

var age: float = 0.0
var source_tower: Node2D = null
var generation_multiplier: float = 1.0


func _ready() -> void:
	add_to_group("phenomena")
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	if age >= max_duration:
		queue_free()
		return
	queue_redraw()


func get_visual_alpha() -> float:
	var life_ratio := 1.0 - (age / max_duration)
	return clampf(life_ratio * 0.85 + 0.15, 0.15, 1.0)


func get_effective_radius() -> float:
	return radius * generation_multiplier


func _draw() -> void:
	var alpha := get_visual_alpha()
	var r := get_effective_radius()
	var fill := tint
	fill.a = 0.25 * alpha
	var border := tint.lightened(0.2)
	border.a = 0.7 * alpha
	draw_circle(Vector2.ZERO, r, fill)
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, border, 2.5)
	if generation_multiplier > 1.05:
		var pulse := 0.5 + 0.5 * sin(age * 8.0)
		var boost := tint.lightened(0.35)
		boost.a = 0.15 * pulse * alpha
		draw_circle(Vector2.ZERO, r * 1.08, boost)


func overlaps(other: PhenomenonBase) -> bool:
	if not is_instance_valid(other):
		return false
	var dist := global_position.distance_to(other.global_position)
	return dist < get_effective_radius() + other.get_effective_radius()
