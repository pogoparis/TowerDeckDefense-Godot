extends Node
class_name ElementType

enum Type {
	NONE,
	FIRE,
	WATER,
	ELECTRIC,
	NATURE,
	AIR,
	ICE,
	SHADOW,
	LIGHT,
	EARTH
}


## Nom affichable d'un élément (UI : briefing de niveau, aperçu de vague…).
static func label(t: Type) -> String:
	match t:
		Type.FIRE: return "Feu"
		Type.WATER: return "Eau"
		Type.ELECTRIC: return "Électricité"
		Type.NATURE: return "Nature"
		Type.AIR: return "Air"
		Type.ICE: return "Glace"
		Type.SHADOW: return "Ombre"
		Type.LIGHT: return "Lumière"
		Type.EARTH: return "Terre"
	return "Neutre"


## Pictogramme court, pour les listes compactes.
static func icon(t: Type) -> String:
	match t:
		Type.FIRE: return "🔥"
		Type.WATER: return "💧"
		Type.ELECTRIC: return "⚡"
		Type.NATURE: return "🌿"
		Type.AIR: return "🌪"
		Type.ICE: return "❄"
		Type.SHADOW: return "🦇"
		Type.LIGHT: return "✨"
		Type.EARTH: return "🪨"
	return "◦"


## Couleur associée, pour teinter les libellés d'UI.
static func color(t: Type) -> Color:
	match t:
		Type.FIRE: return Color(1.0, 0.45, 0.15)
		Type.WATER: return Color(0.3, 0.65, 1.0)
		Type.ELECTRIC: return Color(1.0, 0.9, 0.25)
		Type.NATURE: return Color(0.45, 0.85, 0.35)
		Type.AIR: return Color(0.75, 0.85, 0.9)
		Type.ICE: return Color(0.6, 0.9, 1.0)
		Type.SHADOW: return Color(0.65, 0.4, 0.85)
		Type.LIGHT: return Color(1.0, 0.95, 0.7)
		Type.EARTH: return Color(0.8, 0.65, 0.4)
	return Color(0.8, 0.8, 0.8)
