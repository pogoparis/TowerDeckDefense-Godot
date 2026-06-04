extends BaseTower
class_name TowerMamaCog

@export var damage_bonus_mult := 1.3
@export var range_bonus_mult := 1.3

func _ready():

	element_type = ElementType.Type.NATURE

	super._ready()
