extends BaseTower
class_name TowerMamaCog

@export var aura_range := 128.0
@export var damage_bonus_mult := 1.3
@export var range_bonus_mult := 1.3

var buffed_towers: Array[BaseTower] = []

func _ready():

	super._ready()
	
func _process(_delta):

	update_aura()

func update_aura():

	for tower in buffed_towers:

		if is_instance_valid(tower):

			tower.damage = tower.base_damage
			tower.attack_range = tower.base_range

	buffed_towers.clear()

	var towers = get_tree().get_nodes_in_group("towers")

	for tower in towers:

		if tower == self:
			continue

		if not tower is BaseTower:
			continue

		var dist = global_position.distance_to(tower.global_position)

		if dist > aura_range:
			continue

		tower.damage = int(tower.base_damage * damage_bonus_mult)
		tower.attack_range = tower.base_range * range_bonus_mult

		buffed_towers.append(tower)
