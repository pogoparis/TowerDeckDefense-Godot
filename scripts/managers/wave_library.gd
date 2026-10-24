class_name WaveLibrary
## Construit les listes de vagues par niveau, en code (plus simple à tuner que
## des .tres).
##
## ── STRUCTURE ────────────────────────────────────────────────────────────
## ENEMIES est le CATALOGUE : tous les types d'ennemis du jeu, avec leur scène
## et leur rythme de spawn propre. Chaque niveau déclare ensuite un ROSTER —
## le sous-ensemble qu'il convoque — et ses vagues sont des lignes de compteurs
## qui suivent l'ordre de ce roster.
##
## Pourquoi pas un tableau à colonnes fixes : avec 10 ou 15 types d'ennemis,
## chaque niveau traînerait une ligne de zéros sur toute la largeur du
## catalogue, et une erreur de colonne serait invisible à la relecture. Ici un
## niveau ne mentionne QUE ce qu'il utilise, et _validate_level() refuse un plan
## dont les lignes ne correspondent pas à son roster.
##
## ── ÉQUILIBRAGE ──────────────────────────────────────────────────────────
## PV unitaires : Pillard 40 · Kamikazé 70 · Tank 220 · Drone 130 · MiniBoss 900.
## Les PV montent aussi par vague (wave_manager.enemy_hp_growth), donc les
## effectifs tardifs restent modérés : fin de partie = ennemis PEU NOMBREUX mais
## TRÈS coriaces, plutôt qu'une nuée qui fond (modèle BTD6).
##
## ── IDENTITÉ DE MENACE ───────────────────────────────────────────────────
## Chaque niveau a une composition PROPRE. C'est ce qui donne un sens au choix
## de deck : avec la même liste de vagues partout, le briefing élémentaire
## décorerait un choix qui n'existe pas. Un deck doit être un BON choix quelque
## part et un MAUVAIS ailleurs.
##
## Ajouter un ennemi au jeu = une entrée dans ENEMIES + son id dans le roster
## des niveaux concernés. Tout le reste (briefing, part des PV, élément clé,
## couverture des decks) en découle automatiquement.

const SIMPLE := preload("res://scenes/enemies/SimpleMob.tscn")
const TANK := preload("res://scenes/enemies/TankMob.tscn")
const EXPLOSIVE := preload("res://scenes/enemies/ExplosiveMob.tscn")
const MINIBOSS := preload("res://scenes/enemies/MiniBoss.tscn")
const DRONE := preload("res://scenes/enemies/DroneMob.tscn")
const DRONE_PUNK := preload("res://scenes/enemies/DronePunkMob.tscn")
const FOURNAISE := preload("res://scenes/enemies/FurnaceDrone.tscn")
const ZEPPELIN := preload("res://scenes/enemies/Zeppelin.tscn")
const REPARATEUR := preload("res://scenes/enemies/Repairer.tscn")
const FANTOME := preload("res://scenes/enemies/PhantomDrone.tscn")


## CATALOGUE des ennemis.
##   scene   : la scène à instancier.
##   name    : nom affiché dans le briefing d'avant-partie.
##   rythme  : décalage appliqué à l'intervalle de spawn de la vague. Positif =
##             ce type arrive plus espacé (les tanks se traînent), négatif =
##             plus serré (l'escadrille de drones traverse en rafale).
##   boss    : entrée en scène différée et bannière "MINIBOSS !".
const ENEMIES := {
	"pillard":  { "scene": SIMPLE,    "name": "Pillard",     "rythme":  0.00 },
	"kamikaze": { "scene": EXPLOSIVE, "name": "Kamikazé",    "rythme":  0.25 },
	"tank":     { "scene": TANK,      "name": "Tank",        "rythme":  0.70 },
	# ⚠ rythme POSITIF depuis l'équilibrage : à -0.35 les drones sortaient
	# toutes les 0,30 s (le plancher), soit un mur de 12 drones en 3,6 s
	# qu'aucune ligne de tours ne peut mâcher. Un ennemi rapide n'a pas besoin
	# d'arriver serré : sa vitesse est déjà sa pression.
	"drone":    { "scene": DRONE,     "name": "Drone Jaune", "rythme":  0.15 },
	# Lourd et lent : il arrive TRÈS espacé, chacun est un évènement à traiter.
	"dronepunk":{ "scene": DRONE_PUNK,"name": "Drone Punk",  "rythme":  1.60 },
	# Il ACCÉLÈRE en avançant : le laisser entrer serré n'aurait aucun sens,
	# sa pression monte déjà toute seule.
	"fournaise":{ "scene": FOURNAISE, "name": "Drone Fournaise", "rythme": 0.80, "speed_mult": 1.6 },
	# Gros et lent, sans blindage : chacun est un évènement, pas une rafale.
	"zeppelin": { "scene": ZEPPELIN, "name": "Zeppelin", "rythme": 1.20 },
	# Il DOIT arriver dans le paquet : un soigneur isolé ne soigne personne et
	# devient une cible gratuite. C'est le seul mob dont le rythme serré est
	# une décision de design et pas un réglage de pression.
	"reparateur":{ "scene": REPARATEUR, "name": "Réparateur", "rythme": -0.10 },
	# Rapide et camouflé : sa pression vient de sa vitesse et de son immunité
	# partielle, jamais du nombre. Le grouper en rafale le rendrait injouable
	# sans Lumière — exactement l'erreur du mur de Drones Jaunes.
	"fantome":  { "scene": FANTOME,  "name": "Drone Fantôme", "rythme": 0.30 },
	"miniboss": { "scene": MINIBOSS,  "name": "MiniBoss",    "rythme":  0.00, "boss": true },
}


## LES NIVEAUX.
##   roster : les types convoqués, dans l'ordre des colonnes de `waves`.
##   waves  : une ligne par vague = [compteurs…, intervalle de spawn].
##            Il doit y avoir exactement roster.size() + 1 valeurs par ligne.
const LEVELS := {
	# ── NIVEAU 2 — LA CASSE : le niveau des BLINDÉS ──────────────────────
	# Tanks omniprésents (49 % des PV), drones anecdotiques. Récompense la
	# Terre (×2 sur Tank), punit le Feu (résisté par le Tank). Niveau "Roche".
	2: {
		"title": "LA CASSE AUX TANKS",
		"pitch": "Un mur de blindés. Ce qui brûle glisse ; ce qui écrase passe.",
		"roster": ["pillard", "kamikaze", "tank", "drone", "dronepunk", "miniboss"],
		"waves": [
			[ 6,  0,  0,  0, 0, 0, 1.20],   # V1  — intro tranquille
			[ 9,  0,  0,  0, 0, 0, 1.05],   # V2
			[ 8,  3,  0,  0, 0, 0, 1.00],   # V3  — les kamikazés arrivent
			[ 8,  0,  2,  0, 0, 0, 0.95],   # V4  — PREMIERS TANKS
			[ 6,  0,  4,  0, 0, 0, 0.90],   # V5  — mur de tanks
			[ 6,  4,  4,  1, 0, 0, 0.85],   # V6  — un drone éclaireur
			[ 8,  0,  6,  1, 0, 0, 0.80],   # V7  — la casse se referme
			[ 5,  6,  7,  2, 1, 0, 0.75],   # V8  — PREMIER DRONE PUNK
			[10,  3,  7,  2, 1, 1, 0.70],   # V9  — PREMIER MINIBOSS
			[ 6,  6,  9,  3, 2, 1, 0.65],   # V10
			[10,  4, 11,  3, 2, 2, 0.60],   # V11 — ça pique
			[10,  7, 12,  4, 3, 3, 0.55],   # V12 — FINALE
		],
	},

	# ── NIVEAU 3 — LE NID : le niveau de la VITESSE ──────────────────────
	# Nuées de drones et de kamikazés, tanks rares. Récompense l'Électricité
	# (×2 sur Drone) et le Feu (×2 sur Kamikazé).
	#
	# ⚠ EFFECTIFS RÉDUITS D'UN TIERS par rapport au premier jet. La VITESSE est
	# un multiplicateur de difficulté caché : un drone à 195 px/s passe trois
	# fois moins de temps sous le feu qu'un tank à 60. À PV égaux, le Nid
	# demandait donc 1.47× plus de DPS que La Casse — et devenait infaisable
	# dès la vague 4. Compter les PV ne suffit pas, il faut compter PV × vitesse.
	3: {
		"title": "LE NID DE DRONES",
		"pitch": "Une nuée rapide et blindée. Le sol ne rattrape pas ce qui vole.",
		"roster": ["pillard", "kamikaze", "tank", "drone", "dronepunk", "miniboss"],
		"waves": [
			[ 7,  0,  0,  0, 0, 0, 1.10],   # V1
			[ 8,  2,  0,  0, 0, 0, 0.95],   # V2
			[ 6,  5,  0,  0, 0, 0, 0.90],   # V3  — les kamikazés s'installent
			[ 8,  3,  0,  2, 0, 0, 0.85],   # V4  — PREMIERS DRONES
			[ 6,  5,  1,  3, 0, 0, 0.80],   # V5
			[ 8,  5,  1,  4, 0, 0, 0.75],   # V6
			[ 5,  7,  2,  4, 1, 0, 0.70],   # V7  — PREMIER DRONE PUNK
			[ 8,  6,  2,  7, 1, 0, 0.65],   # V8  — escadrille
			[ 6,  9,  3,  7, 1, 1, 0.60],   # V9  — PREMIER MINIBOSS
			[10,  8,  3,  9, 1, 1, 0.55],   # V10
			[ 8, 11,  4, 10, 2, 2, 0.50],   # V11
			[12, 11,  4, 12, 2, 3, 0.45],   # V12 — FINALE
		],
	},

	# ── NIVEAU 4 — LA FONDERIE : le niveau de la CHALEUR ─────────────────
	# Bâti autour du Drone Fournaise, qui accélère tout seul. La Glace est la
	# seule chose qui le refroidit — c'est le premier niveau où ❄ est
	# l'élément clé, et donc le premier où le Pingouin Punk est indispensable.
	#
	# Sa difficulté n'est pas la masse de PV mais le TEMPO : si on ne refroidit
	# pas, la vague entière finit par traverser plus vite que les tours ne
	# tirent. Les effectifs restent donc modestes.
	4: {
		"title": "LA FONDERIE",
		"pitch": "Tout s'emballe. Ce qui n'est pas refroidi finit par passer.",
		# Le Drone Jaune (faible ⚡) n'est pas décoratif : sans lui, le deck Orage
		# ne mordait sur RIEN ici — 0 % de couverture. Un deck qui n'a aucune
		# prise n'est pas un choix moins bon, c'est un piège. Il garde une part
		# volontairement inférieure à la Glace : Orage reste jouable, Roche reste
		# la bonne réponse.
		"roster": ["pillard", "kamikaze", "tank", "drone", "fournaise", "dronepunk", "miniboss"],
		"waves": [
			[8,  0, 0, 0,  0, 0, 0, 1.10],   # V1
			[9,  3, 0, 0,  0, 0, 0, 1.00],   # V2
			[7,  4, 1, 0,  1, 0, 0, 0.95],   # V3  — PREMIÈRE FOURNAISE
			[6,  4, 1, 3,  2, 0, 0, 0.90],   # V4  — PREMIERS DRONES JAUNES
			[5,  5, 2, 4,  3, 0, 0, 0.85],   # V5
			[6,  4, 2, 5,  4, 0, 0, 0.80],   # V6  — la chaleur monte
			[4,  6, 3, 5,  5, 1, 0, 0.75],   # V7  — PREMIER DRONE PUNK
			[6,  5, 3, 6,  6, 1, 0, 0.70],   # V8
			[4,  7, 4, 6,  7, 1, 1, 0.65],   # V9  — PREMIER MINIBOSS
			[5,  6, 4, 6,  9, 2, 1, 0.60],   # V10
			[5,  8, 5, 6, 10, 2, 2, 0.55],   # V11
			[5,  8, 5, 7, 13, 3, 3, 0.50],   # V12 — FINALE
		],
	},

	# ── NIVEAU 5 — LE CIEL DE FERRAILLE ──────────────────────────────────
	# Le niveau des TROIS derniers éléments orphelins. Air, Nature et Lumière
	# n'étaient la faiblesse de personne : ils ne pouvaient donc jamais être
	# l'élément clé d'un niveau, et un tiers des cartes ne brillait nulle part.
	#
	# Chacun des trois nouveaux mobs porte l'un d'eux, et aucun ne domine :
	# c'est le premier niveau à trois éléments clés, donc le premier où aucun
	# deck préconstruit ne répond à tout. Le joueur doit choisir ce qu'il
	# accepte de mal gérer — c'est l'examen de fin de V1.
	#
	# Le Réparateur arrive tôt et change la question posée : ce n'est plus
	# « as-tu assez de dégâts ? » mais « sais-tu où frapper en premier ? ».
	5: {
		"title": "LE CIEL DE FERRAILLE",
		"pitch": "Trois menaces, trois réponses. Aucun deck ne couvre tout.",
		# ⚠ PAS DE KAMIKAZÉ ICI, et c'est le point de tout le niveau.
		# Avec lui au roster il pesait 27,5 % à lui seul : le Feu devenait le
		# SEUL élément clé, et le niveau censé faire briller Air, Nature et
		# Lumière se lisait « niveau de Feu ». Un mob de remplissage ne doit
		# jamais porter l'identité d'un niveau.
		"roster": ["pillard", "reparateur", "fantome", "zeppelin", "dronepunk", "miniboss"],
		"waves": [
			[9, 0,  0,  0, 0, 0, 1.05],   # V1
			[8, 2,  0,  0, 0, 0, 0.95],   # V2  — PREMIER RÉPARATEUR
			[7, 2,  3,  0, 0, 0, 0.90],   # V3  — PREMIERS FANTÔMES
			[6, 3,  4,  2, 0, 0, 0.85],   # V4  — PREMIER ZEPPELIN
			[5, 3,  5,  3, 0, 0, 0.80],   # V5
			[5, 4,  5,  3, 0, 0, 0.75],   # V6
			[4, 4,  6,  4, 1, 0, 0.70],   # V7  — PREMIER DRONE PUNK
			[4, 4,  6,  4, 1, 0, 0.65],   # V8
			[4, 5,  7,  5, 1, 1, 0.60],   # V9  — PREMIER MINIBOSS
			[3, 5,  8,  6, 1, 1, 0.55],   # V10
			[2, 5,  9,  8, 1, 2, 0.50],   # V11
			[0, 5, 12, 11, 2, 2, 0.45],   # V12 — FINALE
		],
	},
}


## Part des PV du niveau en dessous de laquelle un élément n'est pas annoncé
## comme "clé". Même unité que [method get_deck_coverage] : le joueur doit
## pouvoir rapprocher "ÉLÉMENT CLÉ : Terre" et "ce deck répond à 49 %".
const KEY_ELEMENT_MIN_SHARE := 0.25


## Cache des stats lues sur les scènes d'ennemis. Le briefing appelle plusieurs
## fois get_threat_roster() par écran (roster, couverture de chaque deck,
## élément clé, pin de la carte) : sans ça on instancierait une scène complète
## à chaque fois, juste pour lire deux entiers.
static var _stats_cache := {}


## PV et faiblesse d'un type d'ennemi, lus sur sa scène — jamais recopiés, donc
## un rééquilibrage met à jour le briefing tout seul.
static func _enemy_stats(id: String) -> Dictionary:
	if _stats_cache.has(id):
		return _stats_cache[id]

	var stats := { "hp": 0, "speed": 100.0, "weak": ElementType.Type.NONE }
	var entry: Dictionary = ENEMIES.get(id, {})
	if entry.has("scene"):
		var probe = entry["scene"].instantiate()
		if probe is EnemyBase:
			stats["hp"] = probe.max_hp
			stats["speed"] = probe.speed
			stats["weak"] = probe.weak_to
		probe.free()

	# Certains mobs ne gardent pas leur vitesse de base : la Fournaise
	# accélère jusqu'au double. On corrige avec la vitesse MOYENNE réelle,
	# sinon le catalogue la sous-estime de moitié.
	stats["speed"] *= float(entry.get("speed_mult", 1.0))

	_stats_cache[id] = stats
	return stats


## Poids réel d'un groupe d'ennemis dans la difficulté d'un niveau.
##
## ── POURQUOI PAS SIMPLEMENT LES PV ───────────────────────────────────────
## Une tour ne dispose pas d'un temps illimité : un ennemi reste sous son feu
## pendant 2 × portée ÷ vitesse. Doubler la vitesse d'un mob revient donc
## exactement à doubler ses PV du point de vue de la défense.
##
## Ne compter que les PV a déjà produit un niveau 3 mathématiquement
## impossible : les drones y étaient rapides, donc deux fois plus coûteux que
## le modèle ne le croyait. La vitesse n'est pas un détail de ressenti, c'est
## la moitié de l'équation.
##
## Normalisé sur 100 px/s pour que les nombres restent du même ordre qu'avant.
static func _threat_mass(count: int, id: String) -> int:
	var stats := _enemy_stats(id)
	return int(round(count * float(stats["hp"]) * float(stats["speed"]) / 100.0))


## Vérifie qu'un niveau est cohérent : ids connus, et lignes de vagues à la
## bonne longueur. Une colonne en trop ou en moins passerait sinon inaperçue et
## décalerait silencieusement TOUS les effectifs.
static func _validate_level(level_id: int, level: Dictionary) -> bool:
	var roster: Array = level.get("roster", [])
	if roster.is_empty():
		push_error("WaveLibrary : niveau %d sans roster." % level_id)
		return false

	for id in roster:
		if not ENEMIES.has(id):
			push_error("WaveLibrary : niveau %d — ennemi inconnu '%s'." % [level_id, id])
			return false

	var expected: int = roster.size() + 1   # compteurs + intervalle
	for i in level.get("waves", []).size():
		var row: Array = level["waves"][i]
		if row.size() != expected:
			push_error(
				"WaveLibrary : niveau %d, vague %d — %d valeurs au lieu de %d (roster %s + intervalle)."
				% [level_id, i + 1, row.size(), expected, str(roster)]
			)
			return false

	return true


## Retourne les vagues d'un niveau, ou [] si le niveau n'a pas de plan dédié
## (dans ce cas on garde celles définies dans la scène).
static func get_waves(level_id: int) -> Array[WaveData]:
	var level: Dictionary = LEVELS.get(level_id, {})
	if level.is_empty() or not _validate_level(level_id, level):
		return []

	var roster: Array = level["roster"]
	var waves: Array[WaveData] = []

	for row in level["waves"]:
		var interval: float = float(row[roster.size()])
		var groups: Array = []
		var boss_scene: PackedScene = null

		for col in roster.size():
			var count: int = int(row[col])
			if count <= 0:
				continue

			var enemy: Dictionary = ENEMIES[roster[col]]
			var rythme: float = float(enemy.get("rythme", 0.0))
			var scene: PackedScene = enemy["scene"]

			if enemy.get("boss", false):
				# Le premier boss entre en scène via boss_scene (entrée
				# dramatique différée) ; les suivants arrivent en groupe.
				boss_scene = scene
				if count > 1:
					groups.append(_group(scene, count - 1, 2.5))
			else:
				groups.append(_group(scene, count, maxf(0.3, interval + rythme)))

		waves.append(_wave(groups, boss_scene))

	return waves


## Titre et pitch du niveau, ou {} si le niveau n'en a pas.
static func get_threat_identity(level_id: int) -> Dictionary:
	var level: Dictionary = LEVELS.get(level_id, {})
	if level.is_empty():
		return {}
	return { "title": level.get("title", ""), "pitch": level.get("pitch", "") }


## Types d'ennemis présents dans le niveau :
## [{scene, name, total, mass, share}, …], trié par MASSE DE PV décroissante.
##
## Le tri par masse et non par effectif est délibéré. À La Casse, le Pillard est
## le plus NOMBREUX (×92) mais ne pèse que 13 % des PV, tandis que le Tank (×62)
## en pèse 49 %. Trier par effectif mettait en tête la menace la moins
## importante — et faisait paraître équivalentes des faiblesses qui ne le sont
## pas du tout.
static func get_threat_roster(level_id: int) -> Array:
	var level: Dictionary = LEVELS.get(level_id, {})
	if level.is_empty():
		return []

	var roster: Array = level["roster"]
	var totals := {}
	for row in level["waves"]:
		for col in roster.size():
			var id: String = roster[col]
			totals[id] = totals.get(id, 0) + int(row[col])

	var result := []
	var grand_total := 0
	for id in roster:
		var count: int = totals.get(id, 0)
		if count <= 0:
			continue
		var mass: int = _threat_mass(count, id)
		grand_total += mass
		result.append({
			"scene": ENEMIES[id]["scene"],
			"name": ENEMIES[id]["name"],
			"weak": _enemy_stats(id)["weak"],
			"total": count,
			"mass": mass,
		})

	for entry in result:
		entry["share"] = float(entry["mass"]) / float(grand_total) if grand_total > 0 else 0.0

	result.sort_custom(func(a, b): return a["mass"] > b["mass"])
	return result


## Part des PV du niveau que [param elements] frappe en double (0→1).
## C'est le chiffre qui tranche entre deux decks : "Roche répond à 49 % du
## niveau, Brasier à 16 %" est une information actionnable, là où plusieurs
## faiblesses alignées côte à côte se lisent comme équivalentes.
static func get_deck_coverage(level_id: int, elements: Dictionary) -> float:
	var covered := 0
	var total := 0

	for entry in get_threat_roster(level_id):
		total += int(entry["mass"])
		var weak: ElementType.Type = entry["weak"]
		if weak != ElementType.Type.NONE and elements.has(weak):
			covered += int(entry["mass"])

	return float(covered) / float(total) if total > 0 else 0.0


## Éléments qui PAIENT vraiment sur ce niveau : [{element, weight, share}, …].
##
## Lister les faiblesses ne suffit pas : si le joueur lit "Terre, Feu, Élec"
## il n'apprend rien — chaque deck coche une case et le choix s'évapore. Ce qui
## décide, c'est la MASSE DE PV derrière chaque faiblesse : 62 Tanks à 220 PV
## pèsent bien plus que 33 Kamikazés à 70. On ne retient donc que ce qui dépasse
## KEY_ELEMENT_MIN_SHARE.
static func get_key_elements(level_id: int) -> Array:
	var weights := {}
	var total := 0

	for entry in get_threat_roster(level_id):
		var mass: int = int(entry["mass"])
		total += mass
		var weak: ElementType.Type = entry["weak"]
		if weak != ElementType.Type.NONE:
			weights[weak] = weights.get(weak, 0) + mass

	if total <= 0:
		return []

	var result := []
	for element in weights:
		var share := float(weights[element]) / float(total)
		if share < KEY_ELEMENT_MIN_SHARE:
			continue
		result.append({ "element": element, "weight": weights[element], "share": share })

	result.sort_custom(func(a, b): return a["weight"] > b["weight"])
	return result


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
