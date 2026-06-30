extends Resource
class_name BonusData

@export_enum("COMMON", "RARE", "EPIC", "LEGENDARY")
var rarity: String = "COMMON"

@export var title: String
@export_multiline var description: String
@export var icon: Texture2D

# ── Tours (BUILD) ─────────────────────────────────────
@export var damage_bonus       := 0
@export var range_bonus        := 0
@export var fire_rate_mult     := 1.0
@export var wet_duration_bonus := 0.0       # Canon à Eau Modifié

# ── Réactions ─────────────────────────────────────────
@export var mini_shock_damage_bonus      := 0      # Court-Circuit
@export var mini_shock_cooldown_mult     := 1.0    # Bobine Surchargée (0.5 = 2× plus vite)
@export var electrocution_damage_mult    := 1.0    # Électrocution Fatale
@export var stun_duration_bonus          := 0.0    # Paralysie Prolongée
@export var wet_tick_damage              := 0      # Flaque Toxique

# ── Phénomènes (CONSUME) ─────────────────────────────
@export var phenomenon_radius_mult       := 1.0    # Zone Étendue
@export var phenomenon_duration_bonus    := 0.0    # Persistance
@export var consume_cost_reduction       := 0      # Sacrifice Économique

# ── Économie ─────────────────────────────────────────
@export var caps_per_wave                := 0      # Ferrailleur
@export var post_wave_draw_bonus         := 0      # Fouille des Décombres
