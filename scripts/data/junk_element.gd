class_name JunkElement
extends RefCounted

enum Type {
	WATER,
	ELECTRIC,
	AIR,
	FIRE,
	NATURE,
}

static func color_for(element: Type) -> Color:
	match element:
		Type.WATER:
			return Color(0.2, 0.65, 1.0)
		Type.ELECTRIC:
			return Color(1.0, 0.85, 0.2)
		Type.AIR:
			return Color(0.6, 0.95, 1.0)
		Type.FIRE:
			return Color(1.0, 0.45, 0.15)
		Type.NATURE:
			return Color(0.3, 0.85, 0.35)
		_:
			return Color.WHITE


static func display_name(element: Type) -> String:
	match element:
		Type.WATER:
			return "Eau"
		Type.ELECTRIC:
			return "Électricité"
		Type.AIR:
			return "Air"
		Type.FIRE:
			return "Feu"
		Type.NATURE:
			return "Nature"
		_:
			return "?"
