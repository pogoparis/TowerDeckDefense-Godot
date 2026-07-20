class_name WaveLibrary
## Construit les listes de vagues par niveau, en code (plus simple à tuner que
## des .tres). Vagues mixées : chaque vague = plusieurs WaveGroup enchaînés.

const SIMPLE := preload("res://scenes/enemies/SimpleMob.tscn")
const TANK := preload("res://scenes/enemies/TankMob.tscn")
const EXPLOSIVE := preload("res://scenes/enemies/ExplosiveMob.tscn")
const MINIBOSS := preload("res://scenes/enemies/MiniBoss.tscn")


## Retourne les vagues d'un niveau, ou [] si le niveau n'a pas de liste dédiée
## (dans ce cas on garde celles définies dans la scène).
static func get_waves(level_id: int) -> Array[WaveData]:
	match level_id:
		2: return _level2()
		3: return _level3()
	return []


# ── Helpers de construction ──────────────────────────────────

static func _group(scene: PackedScene, count: int, interval: float, hp := 0, speed := 0.0) -> WaveGroup:
	var g := WaveGroup.new()
	g.enemy_scene = scene
	g.count = count
	g.spawn_interval = interval
	g.hp_override = hp
	g.speed_override = speed
	return g


static func _wave(groups: Array, boss: PackedScene = null, boss_delay := 3.0) -> WaveData:
	var w := WaveData.new()
	w.groups.assign(groups)
	w.boss_scene = boss
	w.boss_delay = boss_delay
	return w


# ── Niveau 2 — Presse à Déchets (montée progressive) ─────────

static func _level2() -> Array[WaveData]:
	var waves: Array[WaveData] = []
	# V1 — intro : peu de mobs, vitesse modérée → 2 tours qui se complètent passent
	waves.append(_wave([_group(SIMPLE, 6, 1.2, 0, 110.0)]))
	# V2 — un peu plus, encore gérable aux tours seules
	waves.append(_wave([_group(SIMPLE, 8, 1.0, 0, 110.0), _group(EXPLOSIVE, 2, 1.4)]))
	# V3 — premiers tanks : les tours seules ne suffisent plus → phénomènes
	waves.append(_wave([_group(SIMPLE, 8, 0.7, 0, 120.0), _group(TANK, 3, 1.8)]))
	# V4 — explosifs + tanks
	waves.append(_wave([_group(EXPLOSIVE, 7, 1.0), _group(TANK, 3, 2.0)]))
	# V5 — vague finale massive et rapide + MiniBoss
	waves.append(_wave([_group(SIMPLE, 12, 0.5, 0, 140.0), _group(TANK, 4, 1.6)], MINIBOSS))
	return waves


# ── Niveau 3 — plus dur (plus nombreux / plus de tanks) ──────

static func _level3() -> Array[WaveData]:
	var waves: Array[WaveData] = []
	# V1 — intro (un peu plus que le niveau 2 mais reste gérable aux tours)
	waves.append(_wave([_group(SIMPLE, 7, 1.2, 0, 100.0)]))
	# V2
	waves.append(_wave([_group(SIMPLE, 10, 0.8, 0, 120.0), _group(EXPLOSIVE, 3, 1.2)]))
	# V3
	waves.append(_wave([_group(SIMPLE, 10, 0.6, 0, 130.0), _group(TANK, 4, 1.6)]))
	# V4
	waves.append(_wave([_group(EXPLOSIVE, 9, 0.9), _group(TANK, 4, 1.8)]))
	# V5 — finale + MiniBoss
	waves.append(_wave([_group(SIMPLE, 14, 0.4, 0, 150.0), _group(TANK, 5, 1.4)], MINIBOSS))
	return waves
