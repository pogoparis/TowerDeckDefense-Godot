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
	# V1 — intro : petite nuée
	waves.append(_wave([_group(SIMPLE, 6, 1.2)]))
	# V2 — nuée plus grosse + quelques explosifs
	waves.append(_wave([_group(SIMPLE, 8, 0.9), _group(EXPLOSIVE, 2, 1.4)]))
	# V3 — premiers tanks au milieu d'une nuée
	waves.append(_wave([_group(SIMPLE, 6, 0.8), _group(TANK, 2, 2.0)]))
	# V4 — explosifs + tanks
	waves.append(_wave([_group(EXPLOSIVE, 5, 1.1), _group(TANK, 2, 2.5)]))
	# V5 — vague finale + MiniBoss
	waves.append(_wave([_group(SIMPLE, 8, 0.7), _group(TANK, 2, 2.0)], MINIBOSS))
	return waves


# ── Niveau 3 — plus dur (plus nombreux / plus de tanks) ──────

static func _level3() -> Array[WaveData]:
	var waves: Array[WaveData] = []
	# V1
	waves.append(_wave([_group(SIMPLE, 8, 1.0)]))
	# V2
	waves.append(_wave([_group(SIMPLE, 10, 0.8), _group(EXPLOSIVE, 3, 1.2)]))
	# V3
	waves.append(_wave([_group(SIMPLE, 8, 0.7), _group(TANK, 3, 2.0)]))
	# V4
	waves.append(_wave([_group(EXPLOSIVE, 6, 1.0), _group(TANK, 3, 2.2)]))
	# V5 — finale + MiniBoss
	waves.append(_wave([_group(SIMPLE, 10, 0.6), _group(TANK, 4, 1.8)], MINIBOSS))
	return waves
