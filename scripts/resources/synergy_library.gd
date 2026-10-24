class_name SynergyLibrary
## Catalogue des RÉACTIONS ÉLÉMENTAIRES, pour les afficher au joueur.
##
## Indexé par ÉLÉMENT et non par nom de tour : une réaction appartient au
## couple Eau+Glace, pas au couple Requin+Pingouin. Une nouvelle tour de Glace
## hérite donc automatiquement des réactions de la Glace, sans rien toucher ici.
##
## ⚠ Ce fichier ne CRÉE aucune réaction : il DÉCRIT celles qui existent dans
## reaction_manager.gd. Toute réaction ajoutée là-bas doit être décrite ici,
## sinon le joueur ne peut pas la découvrir autrement que par accident — et une
## difficulté qui repose sur des combos invisibles n'est pas un défi, c'est un
## piège.

## [source] = statut posé par la tour · [partner] = l'autre moitié
## Les REACTIONS de zone (Charges des signatures) sont notées "charge": true —
## elles ne se déclenchent pas en tirant, mais en déclenchant une Charge.
const REACTIONS := [
	{
		"name": "CRYOGÉNISATION",
		"elements": [ElementType.Type.WATER, ElementType.Type.ICE],
		"effect": "Fige l'ennemi sur place 2 s.",
	},
	{
		"name": "TEMPÊTE DE SABLE",
		"elements": [ElementType.Type.EARTH, ElementType.Type.AIR],
		"effect": "Dégâts de zone + ralentissement autour de la cible.",
	},
	{
		"name": "SPORES",
		"elements": [ElementType.Type.NATURE, ElementType.Type.AIR],
		"effect": "Le vent propage le poison aux ennemis voisins.",
	},
	{
		"name": "ÉLECTROCUTION",
		"elements": [ElementType.Type.WATER, ElementType.Type.ELECTRIC],
		"effect": "Décharge répétée sur l'ennemi trempé.",
	},
	{
		"name": "VAPEUR",
		"elements": [ElementType.Type.WATER, ElementType.Type.FIRE],
		"effect": "Choc thermique sur l'ennemi trempé et en feu.",
	},
	{
		"name": "SURCHAUFFE",
		"elements": [ElementType.Type.FIRE, ElementType.Type.ELECTRIC],
		"effect": "L'ennemi en feu et chargé encaisse un surplus.",
	},
	{
		"name": "ATTISÉ",
		"elements": [ElementType.Type.AIR, ElementType.Type.FIRE],
		"effect": "Le vent ravive les flammes.",
	},
	{
		"name": "DÉCHARGE",
		"elements": [ElementType.Type.AIR, ElementType.Type.ELECTRIC],
		"effect": "La marque de vent conduit l'électricité.",
	},
	{
		"name": "ÉCLABOUSSURE",
		"elements": [ElementType.Type.WATER, ElementType.Type.AIR],
		"effect": "La bourrasque projette l'eau sur la cible.",
	},
]


## Réactions auxquelles [param element] participe, avec l'élément partenaire :
## [{name, effect, partner}, …]. Vide si l'élément n'en a aucune.
static func get_reactions_for(element: ElementType.Type) -> Array:
	var result := []
	if element == ElementType.Type.NONE:
		return result

	for r in REACTIONS:
		var pair: Array = r["elements"]
		if not pair.has(element):
			continue
		var partner: ElementType.Type = pair[0] if pair[1] == element else pair[1]
		result.append({
			"name": r["name"],
			"effect": r["effect"],
			"partner": partner,
		})
	return result
