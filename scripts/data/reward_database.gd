extends Node
## Base des récompenses proposées entre deux vagues (autoload "RewardDB").
##
## ── POURQUOI CE FICHIER A ÉTÉ RÉÉCRIT ────────────────────────────────────
## Il ne servait que des BONUS : des stats passives (+10 % de dégâts, +1 cap
## par vague). Ces bonus changent COMBIEN on tape, jamais COMMENT on joue —
## exactement le type de récompense que BTD6 a relégué en méta-progression
## parce qu'elle n'excite personne en cours de partie.
##
## Pire : les récompenses de type CARD étaient explicitement filtrées. Le deck
## du joueur était donc figé du début à la fin, ce qui privait le jeu de toute
## découverte. Un deck qui ne devient rien n'est pas un deck, c'est un
## distributeur.
##
## Désormais chaque offre contient des CARTES, choisies pour être utiles sur le
## niveau en cours.

var rewards: Array[RewardData] = []
var taken: Array[RewardData] = []

## Toutes les cartes jouables du jeu, chargées depuis resources/cards.
var card_pool: Array[CardData] = []


func _ready():
	load_rewards()


func reset_taken():
	taken.clear()


func mark_taken(reward: RewardData):
	taken.append(reward)


func load_rewards():
	rewards.clear()
	card_pool.clear()
	_load_bonuses()
	_load_cards()


## Les bonus : une source de vérité unique, les fichiers de resources/bonuses.
func _load_bonuses() -> void:
	for path in _list_tres("res://resources/bonuses"):
		var bonus = load(path)
		if bonus is BonusData:
			var rd := RewardData.new()
			rd.reward_type = RewardData.RewardType.BONUS
			rd.title = bonus.title
			rd.description = bonus.description
			rd.icon = bonus.icon
			rd.bonus_data = bonus
			rewards.append(rd)


## Charge les cartes, en NE gardant que celles débloquées par la progression.
## Le pool de récompenses grandit donc de partie en partie — c'est la promesse
## qui donne envie d'aller au niveau suivant.
func _load_cards() -> void:
	for path in _list_tres("res://resources/cards"):
		var card = load(path)
		if card is CardData and Progress.is_card_unlocked(path.get_file().get_basename()):
			card_pool.append(card)


func _list_tres(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Dossier introuvable : " + dir_path)
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".tres"):
			out.append(dir_path + "/" + f)
		f = dir.get_next()
	dir.list_dir_end()
	return out


# ══════════════════════════════════════════════════════
#                    L'OFFRE
# ══════════════════════════════════════════════════════
#
# Composition VOULUE d'une offre de 3 :
#   • 1 carte qui PAIE sur ce niveau (son élément est un élément clé)
#   • 1 carte de l'autre type (sort si la première est une tour, et inverse)
#   • 1 bonus
#
# Cette règle garantit trois choses : il y a toujours quelque chose d'utile,
# il y a toujours un vrai choix entre « étoffer mon deck » et « renforcer ce
# que j'ai », et on ne propose jamais trois fois la même chose.

## Noms des cartes que le joueur possède, LUS EN DIRECT dans son deck.
##
## C'était une liste maintenue à la main — et elle s'est désynchronisée dès que
## les cartes ont été dupliquées au démarrage : les copies du deck n'étant pas
## les mêmes objets que celles du pool, AUCUNE carte n'était jamais reconnue
## comme possédée et le bonus de découverte s'appliquait à tout, tout le temps.
## Un état dérivé ne peut pas se désynchroniser.
func _owned_names() -> Dictionary:
	var out := {}
	var cm := _card_manager()
	if cm == null:
		return out
	for c in cm.all_cards():
		if c != null:
			# Une carte ★ garde le nom de sa base : on ne veut pas reproposer
			# la version normale de ce qu'on a déjà amélioré.
			out[c.card_name.replace(" ★", "")] = true
	return out



func get_random_rewards(count: int, level_id: int = -1) -> Array[RewardData]:
	var result: Array[RewardData] = []
	var key_elements := _key_elements_of(level_id)

	# 1) Une carte pertinente sur ce niveau.
	var first := _pick_card(key_elements, [], true)
	if first:
		result.append(_wrap_card(first))

	# 2) Une carte de l'AUTRE type — sans ça une offre peut être « 2 tours »,
	#    et le joueur qui manque de sorts n'en verra jamais.
	if first:
		var other_type := (
			CardData.CardType.SPELL if first.card_type == CardData.CardType.TOWER
			else CardData.CardType.TOWER
		)
		var second := _pick_card(key_elements, [first], false, other_type)
		if second:
			result.append(_wrap_card(second))

	# 3) Le CONTREPOINT : améliorer plutôt qu'ajouter.
	#    C'est la seule récompense qui rend le deck meilleur SANS l'alourdir —
	#    donc la seule qui reste intéressante quand le deck a déjà 18 cartes.
	# Une fois sur quatre, on propose une ÉPURATION plutôt qu'une amélioration.
	# Rarement, car un joueur qui épure à chaque offre finit avec un deck de
	# 6 cartes : plus de hasard, plus de deckbuilding, juste un combo répété.
	var contrepoint: RewardData = null
	if randf() < 0.25:
		contrepoint = _pick_removal()
	if contrepoint == null:
		contrepoint = _pick_upgrade()
	if contrepoint:
		result.append(contrepoint)

	# 4) Compléter avec des bonus non encore pris.
	var pool: Array[RewardData] = []
	for r in rewards:
		if r.reward_type == RewardData.RewardType.BONUS and not r in taken:
			pool.append(r)
	while result.size() < count and pool.size() > 0:
		result.append(pool.pop_at(randi() % pool.size()))

	# Filet : si les bonus sont épuisés, on complète en cartes.
	while result.size() < count:
		var extra := _pick_card(key_elements, [], false)
		if extra == null:
			break
		result.append(_wrap_card(extra))

	return result


## Tire une carte, en favorisant celles qui PAIENT sur le niveau et celles que
## le joueur ne possède pas encore.
func _pick_card(
	key_elements: Dictionary,
	exclude: Array,
	prefer_key: bool,
	force_type: int = -1
) -> CardData:
	var weighted: Array[CardData] = []
	var owned := _owned_names()

	for card in card_pool:
		if card in exclude:
			continue
		if force_type >= 0 and card.card_type != force_type:
			continue

		# Poids 1 = tirage normal ; on empile la carte pour augmenter sa chance.
		var weight := 2
		var element := _card_element(card)
		if prefer_key and key_elements.has(element):
			weight += 4          # elle est efficace ICI
		if not owned.has(card.card_name):
			weight += 3          # découverte : une carte neuve vaut mieux
		for _i in weight:
			weighted.append(card)

	if weighted.is_empty():
		return null
	return weighted[randi() % weighted.size()]


## Propose d'améliorer une carte que le joueur POSSÈDE et qui ne l'est pas déjà.
##
## On nomme la carte dans l'offre plutôt que d'ouvrir un sélecteur : le choix se
## fait alors parmi les trois propositions, comme n'importe quelle récompense.
## Même décision pour le joueur, aucune interface supplémentaire.
func _pick_upgrade() -> RewardData:
	var cm := _card_manager()
	if cm == null:
		return null

	var candidates: Array[CardData] = []
	for c in cm.all_cards():
		if c != null and not c.upgraded and not c in candidates:
			candidates.append(c)
	if candidates.is_empty():
		return null

	var card: CardData = candidates[randi() % candidates.size()]
	var rd := RewardData.new()
	rd.reward_type = RewardData.RewardType.CARD_UPGRADE
	rd.title = "%s ★" % card.card_name
	rd.description = _upgrade_blurb(card)
	rd.icon = card.card_texture
	rd.card_data = card
	return rd


## Propose de RETIRER une carte du deck.
##
## Ne se propose qu'au-dessus d'une certaine taille de deck : épurer un deck de
## 10 cartes le rendrait fragile au lieu de le concentrer.
const REMOVAL_MIN_DECK := 12

func _pick_removal() -> RewardData:
	var cm := _card_manager()
	if cm == null:
		return null

	var deck: Array = cm.all_cards()
	if deck.size() < REMOVAL_MIN_DECK:
		return null

	# On propose de retirer une carte que le joueur possède EN PLUSIEURS
	# exemplaires en priorité : c'est là que l'épuration a le plus de valeur, et
	# ça évite de lui proposer de jeter sa seule tour de dégâts.
	var counts := {}
	for c in deck:
		counts[c.card_name] = counts.get(c.card_name, 0) + 1

	var best: CardData = null
	var best_count := 0
	for c in deck:
		var n: int = counts[c.card_name]
		if n > best_count:
			best_count = n
			best = c
	if best == null or best_count < 2:
		return null

	var rd := RewardData.new()
	rd.reward_type = RewardData.RewardType.CARD_REMOVE
	rd.title = "Retirer : %s" % best.card_name
	rd.description = "ÉPURATION — Retire définitivement une copie de cette carte (tu en as %d). Un deck plus court pioche plus souvent ce qui compte." % best_count
	rd.card_data = best
	return rd


func _card_manager() -> CardManager:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene.get("card_manager") as CardManager


## Décrit ce que l'amélioration va faire, en termes concrets.
## Une récompense qu'on ne comprend pas n'est pas un choix.
func _upgrade_blurb(card: CardData) -> String:
	match card.card_type:
		CardData.CardType.TOWER:
			return "AMÉLIORE cette carte : les tours posées tapent +35 %%, tirent plus vite, portent plus loin, et leur Charge part en %d tirs de moins." % card.up_charge_bonus
		CardData.CardType.SPELL:
			return "AMÉLIORE cette carte : +25 % de rayon, +50 % de dégâts, +40 % de durée."
		CardData.CardType.UPGRADE:
			return "AMÉLIORE cette carte : elle devient GRATUITE."
		_:
			return "AMÉLIORE cette carte : effets et revenus augmentés de moitié."


func _wrap_card(card: CardData) -> RewardData:
	var rd := RewardData.new()
	rd.reward_type = RewardData.RewardType.CARD
	rd.title = card.card_name
	rd.description = card.description
	rd.icon = card.card_texture
	rd.card_data = card
	return rd


func _key_elements_of(level_id: int) -> Dictionary:
	var out := {}
	if level_id < 0:
		return out
	for k in WaveLibrary.get_key_elements(level_id):
		out[k["element"]] = true
	return out


## Élément d'une carte, qu'elle pose une tour ou lance un sort.
func _card_element(card: CardData) -> ElementType.Type:
	if card.spell_data != null:
		return card.spell_data.element
	if card.tower_scene == null:
		return ElementType.Type.NONE
	var probe = card.tower_scene.instantiate()
	var element: ElementType.Type = ElementType.Type.NONE
	if probe is BaseTower:
		element = probe.element_type
	probe.free()
	return element
