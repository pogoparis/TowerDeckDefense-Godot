class_name SynergyLibrary

static func get_all():

	var result = []

	# =========================
	# MAMA COG
	# =========================

	var mama = SynergyDefinition.new()

	mama.id = "mama_cog"

	mama.synergy_name = "Mama Cog"

	mama.partner_text = "Toutes les tours adjacentes"

	mama.description = (
		"Les tours adjacentes gagnent "
		+ "+10% dégâts."
	)

	mama.required_towers = [
		"TowerMamaCog"
	]

	result.append(mama)

	# =========================
	# LASER GUIDE
	# =========================

	var laser = SynergyDefinition.new()

	laser.id = "laser_guide"

	laser.synergy_name = "Laser Guide"

	laser.partner_text = "Grumbolt"

	laser.description = "+50% dégâts sur cible marquée."

	laser.required_towers = [
		"TowerVega",
		"TowerGrumbolt"
	]

	laser.required_tower_names = [
	"Vega",
	"Grumbolt"
	]
	
	result.append(laser)

	return result
