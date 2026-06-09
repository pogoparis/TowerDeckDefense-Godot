# JUNKRIOT 2.0 — Bible de jeu
> Document de référence — état du projet au 09/06/2026
> À modifier librement pour définir la direction future.

---

## 1. CONCEPT GÉNÉRAL

Deck Tower Defense en Godot 4. Le joueur pose des tours et gère une main de cartes. Il peut **construire** (poser une tour) ou **défausser** (déclencher un phénomène de zone). La synergie entre les éléments est le cœur du gameplay : arroser des ennemis chargés électriquement les électrocute, etc.

---

## 2. SYSTÈME DE CARTES

### Main & Pioche
| Paramètre | Valeur actuelle |
|---|---|
| Taille de main max | 4 cartes |
| Refill post-vague | 3 cartes |
| Deck de départ | 9 cartes (Ironclad Starter) |

### Composition du deck de départ (Ironclad Starter)
- Canon à Eau × 3
- Bobine Tesla × 2
- Industrial Fan × 2
- Vega × 2

### Actions sur une carte
- **BUILD** (coût : mana_cost = 2 caps) → pose la tour sur la grille
- **CONSUME** (coût : consume_cost = 2 caps) → défausse la carte et crée un phénomène de zone
- La carte est retirée de la main dans les deux cas

### Phase de mulligan / échange
- **Vague 1** : Mulligan complet — échanger jusqu'à **3 cartes** avant la vague
- **Vague 2+** : Échange simple — échanger **1 seule carte** entre les vagues
- Les cartes sont remplacées par des cartes de la pioche
- L'échange se confirme via le bouton "Valider"

### Économie (Caps)
- Démarrage : **6 caps**
- Après chaque vague : **+3 caps automatiques**
- Bonus Ferrailleur : +3 caps supplémentaires par vague

---

## 3. LES TOURS (CARTES BUILD)

### Canon à Eau
| Stat | Valeur |
|---|---|
| Dégâts | 10 (base) |
| Cadence | 0.8s |
| Portée | 200 |
| Élément | WATER |
| Phénomène CONSUME | WATER_POOL (rayon 96, durée 6s) |
| Coût BUILD | 2 caps |
| Coût CONSUME | 2 caps |

**Comportement spécial** : Cible en priorité les ennemis à l'intérieur d'un Electric Field actif.
**Statut appliqué** : WET

---

### Bobine Tesla
| Stat | Valeur |
|---|---|
| Dégâts | 5 (base) |
| Cadence | 0.8s |
| Portée | 180 |
| Élément | ELECTRIC |
| Phénomène CONSUME | ELECTRIC_FIELD (rayon 96, durée min 10s) |
| Coût BUILD | 2 caps |
| Coût CONSUME | 2 caps |

**Statut appliqué** : CHARGED
**Déclencheur** : Mini Shock si la cible est WET (via ReactionManager)

---

### Industrial Fan
| Stat | Valeur |
|---|---|
| Dégâts | 10 (base) |
| Cadence | 0.8s |
| Portée | 180 |
| Élément | NATURE |
| Phénomène CONSUME | WIND_CURRENT (rayon 96, durée 6s) |
| Coût BUILD | 2 caps |
| Coût CONSUME | 2 caps |

**Comportement** : La tour **ralentit** les ennemis (slow 35% pendant 1.5s) + applique WINDMARK. **Pas de knockback** — le knockback appartient au phénomène Wind Current.

---

### Vega
| Stat | Valeur |
|---|---|
| Dégâts | base (valeur nulle dans .tscn, à définir) |
| Cadence | 1.3s |
| Portée | 250 |
| Élément | AIR |
| Phénomène CONSUME | aucun |
| Coût BUILD | 2 caps |

**Comportement spécial** : Marque la cible (VEGA_MARK). Active un guide laser si `laser_guide_active = true`. Dégâts bonus si guidé laser.

---

## 4. LES PHÉNOMÈNES (CARTES CONSUME)

Les phénomènes sont des zones temporaires créées en défaussant une carte.
Le rayon et la durée sont modifiables par les bonus (Zone Étendue, Persistance).

### WATER_POOL (Canon à Eau)
- **Durée** : 6s
- **Rayon** : 96
- **Effet** : applique le statut WET toutes les 0.5s aux ennemis dans la zone
- **Réaction** : si un ennemi **CHARGED** entre dans la zone → **⚡ COURT-CIRCUIT !** (35 dégâts, stun 2.5s, cooldown 4s/ennemi)

### ELECTRIC_FIELD (Bobine Tesla)
- **Durée** : minimum 10s
- **Rayon** : 96
- **Effet** : applique CHARGED + 5 dégâts toutes les 0.25s à tous les ennemis dans la zone
- **Réaction** : si l'ennemi est **WET** → stun 2s + texte "⚡ PARALYSÉ !"
- Flash d'entrée spectaculaire, arcs électriques animés

### WIND_CURRENT (Industrial Fan)
- **Durée** : 6s
- **Rayon** : 96
- **Effet** : applique WINDMARK toutes les 0.5s
- **Knockback** : toutes les **3 secondes**, repousse de **55px** tous les ennemis dans la zone + rafale visuelle cyan

### FIRE_ZONE *(à implémenter)*
- Applique BURNING

### THORN_PATCH *(à implémenter)*
- Applique ROOTED

---

## 5. LES RÉACTIONS

### Mini Shock (automatique)
- **Condition** : ennemi est WET **ET** CHARGED simultanément
- **Dégâts** : 8 base (+ bonus Court-Circuit)
- **Cooldown** : 1.0s par ennemi (× multiplicateur Bobine Surchargée)
- **Visuel** : texte flottant "SHOCK !"

### Électrocution (zone d'effet, via ElectrocutionZone)
- **Condition** : déclenchée manuellement (carte CONSUME ou autre)
- **Burst initial** : 40 dégâts (× Électrocution Fatale) + stun 3s
- **Ticks** : 15 dégâts/0.35s pendant 3.5s
- **Rayon** : 112
- **Visuel** : arcs électriques, rayons depuis le centre, flash d'entrée

### Court-Circuit (Water Pool + CHARGED)
- **Condition** : ennemi CHARGED dans une zone Water Pool
- **Dégâts** : 35 (× Électrocution Fatale)
- **Stun** : 2.5s (+ Paralysie Prolongée)
- **Cooldown** : 4s par ennemi
- **Visuel** : flash cyan, arcs courts sur l'ennemi

### PARALYSÉ (Electric Field + WET)
- **Condition** : ennemi WET dans un Electric Field
- **Effet** : stun 2s supplémentaire
- **Visuel** : texte "⚡ PARALYSÉ !"

---

## 6. LES STATUTS

| Statut | ID | Effet actuel |
|---|---|---|
| WET | `wet` | Permet Mini Shock si aussi CHARGED. Tick dégâts si bonus Flaque Toxique (+3/s). Durée prolongeable par bonus. |
| CHARGED | `charged` | Permet Mini Shock si aussi WET. Électrocution si dans Water Pool. |
| BURNING | `burning` | *(à implémenter)* |
| ROOTED | `rooted` | *(à implémenter)* |
| WINDMARK | `windmark` | Appliqué par la tour Industrial Fan. Effet gameplay à définir. |
| STUNNED | `stunned` | Vitesse = 0 pendant la durée du stun. |

---

## 7. LES ENNEMIS

### SimpleMob
| Stat | Valeur |
|---|---|
| HP | 50 |
| Vitesse | 150 px/s |
| Vague | 1 |

### TankMob
| Stat | Valeur |
|---|---|
| HP | 300 |
| Vitesse | 60 px/s |
| Vague | 2 |

### ExplosiveMob
| Stat | Valeur |
|---|---|
| HP | 100 |
| Vitesse | 150 px/s |
| Vague | 3 |

**Knockback** : tous les ennemis ont un cooldown de knockback de **3s**. Quand ils sont repoussés : déplacement instantané de N pixels sur le chemin + freeze 0.3s.

---

## 8. LES VAGUES

| Vague | Ennemi | Nombre | Intervalle | Vitesse |
|---|---|---|---|---|
| 1 | SimpleMob | 6 | 3.0s | 200 px/s |
| 2 | TankMob | 3 | 5.0s | 80 px/s |
| 3 | ExplosiveMob | 6 | 3.0s | 100 px/s |

**Design vague 2** : 3 tanks très lents et très résistants. Avec 2 tours seules, le joueur passe tout juste. Il faut utiliser au moins un CONSUME pour s'en sortir confortablement.

**Temps de préparation** : 20 secondes entre chaque vague.

---

## 9. LES BONUS (RÉCOMPENSES INTER-VAGUES)

Après chaque vague, le joueur choisit 1 bonus parmi une sélection (système RewardManager).

### Bonus Tours (généraux)
| Titre | Rareté | Effet |
|---|---|---|
| Munitions Renforcées | COMMON | +8 dégâts à toutes les tours |
| Canon Long | COMMON | +40 portée à toutes les tours |
| Mécanisme Huilé | RARE | Cadence de tir +25% (fire_rate × 0.75) |

### Bonus Eau
| Titre | Rareté | Effet |
|---|---|---|
| Canon à Eau Modifié | RARE | Statut WET dure 2s de plus |
| Flaque Toxique | RARE | Les ennemis WET subissent 3 dégâts/s |

### Bonus Électricité
| Titre | Rareté | Effet |
|---|---|---|
| Court-Circuit | COMMON | Mini Shock inflige +10 dégâts |
| Bobine Surchargée | EPIC | Mini Shock se déclenche 2× plus souvent (cooldown × 0.5) |
| Électrocution Fatale | EPIC | Dégâts d'Électrocution × 1.5 |
| Paralysie Prolongée | RARE | Durée du stun +1.5s |

### Bonus Phénomènes
| Titre | Rareté | Effet |
|---|---|---|
| Zone Étendue | RARE | Rayon de tous les phénomènes × 1.3 |
| Persistance | RARE | Tous les phénomènes durent +4s |

### Bonus Économie / Cartes
| Titre | Rareté | Effet |
|---|---|---|
| Sacrifice Économique | EPIC | CONSUME coûte 1 cap de moins |
| Ferrailleur | COMMON | +3 caps au début de chaque vague |
| Fouille des Décombres | RARE | Pioche 1 carte supplémentaire après chaque vague (max 4 en main) |

---

## 10. SYNERGIES CONFIRMÉES

| Combo | Résultat |
|---|---|
| Tour Eau + Tour Électrique | Mini Shock automatique sur les ennemis WET+CHARGED |
| Electric Field + ennemi WET | Stun 2s + "PARALYSÉ !" |
| Water Pool + ennemi CHARGED | Court-Circuit (35 dégâts + stun 2.5s) |
| Tour Eau → Electric Field | Eau cible en priorité les ennemis dans le champ électrique |
| Industrial Fan → WIND_CURRENT | La tour ralentit, le phénomène repousse |

---

## 11. CE QUI EST À FAIRE / À DÉCIDER

### Gameplay
- [ ] **Vague 4+** : nouveaux ennemis ? Boss ? Définir la progression
- [ ] **BURNING / ROOTED** : statuts codés mais sans effets gameplay
- [ ] **WINDMARK** : statut appliqué mais sans effet synergique défini
- [ ] **Vega** : valeur de base_damage à fixer dans le .tscn
- [ ] **Vega laser guide** : mécanisme à préciser (quand s'active-t-il ?)
- [ ] **ExplosiveMob** : comportement à définir (explose à la mort ? dégâts de zone ?)

### Cartes & Deck
- [ ] **Nouvelles cartes** : les 14 bonus existent en .tres mais pas en cartes jouables
- [ ] **Cartes récompenses** : créer les CardData pour distribuer les bonus
- [ ] **Description cartes** : `industrial_fan_card.tres` dit encore "Knockback toutes les 3 secondes" — à corriger (c'est le phénomène, pas la tour)
- [ ] **Nouvelles tours** : à inventer (Feu ? Ronces ?)

### Technique
- [ ] **Reward system** : les anciens bonus (sharpened_ammo, long_barrel, etc.) ne correspondent plus au design — à nettoyer ou remplacer
- [ ] **base_damage de Vega** : null dans le .tscn, à fixer
- [ ] **Carte Vega sans consume_phenomenon_type** : elle ne peut pas être défaussée pour un phénomène — intentionnel ?

---

## 12. ARCHITECTURE TECHNIQUE (RÉFÉRENCE RAPIDE)

| Script | Rôle |
|---|---|
| `card_manager.gd` | Gère la main, la pioche, BUILD, CONSUME |
| `wave_manager.gd` | Spawn des vagues, prep phase, récompenses post-vague |
| `reaction_manager.gd` | Vérifie WET+CHARGED → Mini Shock chaque frame |
| `phenomenon_manager.gd` | Crée et suit les phénomènes actifs |
| `phenomenon.gd` | Logique d'une zone (contamination, dégâts, knockback) |
| `enemy_base.gd` | HP, statuts, slow, knockback, mort |
| `base_tower.gd` | Stats, cadence, ciblage, bonus de run |
| `run_bonuses.gd` | Autoload — getters agrégés sur tous les bonus possédés |
| `player_data.gd` | Autoload Player — caps, HP de base, numéro de vague |

### Phénomènes — paramètres clés
```
consume_radius = 96.0   (modifié × phenomenon_radius_mult)
consume_duration = 6.0  (+ phenomenon_duration_bonus)
ELECTRIC_FIELD : durée min forcée à 10s
```

### Règles de la main
```
max_hand_size = 4
refill_hand_size = 3   (pioche automatique fin de vague)
mulligan vague 1 = max 3 cartes échangées
échange vague 2+ = max 1 carte échangée
```
