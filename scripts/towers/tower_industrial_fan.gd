extends ProjectileTower
class_name TowerIndustrialFan

@export var damage_bonus_mult := 1.3
@export var range_bonus_mult := 1.3

func _ready():

	element_type = ElementType.Type.AIR

	super._ready()
