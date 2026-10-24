class_name DeckSelect
extends Control
## Écran de choix de deck — s'intercale entre la carte du monde et le niveau.
##
## Chaque deck raconte une stratégie lisible : le joueur voit les cartes qu'il
## embarque AVANT de se lancer, ce qui fait du choix de deck une vraie décision
## de run (et non un réglage caché).
##
## Le style vient du thème junkriot ; ce script ne fait que construire la liste.

## Decks proposés au joueur.
## Les 9 éléments se répartissent en 3 rôles (dégâts / contrôle / amplificateur)
## et les 3 decks en font une partition : chacun prend 3 éléments et possède au
## moins une réaction native. Aucun deck ne peut tout faire — c'est la règle qui
## rend le choix signifiant.
const DECKS: Array[StartingDeckData] = [
	preload("res://resources/decks/deck_brasier.tres"),
	preload("res://resources/decks/deck_roche.tres"),
	preload("res://resources/decks/deck_orage.tres"),
]

## Une phrase qui résume la stratégie du deck (clé = deck_name).
const DECK_PITCH := {
	"Brasier": "Feu · Eau · Ombre — trempe, enflamme, amplifie. Réaction : VAPEUR.",
	"Roche": "Terre · Glace · Lumière — gèle, brise, renforce. Réaction : BRISURE.",
	"Orage": "Électricité · Air · Nature — repousse, empoisonne, foudroie. Réactions : DÉCHARGE, SPORES.",
}

## Le briefing est la MOITIÉ du système de faiblesses : si le joueur découvre
## les résistances en pleine vague, il subit son deck au lieu de le choisir.
## Ici il lit la menace du niveau QU'IL VIENT DE CHOISIR, puis décide.
##
## Tout vient de WaveLibrary (vagues et catalogue d'ennemis réels) et des scènes
## d'ennemis (faiblesses réelles) : aucune liste recopiée ici, donc ajouter un
## monstre au jeu suffit à le faire apparaître dans ce briefing.

@export_file("*.tscn") var map_scene_path: String = "res://scenes/ui/WorldMap.tscn"

@onready var deck_row: HBoxContainer = $Center/VBox/DeckRow
@onready var btn_back: Button = $Center/VBox/BtnBack
@onready var overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	overlay.color = Color(0, 0, 0, 1)
	btn_back.pressed.connect(_on_back_pressed)

	_build_threat_briefing()

	for deck in DECKS:
		if deck != null:
			deck_row.add_child(_build_deck_panel(deck))

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)


## Encart "menaces de ce niveau" : pour chaque type d'ennemi, son point faible
## et ce qui glisse sur lui. Inséré au-dessus de la rangée de decks.
func _build_threat_briefing() -> void:
	var parent := deck_row.get_parent()
	if parent == null:
		return

	var panel := PanelContainer.new()
	panel.name = "ThreatBriefing"

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	margin.add_child(vb)

	var identity: Dictionary = WaveLibrary.get_threat_identity(Progress.current_level_id)

	var title := Label.new()
	title.text = "⚠  %s" % identity.get("title", "CE QUI T'ATTEND")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vb.add_child(title)

	var pitch: String = identity.get("pitch", "")
	if pitch != "":
		var pitch_lbl := Label.new()
		pitch_lbl.text = pitch
		pitch_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pitch_lbl.add_theme_font_size_override("font_size", 18)
		pitch_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		vb.add_child(pitch_lbl)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	vb.add_child(row)

	var keys := WaveLibrary.get_key_elements(Progress.current_level_id)

	# Éléments réellement payants sur ce niveau. Sert à GRISER les faiblesses
	# marginales : "Kamikazé faible au Feu" est vrai, mais sur un niveau à 62
	# Tanks (qui résistent au Feu) c'est un détail. Affiché au même niveau
	# visuel que la faiblesse dominante, ça crée une hésitation injustifiée.
	var key_set := {}
	for k in keys:
		key_set[k["element"]] = true

	# Roster réel du niveau, du plus nombreux au plus rare : le joueur voit
	# d'abord ce qu'il va affronter le plus souvent.
	for entry in WaveLibrary.get_threat_roster(Progress.current_level_id):
		var line := _build_threat_line(entry, key_set)
		if line != null:
			row.add_child(line)

	# La CONCLUSION. Une liste de faiblesses ne décide rien ; le joueur a besoin
	# de savoir laquelle pèse. On n'affiche que ce qui compte vraiment.
	if not keys.is_empty():
		vb.add_child(_build_key_element_line(keys))

	parent.add_child(panel)
	parent.move_child(panel, deck_row.get_index())


## Une colonne du briefing, à partir d'une entrée de WaveLibrary.get_threat_roster.
## Les faiblesses viennent de la scène de l'ennemi : le briefing ne peut donc
## jamais mentir sur l'équilibrage réel, même après un retuning.
func _build_threat_line(entry: Dictionary, key_set: Dictionary) -> Control:
	var scene: PackedScene = entry["scene"]
	if scene == null:
		return null

	var total: int = int(entry["total"])
	var share: float = float(entry["share"])
	var weak: ElementType.Type = entry["weak"]

	# resists et armor ne sont pas dans le roster (le calcul de masse n'en a pas
	# besoin) : on les lit ici, une seule fois par type affiché.
	var probe := scene.instantiate()
	if not (probe is EnemyBase):
		probe.free()
		return null
	var resist: ElementType.Type = probe.resists
	var armored: bool = probe.armor > 0
	probe.free()

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)

	var name_lbl := Label.new()
	name_lbl.text = "%s  ×%d" % [entry["name"], total]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# La menace majeure est écrite plus gros : l'effectif seul induit en erreur
	# (92 Pillards pèsent moins que 62 Tanks).
	name_lbl.add_theme_font_size_override("font_size", 23 if share >= 0.30 else 19)
	vb.add_child(name_lbl)

	# Part des PV du niveau — la seule mesure qui compare des ennemis entre eux.
	vb.add_child(_affinity_label(
		"%d %% des PV" % int(round(share * 100.0)),
		Color(0.95, 0.85, 0.45) if share >= 0.30 else Color(0.55, 0.55, 0.6)
	))

	if weak != ElementType.Type.NONE:
		# En couleur pleine seulement si cet élément est payant sur CE niveau.
		# Sinon en gris : l'info reste consultable, mais elle ne tire plus l'œil
		# vers un deck qui perdrait la partie.
		var pays: bool = key_set.has(weak)
		vb.add_child(_affinity_label(
			"faible : %s %s" % [ElementType.icon(weak), ElementType.label(weak)],
			ElementType.color(weak) if pays else Color(0.45, 0.45, 0.5)
		))
	if resist != ElementType.Type.NONE:
		vb.add_child(_affinity_label(
			"résiste : %s %s" % [ElementType.icon(resist), ElementType.label(resist)],
			Color(0.62, 0.62, 0.68)
		))
	if armored:
		vb.add_child(_affinity_label("🛡 blindé", Color(0.85, 0.8, 0.6)))

	# Un mob sans aucune règle (le Pillard) : on le dit, plutôt que de laisser
	# un blanc que le joueur lirait comme une information manquante.
	if weak == ElementType.Type.NONE and resist == ElementType.Type.NONE and not armored:
		vb.add_child(_affinity_label("aucune faiblesse", Color(0.55, 0.55, 0.6)))

	return vb


## Bandeau "ÉLÉMENT CLÉ". Le filtrage est fait en amont par WaveLibrary (part
## des PV du niveau) : ici on se contente de hiérarchiser visuellement.
func _build_key_element_line(keys: Array) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)

	var intro := Label.new()
	intro.text = "ÉLÉMENT CLÉ :"
	intro.add_theme_font_size_override("font_size", 20)
	row.add_child(intro)

	var best: int = int(keys[0]["weight"])
	for k in keys:
		var weight: int = int(k["weight"])
		var element: ElementType.Type = k["element"]
		var lbl := Label.new()
		# Le plus lourd est écrit en grand : la hiérarchie doit se lire d'un
		# coup d'œil, sans comparer des nombres.
		var dominant := weight == best
		lbl.text = "%s %s" % [ElementType.icon(element), ElementType.label(element)]
		lbl.add_theme_font_size_override("font_size", 24 if dominant else 18)
		lbl.add_theme_color_override("font_color", ElementType.color(element))
		row.add_child(lbl)

	return row


func _affinity_label(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", color)
	return lbl


## Construit le panneau d'un deck : nom, pitch, aperçu des cartes, bouton.
func _build_deck_panel(deck: StartingDeckData) -> Control:
	# 3 cartes par ligne : avec 2 colonnes, un deck de 5-6 cartes uniques faisait
	# 3 rangées et l'écran débordait en hauteur. On échange de la hauteur (rare :
	# l'écran fait 1080) contre de la largeur (disponible : 1920).
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 7)
	margin.add_child(vb)

	var title := Label.new()
	title.text = deck.deck_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	vb.add_child(title)

	var pitch := Label.new()
	pitch.text = DECK_PITCH.get(deck.deck_name, "")
	pitch.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pitch.add_theme_font_size_override("font_size", 18)
	vb.add_child(pitch)

	# Éléments couverts par le deck, face à l'ÉLÉMENT CLÉ du niveau affiché
	# juste au-dessus : c'est la mise en correspondance qui rend le choix
	# évident. Sans elle, le joueur doit deviner quel deck porte quel élément.
	vb.add_child(_build_deck_elements_row(deck))
	vb.add_child(_build_coverage_label(deck))

	# Aperçu : une vignette par carte unique, avec son nombre d'exemplaires.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)

	for entry in _unique_cards(deck):
		grid.add_child(_build_card_preview(entry["card"], entry["count"]))

	var btn := Button.new()
	btn.text = "JOUER AVEC CE DECK"
	btn.custom_minimum_size = Vector2(0, 54)
	btn.pressed.connect(_on_deck_chosen.bind(deck))
	vb.add_child(btn)

	return panel


## Éléments présents dans le deck, lus sur les scènes de tours de ses cartes.
## Comme le reste du briefing : dérivé, jamais recopié. Changer l'élément d'une
## tour met cette ligne à jour toute seule.
## Verdict chiffré du deck contre CE niveau : la part des PV qu'il frappe en
## double. Sans lui, le joueur compare des LIGNES de faiblesse ("Brasier en
## couvre 2, Roche 1") et choisit à l'envers — alors qu'à La Casse la seule
## faiblesse de Roche pèse 49 % du niveau et les deux de Brasier 16 % à elles
## deux. Le nombre d'éléments couverts n'a jamais été la bonne mesure.
func _build_coverage_label(deck: StartingDeckData) -> Control:
	var coverage := WaveLibrary.get_deck_coverage(
		Progress.current_level_id, _deck_elements(deck)
	)

	var lbl := Label.new()
	lbl.text = "Répond à %d %% des PV de ce niveau" % int(round(coverage * 100.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	# Vert quand le deck domine, gris quand il est hors-sujet : la couleur doit
	# trancher avant même qu'on ait lu le pourcentage.
	if coverage >= 0.35:
		lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	elif coverage >= 0.20:
		lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	else:
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.66))
	return lbl


## Ensemble des éléments présents dans le deck, lus sur les scènes de tours.
func _deck_elements(deck: StartingDeckData) -> Dictionary:
	var seen := {}
	for card in deck.cards:
		if card == null:
			continue
		var element := _card_element(card)
		if element != ElementType.Type.NONE:
			seen[element] = true
	return seen


## Élément d'une carte, qu'elle pose une tour ou lance un sort. Les decks sont
## maintenant composés à 30-40 % de sorts : ignorer leur élément fausserait la
## couverture affichée au joueur, qui est justement le chiffre sur lequel il
## fonde son choix.
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


func _build_deck_elements_row(deck: StartingDeckData) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)

	var seen := {}
	for card in deck.cards:
		if card == null or card.tower_scene == null:
			continue
		var probe = card.tower_scene.instantiate()
		var element: ElementType.Type = ElementType.Type.NONE
		if probe is BaseTower:
			element = probe.element_type
		probe.free()
		if element == ElementType.Type.NONE or seen.has(element):
			continue
		seen[element] = true

		var lbl := Label.new()
		lbl.text = "%s %s" % [ElementType.icon(element), ElementType.label(element)]
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color", ElementType.color(element))
		row.add_child(lbl)

	return row


## Cartes uniques du deck, dans l'ordre d'apparition, avec leur quantité.
func _unique_cards(deck: StartingDeckData) -> Array:
	var counts := {}
	var order := []
	for c in deck.cards:
		if c == null:
			continue
		if not counts.has(c):
			counts[c] = 0
			order.append(c)
		counts[c] += 1

	var result := []
	for c in order:
		result.append({"card": c, "count": counts[c]})
	return result


func _build_card_preview(card: CardData, count: int) -> Control:
	var item := VBoxContainer.new()
	item.add_theme_constant_override("separation", 2)

	if card.card_texture != null:
		var tex := TextureRect.new()
		tex.texture = card.card_texture
		tex.custom_minimum_size = Vector2(140, 208)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item.add_child(tex)
	else:
		# Carte sans illustration (les sorts, pour l'instant) : sans ce repli,
		# elle occuperait un trou blanc dans l'aperçu du deck.
		item.add_child(_build_cardless_preview(card))

	var lbl := Label.new()
	lbl.text = "×%d  %s" % [count, card.card_name]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	item.add_child(lbl)

	return item


## Vignette de repli pour une carte sans illustration : panneau violet (sort)
## ou gris, avec son élément. Même code couleur que la main en jeu.
func _build_cardless_preview(card: CardData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 208)

	var is_spell := card.card_type == CardData.CardType.SPELL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.20, 0.12, 0.30) if is_spell else Color(0.16, 0.16, 0.19)
	sb.border_color = Color(0.75, 0.50, 1.0) if is_spell else Color(0.55, 0.55, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	var element := _card_element(card)
	if element != ElementType.Type.NONE:
		var el := Label.new()
		el.text = ElementType.icon(element)
		el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		el.add_theme_font_size_override("font_size", 34)
		vb.add_child(el)

	var kind := Label.new()
	kind.text = "SORT" if is_spell else "CARTE"
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kind.add_theme_font_size_override("font_size", 13)
	kind.add_theme_color_override("font_color", Color(0.78, 0.6, 1.0))
	vb.add_child(kind)

	var cost := Label.new()
	cost.text = "%d caps" % card.mana_cost
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.add_theme_font_size_override("font_size", 15)
	cost.add_theme_color_override("font_color", Color(0.85, 0.8, 0.5))
	vb.add_child(cost)

	return panel


# ══════════════════════════════════════════════════════
#              PHASE 2 — PERSONNALISATION
# ══════════════════════════════════════════════════════
#
# Le constructeur de deck LIBRE reste repoussé : avec 27 cartes très typées,
# il produirait surtout des decks injouables, et le joueur n'a pas encore les
# repères pour en juger. Ce compromis lui donne de la personnalisation sans le
# risque : il part d'un deck cohérent et n'en change qu'une poignée de cartes.
#
# Trois échanges, pas plus. C'est assez pour corriger un deck face au briefing
# de menaces qu'il vient de lire ("ce niveau demande de la Terre, j'échange mes
# deux Chouettes"), et trop peu pour dénaturer l'archétype.
const MAX_SWAPS := 3

var _custom_deck: Array[CardData] = []
var _base_deck: StartingDeckData = null
var _swaps_used := 0
var _selected_index := -1
var _swap_root: Control = null


func _on_deck_chosen(deck: StartingDeckData) -> void:
	Audio.ui_click()
	Progress.selected_deck = deck
	_base_deck = deck
	_custom_deck.clear()
	for c in deck.cards:
		if c != null:
			_custom_deck.append(c)
	_swaps_used = 0
	_selected_index = -1
	_build_swap_screen()


## Cartes proposables à l'échange : débloquées, hors du deck actuel.
func _swap_pool() -> Array[CardData]:
	var out: Array[CardData] = []
	for card in RewardDB.card_pool:
		if not card in _custom_deck:
			out.append(card)
	return out


func _build_swap_screen() -> void:
	# On masque la sélection de decks plutôt que de changer de scène : le
	# joueur garde le briefing de menaces sous les yeux, qui est justement
	# l'information sur laquelle il doit fonder ses échanges.
	deck_row.visible = false
	btn_back.visible = false
	if _swap_root:
		_swap_root.queue_free()

	_swap_root = VBoxContainer.new()
	_swap_root.add_theme_constant_override("separation", 8)
	deck_row.get_parent().add_child(_swap_root)
	_refresh_swap_screen()


func _refresh_swap_screen() -> void:
	for c in _swap_root.get_children():
		c.queue_free()

	var title := Label.new()
	title.text = "%s — ÉCHANGES : %d / %d" % [
		_base_deck.deck_name.to_upper(), _swaps_used, MAX_SWAPS
	]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	_swap_root.add_child(title)

	var hint := Label.new()
	hint.text = ("Clique une carte de TON DECK, puis une carte DISPONIBLE pour l'échanger."
		if _selected_index < 0
		else "Choisis maintenant la carte qui la remplace.")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.82))
	_swap_root.add_child(hint)

	_swap_root.add_child(_section("TON DECK", _custom_deck, true))

	if _swaps_used < MAX_SWAPS:
		_swap_root.add_child(_section("DISPONIBLES", _swap_pool(), false))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	_swap_root.add_child(row)

	var play := Button.new()
	play.text = "  LANCER LA PARTIE  "
	play.custom_minimum_size = Vector2(0, 52)
	play.pressed.connect(_launch)
	row.add_child(play)

	var back := Button.new()
	back.text = "  CHANGER DE DECK  "
	back.custom_minimum_size = Vector2(0, 52)
	back.pressed.connect(_back_to_decks)
	row.add_child(back)


func _section(label: String, cards: Array, is_deck: bool) -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	vb.add_child(lbl)

	# Le pool peut compter 15-20 cartes : sans défilement, il déborderait de
	# l'écran comme la rangée de decks l'a déjà fait.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 150)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	scroll.add_child(row)

	for i in cards.size():
		row.add_child(_swap_button(cards[i], i, is_deck))
	return vb


func _swap_button(card: CardData, index: int, is_deck: bool) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 132)
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = card.description
	btn.text = "%s
%d" % [card.card_name, card.mana_cost]
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_size_override("font_size", 12)

	if is_deck and index == _selected_index:
		btn.modulate = Color(1.5, 1.5, 0.7)

	if is_deck:
		btn.pressed.connect(func():
			Audio.ui_click()
			_selected_index = -1 if _selected_index == index else index
			_refresh_swap_screen()
		)
	else:
		btn.disabled = _selected_index < 0
		btn.pressed.connect(func():
			if _selected_index < 0:
				return
			Audio.ui_click()
			_custom_deck[_selected_index] = card
			_swaps_used += 1
			_selected_index = -1
			_refresh_swap_screen()
		)
	return btn


func _back_to_decks() -> void:
	Audio.ui_click()
	if _swap_root:
		_swap_root.queue_free()
		_swap_root = null
	deck_row.visible = true
	btn_back.visible = true


func _launch() -> void:
	Audio.ui_click()
	# On transmet la liste FINALE, pas le deck préconstruit : c'est elle qui a
	# été personnalisée.
	Progress.custom_deck_cards = _custom_deck.duplicate()

	var target := Progress.pending_level_scene
	if target == "":
		push_warning("DeckSelect : aucun niveau en attente, retour à la carte.")
		target = map_scene_path

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	await tween.finished
	get_tree().change_scene_to_file(target)


func _on_back_pressed() -> void:
	Audio.ui_click()
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	await tween.finished
	get_tree().change_scene_to_file(map_scene_path)
