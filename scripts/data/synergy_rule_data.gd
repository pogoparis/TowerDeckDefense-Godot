class_name SynergyRuleData
extends Resource

enum EffectType {
	GENERATION_SPEED,
	PHENOMENON_SIZE,
	STORM_FREQUENCY,
}

@export var synergy_id: String = ""
@export var display_name: String = ""
@export var element_a: JunkElement.Type = JunkElement.Type.WATER
@export var element_b: JunkElement.Type = JunkElement.Type.ELECTRIC
@export var effect: EffectType = EffectType.GENERATION_SPEED
@export var multiplier: float = 1.3
@export var visual_profile: SynergyVisualProfile


func matches_elements(a: JunkElement.Type, b: JunkElement.Type) -> bool:
	return (element_a == a and element_b == b) or (element_a == b and element_b == a)
