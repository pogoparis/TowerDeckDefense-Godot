class_name LevelData
extends Resource
## Données d'un niveau affiché sur la carte du monde.
##
## Pour ajouter un niveau au jeu : créer un nouveau .tres dans
## resources/levels/ (clic droit → New Resource → LevelData),
## le remplir dans l'inspecteur, puis l'ajouter à la liste
## "levels" de WorldMap.tscn. Aucun code à toucher.

## Identifiant unique du niveau (1, 2, 3…). Le niveau N se débloque
## quand le niveau N-1 a au moins 1 étoile.
@export var level_id: int = 1

## Nom affiché sous le pin sur la carte.
@export var display_name: String = "Niveau"

## Scène de jeu lancée quand on clique sur le pin.
@export_file("*.tscn") var scene_path: String = "res://scenes/ui/level.tscn"

## Position du pin sur la carte du monde, en fraction de l'image
## (0,0 = coin haut-gauche, 1,1 = coin bas-droit).
@export var map_position: Vector2 = Vector2(0.5, 0.5)
