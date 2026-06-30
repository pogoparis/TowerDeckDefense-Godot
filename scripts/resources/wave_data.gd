extends Resource
class_name WaveData

## Vague mixée : si rempli, ces groupes sont spawnés (chacun son type/nombre)
## et les champs "enemy_*" ci-dessous sont ignorés. Vide = vague mono-type (legacy).
@export var groups: Array[WaveGroup] = []

@export var enemy_scene: PackedScene

@export var enemy_count := 10

@export var spawn_interval := 1.0

## Vitesse imposée aux ennemis de la vague. 0 = garder la vitesse de leur scène
## (recommandé en jeu normal pour des visuels cohérents). Le tuto la surcharge.
@export var enemy_speed := 0.0

## Force les PV de chaque ennemi de la vague (0 = garder ceux de la scène).
@export var enemy_hp_override := 0

@export var boss_scene: PackedScene = null

@export var boss_delay := 3.0

## Nombre total d'ennemis (somme des groupes, ou enemy_count en mono-type).
func total_count() -> int:
	if groups.size() > 0:
		var t := 0
		for g in groups:
			if g != null:
				t += g.count
		return t
	return enemy_count


@export_group("Tutoriel (optionnel)")
## Si [member tutorial_text] est non vide, un tutoriel s'affiche en pause
## AVANT cette vague (une seule fois). Laisser vide = pas de tutoriel.
@export var tutorial_title := "INFO"
@export_multiline var tutorial_text := ""
