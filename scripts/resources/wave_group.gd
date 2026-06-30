extends Resource
class_name WaveGroup
## Un sous-groupe d'ennemis dans une vague. Plusieurs groupes dans une même
## WaveData = vague mixée (ex : nuée de SimpleMob + 2 TankMob).

@export var enemy_scene: PackedScene
@export var count := 5
@export var spawn_interval := 1.0
## Force les PV (0 = garder ceux de la scène).
@export var hp_override := 0
## Force la vitesse (0 = garder celle de la scène).
@export var speed_override := 0.0
