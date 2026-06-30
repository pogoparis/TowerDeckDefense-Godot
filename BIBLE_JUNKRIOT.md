# BIBLE JUNKRIOT 2.0
> Document de référence complet — état du projet au 2026-06-10  
> Destination : transmettre le contexte à un autre IA ou collaborateur

---

## 0. VISION & PRINCIPES FONDATEURS

**Junkriot 2.0** est un tower defense avec mécanique de deck building.  
Chaque carte a une double utilité :
- **BUILD (poser)** : déploie une tour permanente sur la grille
- **CONSUME (défausser)** : détruit la carte pour créer un phénomène de zone temporaire

### Hiérarchie de puissance
```
TOUR (dégâts continus) < PHÉNOMÈNE (zone, durée) < RÉACTION MAJEURE (burst dévastateur)
```

### ADN du jeu
> *"Le but de Junkriot n'est pas de pousser le joueur à BUILD.*  
> *Le but de Junkriot n'est pas de pousser le joueur à CONSUME.*  
> *Le but de Junkriot est de créer une hésitation permanente entre BUILD et CONSUME."*

Le joueur consomme ses cartes **parce que les réactions sont incroyables**, pas parce que BUILD est trop cher. La décision a du poids parce que **les deux options coûtent une carte définitivement**.

### Philosophie économique validée
- BUILD = 2 caps, CONSUME = 2 caps — **même coût intentionnel**
- Le poids de la décision vient du fait que la **carte est brûlée**, pas du coût en caps
- Les phénomènes et réactions sont **volontairement forts** pour donner envie de CONSUME
- Ne jamais forcer CONSUME par la contrainte économique — le séduire par la puissance

### Règle absolue
- Toute carte **jouée** (BUILD) est **brûlée** — retirée définitivement du jeu
- Toute carte **défaussée** (CONSUME) est **brûlée** — aucun recyclage
- Il n'y a pas de défausse, pas de cimetière : la pioche se vide et c'est tout

---

## 1. TECHNOLOGIES

- **Moteur** : Godot 4.6
- **Langage** : GDScript (typage statique préféré)
- **Plateforme cible** : PC (prototype), mobile envisagé
- **Architecture** : `level.gd` est le chef d'orchestre — il instancie et connecte les managers, ne contient pas de logique métier

---

## 2. ÉCONOMIE

| Ressource | Départ | Gain par vague | Source autre |
|-----------|--------|----------------|--------------|
| **Caps** | 4 | +3 après chaque vague | RunBonuses (Ferrailleur) |
| **Ferraille** | 0 | — | +1 par SimpleMob/ExplosiveMob tué, +3 par TankMob, +10 par MiniBoss |

- **Poser une tour** : 2 caps
- **Consommer une carte** : 2 caps
- La ferraille est une monnaie future pour les améliorations de tour (non implémenté)

---

## 3. DECK DE DÉPART — Ironclad Starter

10 cartes totales, toutes brûlées à l'usage :
- **Canon à Eau** × 5 (`water_cannon_card.tres`)
- **Bobine Tesla** × 5 (`tesla_coil_card.tres`)

Fichier : `resources/decks/ironclad_starter.tres`

---

## 4. CARTES

### Canon à Eau
| Propriété | Valeur |
|-----------|--------|
| Coût BUILD | 2 caps |
| Coût CONSUME | 2 caps |
| Tour déployée | TowerWaterCannon |
| Phénomène créé | WATER_POOL |
| Rayon phénomène | 150 px |
| Durée phénomène | 10 s |

### Bobine Tesla
| Propriété | Valeur |
|-----------|--------|
| Coût BUILD | 2 caps |
| Coût CONSUME | 2 caps |
| Tour déployée | TowerTeslaCoil |
| Phénomène créé | ELECTRIC_FIELD |
| Rayon phénomène | 150 px |
| Durée phénomène | 10 s (forcée dans `_ready`) |

---

## 5. TOURS

### Architecture commune (`base_tower.gd`)
- `base_damage`, `base_fire_rate = 0.8s`, `base_range = 120px`
- `element_type` (WATER / ELECTRIC / NONE…)
- `find_target()` → retourne le premier ennemi en portée (override possible)

### TowerWaterCannon
**Ciblage prioritaire** (ordre décroissant) :
1. Ennemi dans un Electric Field, **pas WET**, **pas stun** — le plus avancé
2. Ennemi dans un Electric Field, **pas stun** (même WET — pour déclencher COURT-CIRCUIT)
3. Ennemi en portée, **pas WET** — le plus avancé
4. Fallback : n'importe quel ennemi en portée

### TowerTeslaCoil
**Ciblage prioritaire** :
1. Ennemi en portée **pas STUNNED**
2. Fallback : n'importe quel ennemi en portée

---

## 6. ENNEMIS

### SimpleMob
- HP : ~30, Vitesse : 200, Ferraille : 1 (défaut)

### TankMob
- HP : 260, Vitesse : 60, Ferraille : 3

### ExplosiveMob
- HP : 100, Vitesse : 150, Ferraille : 1
- Scale racine : 0.6 (plus petit visuellement)

### MiniBoss (vague 3)
- HP : 800, Vitesse : 40, Ferraille : 10
- Scale racine : 1.6 (visuellement grand)
- Barre de vie **rouge**
- Spawn 3s après le dernier mob de la vague 3

Tous les ennemis héritent de `enemy_base.gd` et utilisent `PathFollow2D.progress` pour avancer sur le chemin.

---

## 7. STATUTS (`status_ids.gd`)

| Constante | Valeur string | Icône | Couleur tint |
|-----------|--------------|-------|-------------|
| `WET` | "wet" | WaterIcon64.png | blanc |
| `CHARGED` | "charged" | ThunderIcon64.png | jaune |
| `STUNNED` | "stunned" | WindIcon64.png | bleu clair |
| `BURNING` | "burning" | FireIcon64.png | blanc |
| `ROOTED` | "rooted" | NatureIcon64.png | blanc |
| `WINDMARK` | "windmark" | WindIcon64.png | blanc |

Gérés dans `enemy_base.gd` → `status_effects: Dictionary`  
Affichage : `StatusIconContainer` attaché à chaque ennemi (scripts/status/status_icon_container.gd)

---

## 8. PHÉNOMÈNES

Créés par CONSUME d'une carte. Gérés par `PhenomenonManager`.  
Script principal : `scripts/phenomena/phenomenon.gd`

### WATER_POOL
- Durée : 10s, Rayon : 150px
- Applique **WET** (3s) à chaque ennemi dans la zone toutes les 0.5s (renouvelé à chaque tick)
- **Ralentit à 25% de vitesse** (`apply_slow(0.25, ...)`) tant que l'ennemi est dans la flaque
- Réaction croisée : si ennemi est CHARGED → **COURT-CIRCUIT** (cooldown 4s par ennemi)

### ELECTRIC_FIELD
- Durée : 10s (forcée dans `_ready`), Rayon : 150px
- Inflige **5 dmg/tick** (toutes les 0.25s)
- Applique **CHARGED** (3s)
- Réaction : si ennemi WET → **PARALYSÉ** (stun 2s + slow total, 0 vitesse)
  - Texte "⚡ PARALYSÉ !" affiché **une seule fois** par nouvelle application de stun

### WIND_CURRENT
- Knockback périodique (toutes les 3s, force 55)
- Knockback instantané : `pf.progress -= force` + `apply_slow(0.0, 0.3)`
- La **tour Industrial Fan** ralentit uniquement (pas de knockback direct)

---

## 9. RÉACTIONS

### Mini Shock (automatique, passif)
- **Déclencheur** : ennemi possède WET + CHARGED simultanément
- **Dégâts** : 8 + `RunBonuses.get_mini_shock_damage_bonus()`
- **Cooldown** : 1s normal, **2s si ennemi déjà STUNNED** (évite le spam sur mob paralysé)
- Vérifié chaque frame dans `ReactionManager._process()` → `check_contamination_reactions()`

### PARALYSÉ (Electric Field + ennemi WET)
- Stun 2s + vitesse 0
- Texte flottant unique par application
- Géré dans `phenomenon.gd → _apply_electric_damage()`

### COURT-CIRCUIT (Water Pool + ennemi CHARGED)
- **Dégâts** : 80 × `RunBonuses.get_electrocution_damage_mult()`
- **Effet** : stun 3s + vitesse 0
- Cooldown 4s par ennemi
- Texte : "⚡ COURT-CIRCUIT !"
- Géré dans `phenomenon.gd → _trigger_cross_electrocution()`

### ÉLECTROCUTION (Water Pool + Electric Field qui se chevauchent)
- Deux phénomènes proches → fusionnent en `ElectrocutionZone`
- Burst 100 dmg + tick 20 dmg + stun
- Les deux phénomènes sont **détruits** à la réaction
- Géré dans `ReactionManager → trigger_electrocution()`

---

## 10. PHASE DE JEU — DÉROULEMENT

```
[MULLIGAN] → [COMPTE À REBOURS 5s] → [VAGUE] → [ATTENTE FIN VAGUE]
    → [+3 caps] → [draw jusqu'à main pleine] → [RÉCOMPENSE] → [MULLIGAN suivant]
```

### Mulligan
- **Avant vague 1** : échange jusqu'à 3 cartes
- **Inter-vague** : échange 1 carte maximum
- Overlay : "PHASE DE MULLIGAN" / "ÉCHANGE INTER-VAGUE" selon la vague
- Après validation : compte à rebours 5s avant le début de la vague

### Main & Pioche
- `max_hand_size = 4`, `refill_hand_size = 3`
- Pas de défausse — les cartes brûlées sont retirées définitivement
- `draw_to_hand()` : si pioche vide → stop, pas de recyclage

---

## 11. VAGUES

| Vague | Ennemis | Nombre | Intervalle | Vitesse | Boss |
|-------|---------|--------|------------|---------|------|
| 1 | SimpleMob | 6 | 3s | 200 | — |
| 2 | TankMob | 3 | 5s | 80 | — |
| 3 | ExplosiveMob | 6 | 3s | 100 | MiniBoss (+3s délai) |

**WaveData** (`scripts/resources/wave_data.gd`) :
```gdscript
@export var enemy_scene: PackedScene
@export var enemy_count := 10
@export var spawn_interval := 1.0
@export var enemy_speed := 70.0
@export var boss_scene: PackedScene = null   # optionnel
@export var boss_delay := 3.0
```
Le boss spawn après le dernier mob. Le WaveTimerLabel affiche "MINIBOSS !" pendant 1.5s.

---

## 12. ARCHITECTURE CODE

### Chef d'orchestre : `level.gd`
- Instancie et connecte tous les managers via `setup()`
- Ne contient pas de logique métier
- Connecte les signaux Player (caps, HP, wave, ferraille) aux fonctions HUD
- Aucun style en code : tout le style UI vient de `resources/themes/junkriot_theme.tres` (voir `docs/UI_STYLE_GUIDE.md`)

### Autoloads
| Nom | Fichier | Rôle |
|-----|---------|------|
| `Player` | `scripts/data/player_data.gd` | caps, HP base, ferraille, vague — signaux |
| `RunBonuses` | `scripts/core/run_bonuses.gd` | multiplicateurs bonus de run |
| `FloatingTextService` | — | textes flottants à l'écran |
| `RewardManager` | — | panneau de récompenses inter-vague |
| `SynergyLibrary` | — | catalogue des synergies de tours |
| `StatusIds` | `scripts/data/status_ids.gd` | constantes string des statuts |
| `PhenomenonType` | — | enum des types de phénomènes |
| `ElementType` | — | enum des éléments |

### Managers
| Manager | Fichier | Rôle |
|---------|---------|------|
| `WaveManager` | `scripts/managers/wave_manager.gd` | Spawn vagues, prep phase, mulligan, boss |
| `CardManager` | `scripts/cards/card_manager.gd` | Main, pioche, BUILD/CONSUME |
| `PlacementManager` | `scripts/managers/placement_manager.gd` | Placement tours sur grille |
| `TowerManager` | `scripts/managers/tower_manager.gd` | Tours actives, synergies |
| `PhenomenonManager` | `scripts/phenomena/phenomenon_manager.gd` | Phénomènes actifs |
| `ReactionManager` | `scripts/reactions/reaction_manager.gd` | Mini Shock, Électrocution |
| `EnemyManager` | `scripts/managers/enemy_manager.gd` | Liste ennemis vivants |
| `GridManager` | `scripts/managers/grid_manager.gd` | Cellules constructibles |

---

## 13. BARRE DE VIE — SYSTÈME GÉNÉRIQUE

Dans `enemy_base.gd` :
```gdscript
@onready var hp_fill: ColorRect = get_node_or_null("HPBarContainer/HPFill")
@onready var hp_background: ColorRect = get_node_or_null("HPBarContainer/HPBackground")

func update_hp_bar():
    var ratio := float(hp) / float(max_hp)
    var bar_width := hp_background.offset_right if hp_background else 40.0
    hp_fill.offset_right = bar_width * ratio
```
- Largeur lue depuis `HPBackground.offset_right` → générique, fonctionne pour tous les ennemis
- Couleur : vert > 60%, orange > 30%, rouge sinon
- MiniBoss : barre rouge fixe définie dans la scène

---

## 14. HUD

**Tout le style UI vient de `resources/themes/junkriot_theme.tres`** — un seul Theme Godot,
éditable dans l'éditeur, appliqué à la racine de chaque scène UI.
Les nœuds utilisent des `theme_type_variation` (DarkPanel, GhostButton, TitleGold…).
Règles complètes : `docs/UI_STYLE_GUIDE.md`.

### TopHUD (`scenes/ui/TopHUD.tscn` + `scripts/ui/top_hud.gd`)
- Vague, kills, PV base (code couleur via @export), caps, bouton vitesse, bouton ⚙
- Barre de vague : se remplit au fil des spawns (ou du countdown en prep)

### Bouton vitesse
- `▶▶ x2` → `Engine.time_scale = 2.0`
- `▶ x1` → `Engine.time_scale = 1.0`

### Barre du bas
- `CardBarBackground` (PanelContainer, variation `CardBarPanel`) dans `level.tscn`, derrière les cartes

---

## 15. CONVENTIONS & PIÈGES TECHNIQUES

| Problème | Solution |
|---------|---------|
| BOM UTF-8 sur `.tres` (PowerShell) | Utiliser Write/Edit tools Godot, jamais `Set-Content` |
| Tween sur `pf.progress` → conflit `_physics_process` | Assignation directe : `pf.progress -= force` |
| `draw` est un signal de `CanvasItem` | Renommer : `draw_node`, `burst_draw`, `drop_draw` |
| `get_parent()` non typé → erreur inférence | `var pf := enemy.get_parent() as PathFollow2D` |
| `has_status()` retourne Variant | `var x: bool = enemy.has_status(...)` |
| Style UI en code (StyleBoxFlat.new()…) | INTERDIT — tout passe par `junkriot_theme.tres` |
| Texte flottant spam sur stun | `var was_stunned: bool = enemy.has_status(...)` avant `add_status` |
| Encodage mojibake descriptions cartes | Écrire en ASCII dans les `.tres`, accents dans l'éditeur Godot |

---

## 16. CE QUI EST VALIDÉ (phase prototype terminée)

Le cœur du jeu fonctionne. Ne plus modifier ces éléments sans raison forte :

| Élément | Statut |
|---------|--------|
| BUILD / CONSUME dual-use | ✅ validé |
| WET + CHARGED + MINI SHOCK | ✅ validé |
| COURT-CIRCUIT (Water Pool + CHARGED) | ✅ validé |
| ÉLECTROCUTION (deux phénomènes) | ✅ validé |
| PARALYSÉ (Electric Field + WET) | ✅ validé |
| Cartes brûlées définitivement | ✅ validé |
| Deck qui se vide (pas de recyclage) | ✅ validé |
| Boucle de vague + mulligan + récompenses | ✅ validé |

---

## 17. FEUILLE DE ROUTE — ENRICHISSEMENT

### Règle d'or pour tout nouvel élément
```
1 élément = 1 tour + 1 phénomène + 1 réaction majeure
```
Ne jamais ajouter du contenu sans réaction. C'est la réaction qui vend la décision CONSUME.

### Priorité 1 : AIR (coût faible, base existante)
- Industrial Fan et Wind Current existent déjà dans le code
- **Tour** : Industrial Fan → applique WINDMARK / AIRFLOW
- **Phénomène** : Wind Current → repousse, regroupe, ralentit
- **Réaction majeure** : Electric Field + Wind Current → THUNDERSTORM (éclairs aléatoires, stun, gros dégâts)

### Priorité 2 : FEU
- **Tour** : Fire Turret → applique BURNING
- **Phénomène** : Fire Zone
- **Réaction mineure** : BURNING + WET → STEAM
- **Réaction majeure** : Fire Zone + Wind Current → FIRE TORNADO

### Priorité 3 : NATURE
- Plus abstrait, à garder pour après validation FEU
- ROOTED est déjà dans StatusIds

### À NE PAS FAIRE
- Ajouter 10 tours sans réactions associées
- Ajouter un élément avant que le précédent soit testé
- Diluer la mécanique BUILD/CONSUME avec du contenu passif

---

## 18. CE QUI N'EST PAS ENCORE FAIT (technique)

- Système d'amélioration de tour avec ferraille (UI + mécanique)
- Label ferraille dans le TopBar (code prêt, nœud à ajouter dans l'éditeur Godot)
- Plus de vagues (actuellement 3)
- Menu principal / écran de game over propre
- Sauvegarde de run
- Icône dédiée pour STUNNED (actuellement WindIcon teinté bleu)
- Industrial Fan déplacé en "contenu futur" — ne pas documenter dans la bible principale tant qu'AIR n'est pas développé proprement
