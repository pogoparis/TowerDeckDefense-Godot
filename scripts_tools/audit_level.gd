extends Node
## Audit d'un niveau : menace réelle, éléments clés, couverture de chaque deck.
##
## ── POURQUOI CET OUTIL EXISTE ─────────────────────────────────────────────
## La difficulté d'un niveau n'est PAS la somme de ses PV : c'est PV × vitesse,
## parce qu'un ennemi rapide passe moins de temps sous le feu des tours.
## Estimer ça de tête a déjà produit un niveau 3 mathématiquement impossible
## (« impossible de passer le niveau 3 avec 2 panda »). On ne recommence pas :
## tout nouveau niveau passe par ici avant d'être jouable.
##
## ── POURQUOI UNE SCÈNE ET PAS --script ───────────────────────────────────
## Le mode --script démarre un SceneTree nu, SANS les autoloads. enemy_base.gd
## référence RunBonuses, donc il ne compile pas, donc toutes les sondes
## renvoient 0 PV — l'audit affichait des effectifs nuls sans le dire.
##
##     Godot --headless --path . scenes/tools/AuditLevel.tscn -- 4
## Sans argument, audite tous les niveaux.

func _ready() -> void:
	var ids: Array = []
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			ids.append(a.to_int())
	if ids.is_empty():
		ids = WaveLibrary.LEVELS.keys()
		ids.sort()

	for id in ids:
		_audit(id)
	_orphelins()
	get_tree().quit()


## Mobs présents au catalogue mais convoqués par AUCUN niveau.
##
## Un ennemi qu'on a écrit, réglé et dessiné mais que personne ne rencontre est
## du contenu mort — et rien dans le code ne le signale : il compile, il
## s'instancie, il ne manque à personne. Le seul moment où ça se voit, c'est en
## croisant le catalogue avec les rosters, donc ici.
func _orphelins() -> void:
	var vus := {}
	for level_id in WaveLibrary.LEVELS:
		for id in WaveLibrary.LEVELS[level_id].get("roster", []):
			vus[id] = vus.get(id, [])
			vus[id].append(level_id)

	print("
════════════════════════════════════════════════════════════")
	print("COUVERTURE DU CATALOGUE")
	print("════════════════════════════════════════════════════════════")
	var manquants := 0
	for id in WaveLibrary.ENEMIES:
		if vus.has(id):
			var niveaux: Array = vus[id]
			niveaux.sort()
			print("  %-12s niveaux %s" % [id, str(niveaux)])
		else:
			manquants += 1
			print("  %-12s ⚠ AUCUN NIVEAU — contenu mort" % id)
	if manquants == 0:
		print("
  Tous les ennemis du catalogue sont jouables.")


func _audit(level_id: int) -> void:
	var level: Dictionary = WaveLibrary.LEVELS.get(level_id, {})
	if level.is_empty():
		print("Niveau %d : inexistant." % level_id)
		return

	print("\n════════════════════════════════════════════════════════════")
	print("NIVEAU %d — %s" % [level_id, level["title"]])
	print("  « %s »" % level["pitch"])
	print("════════════════════════════════════════════════════════════")

	print("\nMENACE (part de la difficulté réelle, PV × vitesse) :")
	for e in WaveLibrary.get_threat_roster(level_id):
		print("  %-16s ×%-5d %5.1f %%   faible : %s"
			% [e["name"], e["total"], e["share"] * 100.0,
			   ElementType.label(e["weak"])])

	print("\nÉLÉMENTS CLÉS (seuil %d %%) :" % int(WaveLibrary.KEY_ELEMENT_MIN_SHARE * 100.0))
	var keys: Array = WaveLibrary.get_key_elements(level_id)
	if keys.is_empty():
		print("  AUCUN — le niveau ne récompense aucun deck en particulier,")
		print("  donc le choix du deck n'y est pas une décision.")
	for k in keys:
		print("  %s %-12s %5.1f %% de la menace"
			% [ElementType.icon(k["element"]), ElementType.label(k["element"]),
			   k["share"] * 100.0])

	_deck_coverage(level_id)
	_curve(level_id, level)


## Ce que chaque deck préconstruit répond réellement sur ce niveau.
## Un niveau où tous les decks couvrent pareil est un niveau sans choix.
func _deck_coverage(level_id: int) -> void:
	if not ClassDB.class_exists("RefCounted"):
		return
	var decks = _load_decks()
	if decks.is_empty():
		return
	print("\nCOUVERTURE DES DECKS :")
	for d in decks:
		var elements := {}
		for c in d["elements"]:
			elements[c] = true
		var cov: float = WaveLibrary.get_deck_coverage(level_id, elements)
		var verdict := "faible"
		if cov >= 0.45:
			verdict = "FORT"
		elif cov >= 0.25:
			verdict = "correct"
		print("  %-22s %5.1f %%   %s" % [d["name"], cov * 100.0, verdict])


func _curve(level_id: int, level: Dictionary) -> void:
	var roster: Array = level["roster"]
	print("\nCOURBE : %s" % str(roster))
	var prev := 0
	for i in level["waves"].size():
		var row: Array = level["waves"][i]
		var total := 0
		var mass := 0
		for c in roster.size():
			total += int(row[c])
			mass += WaveLibrary._threat_mass(int(row[c]), roster[c])
		var jump := ""
		if prev > 0 and mass > prev * 2:
			jump = "  ⚠ MASSE ×%.1f" % (float(mass) / float(prev))
		prev = mass
		print("  V%-3d %-26s eff %-4d  menace %-7d  int %.2fs%s"
			% [i + 1, str(row.slice(0, roster.size())), total, mass,
			   float(row[roster.size()]), jump])


## Decks préconstruits, lus là où ils sont réellement définis.
func _load_decks() -> Array:
	var out := []
	var dir := DirAccess.open("res://resources/decks")
	if dir == null:
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".tres"):
			var deck = load("res://resources/decks/" + f)
			if deck != null:
				out.append({
					"name": deck.get("deck_name") if deck.get("deck_name") else f,
					"elements": _deck_elements(deck),
				})
		f = dir.get_next()
	dir.list_dir_end()
	return out


func _deck_elements(deck) -> Array:
	var els := []
	var cards = deck.get("cards")
	if cards == null:
		return els
	for card in cards:
		if card == null:
			continue
		var e: int = ElementType.Type.NONE
		if card.get("spell_data") != null:
			e = card.spell_data.element
		elif card.get("tower_scene") != null:
			var probe = card.tower_scene.instantiate()
			if probe is BaseTower:
				e = probe.element_type
			probe.free()
		if e != ElementType.Type.NONE and not e in els:
			els.append(e)
	return els
