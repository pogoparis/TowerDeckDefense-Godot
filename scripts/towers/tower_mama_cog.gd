extends TowerFire
class_name TowerMamaCog

func _ready():

	super._ready()

	if timer:
		timer.stop()
