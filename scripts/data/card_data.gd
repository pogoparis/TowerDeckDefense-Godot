extends Resource
class_name CardData

enum CardType {
	TOWER,
	SPELL,
	UPGRADE,
	TACTIC,
	ECONOMY,
	RELIC
}


@export var card_name: String
@export_multiline var description: String

@export var card_type: CardType
@export var card_texture : Texture2D
@export var mana_cost := 1
@export var tower_id: String
@export var icon: Texture2D

# ==============================
#       GAMEPLAY LINKS
# ==============================

@export var tower_scene: PackedScene
@export var bonus_data: BonusData
## Rempli uniquement pour les cartes SPELL (voir SpellData).
@export var spell_data: SpellData

@export_group("Cartes utilitaires")
## ── Pourquoi ces cartes existent ──────────────────────────────────────────
## Un deck composé uniquement de tours et de sorts ne se CONSTRUIT pas, il
## s'accumule : chaque carte fait la même chose que la précédente en un peu
## différent. Les cartes utilitaires créent les archétypes — un deck économie
## qui explose en fin de partie, un deck qui cycle vite, un deck qui mise tout
## sur trois tours maxées. C'est ce qui fait qu'un deckbuilder a des IDENTITÉS
## plutôt que des variantes.

## ECONOMY — Caps versées immédiatement à la pose.
@export var instant_caps := 0
## ECONOMY — Caps versées à CHAQUE fin de vague, pour le reste de la partie.
## L'effet boule de neige : payé tôt, il rapporte énormément ; joué vague 10,
## il ne sert à rien. Une carte dont la valeur dépend du MOMENT où on la joue.
@export var caps_per_wave := 0
## TACTIC — Cartes piochées immédiatement.
@export var draw_cards := 0
## UPGRADE — Améliore gratuitement la tour visée (vise comme un sort).
@export var free_upgrade := false


@export_group("Version améliorée ★")
## ── Pourquoi l'amélioration de carte existe ───────────────────────────────
## Gagner des cartes ne fait que GROSSIR le deck — et un deck qui grossit
## devient moins fiable, puisqu'on a moins de chances de piocher celle qu'on
## veut. Passé 16-18 cartes, chaque ajout est presque une punition.
##
## L'amélioration est la SEULE récompense qui rend le deck meilleur sans
## l'alourdir. C'est elle qui transforme « mon deck est plus gros » en « mon
## deck est le mien ».
##
## Les valeurs ci-dessous sont des défauts génériques. Une carte peut les
## surcharger dans son .tres pour une version ★ sur mesure.
var upgraded := false

## TOUR ★ — appliqués à la tour au moment de la pose.
@export var up_damage_mult := 1.35
@export var up_fire_rate_mult := 0.85
@export var up_range_mult := 1.10
## Barres de Charge en MOINS (la Charge part plus vite).
@export var up_charge_bonus := 1

## SORT ★
@export var up_spell_radius_mult := 1.25
@export var up_spell_damage_mult := 1.5
@export var up_spell_duration_mult := 1.4

## UTILITAIRE ★ — multiplie caps, pioche et revenus.
@export var up_utility_mult := 1.5


## Transforme cette carte en sa version ★. Irréversible, et une seule fois.
func apply_upgrade() -> void:
	if upgraded:
		return
	upgraded = true
	card_name = "%s ★" % card_name

	match card_type:
		CardType.SPELL:
			if spell_data != null:
				# On duplique le SpellData : il est partagé entre toutes les
				# copies de la carte (et entre les parties). Le modifier en
				# place améliorerait le sort pour tout le monde, définitivement.
				var s: SpellData = spell_data.duplicate(true)
				s.radius *= up_spell_radius_mult
				s.damage = int(round(s.damage * up_spell_damage_mult))
				s.duration *= up_spell_duration_mult
				spell_data = s

		CardType.ECONOMY, CardType.TACTIC:
			instant_caps = int(round(instant_caps * up_utility_mult))
			caps_per_wave = int(round(caps_per_wave * up_utility_mult))
			if draw_cards > 0:
				draw_cards += 1

		CardType.UPGRADE:
			# Une carte d'amélioration ★ devient gratuite : c'est plus fort et
			# plus lisible que « +50 % d'un effet booléen ».
			mana_cost = 0

		_:
			pass   # TOUR : les multiplicateurs sont lus à la pose
