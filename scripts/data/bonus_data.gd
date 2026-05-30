extends Resource
class_name BonusData

# fire_rate_mult :
# 1.0 = normal
# 0.8 = 20% faster
# 0.65 = 35% faster

@export var title : String
@export_multiline var description : String

@export var damage_bonus := 0
@export var range_bonus := 0
@export var fire_rate_mult := 1.0

@export_enum("COMMON", "RARE", "EPIC", "LEGENDARY")
var rarity : String = "COMMON"

@export var slow_bonus := 0.0
@export var burn_bonus := 0.0
@export var capsule_bonus := 0.0
