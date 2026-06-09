# JUNKRIOT 2.0 — Bible de jeu
> Document de référence — mis à jour le 09/06/2026
> À modifier librement pour définir la direction future.

---

## 0. PRINCIPES FONDATEURS

> Ces règles protègent le concept. Si l'une d'elles est violée, Junkriot redevient un Tower Defense classique.

```
UN PHÉNOMÈNE DOIT ÊTRE PLUS PUISSANT QU'UNE TOUR.
UNE RÉACTION MAJEURE DOIT ÊTRE PLUS PUISSANTE QU'UN PHÉNOMÈNE.
```

```
TOUR  <  PHÉNOMÈNE  <  RÉACTION MAJEURE
```

La vraie question du prototype n'est pas *"combien d'éléments avons-nous ?"* mais :
**"BUILD / CONSUME crée-t-il une décision réellement intéressante ?"**

---

## 1. CONCEPT GÉNÉRAL

Deck Tower Defense. Le joueur pose des tours et gère une main de cartes. Chaque carte a deux usages :

```
Carte
├─ BUILD   → pose une tour (dégâts continus, statut sur les ennemis)
└─ CONSUME → défausse la carte, crée un phénomène de zone (plus puissant)
```

```
Tour → applique un Statut
Carte consommée → crée un Phénomène
Statut A + Statut B → déclenche une Réaction
```

Le CONSUME est encouragé : il est moins cher que le BUILD, mais on perd la carte.
La tension vient de ce choix constant : poser une tour durable ou déclencher un effet immédiat décisif ?

---

## 2. SYSTÈME DE CARTES

### Main & Pioche
| Paramètre | Valeur |
|---|---|
| Taille de main max | 4 cartes |
| Refill post-vague | 3 cartes |
| Deck de départ | 9 cartes (Ironclad Starter) |

### Composition du deck de départ (Ironclad Starter)
- Canon à Eau × 3
- Bobine Tesla × 2
- Industrial Fan × 2
- Vega × 2 *(à réévaluer — voir section 3)*

### Actions sur une carte
- **BUILD** (coût : **4 caps**) → pose la tour sur la grille, carte retirée
- **CONSUME** (coût : **2 caps**) → défausse la carte, crée un phénomène, carte retirée

> BUILD est plus cher que CONSUME : on encourage l'expérimentation des phénomènes.

### Phase de mulligan / échange
- **Vague 1** : Mulligan complet — échanger jusqu'à **3 cartes** avant la vague
- **Vague 2+** : Échange simple — échanger **1 seule carte** entre les vagues
- Les cartes sont remplacées par des cartes de la pioche
- L'échange se confirme via le bouton "Valider"

### Économie (Caps)
- Démarrage : **15 caps** (permet d'expérimenter dès le début)
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
| Coût BUILD | 4 caps |
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
| Coût BUILD | 4 caps |
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
| Coût BUILD | 4 caps |
| Coût CONSUME | 2 caps |

**Comportement** : La tour **ralentit** les ennemis (slow 35% pendant 1.5s) + applique WINDMARK.
Le knockback appartient **exclusivement** au phénomène Wind Current, pas à la tour.

---

### Vega *(à réévaluer)*
| Stat | Valeur |
|---|---|
| Dégâts | à définir |
| Cadence | 1.3s |
| Portée | 250 |
| Élément | AIR |
| Phénomène CONSUME | **aucun** |
| Coût BUILD | 4 caps |

**Problème** : Vega n'est pas lisible dans le concept BUILD/CONSUME. Canon à Eau, Bobine Tesla, Industrial Fan ont chacun un phénomène évident. Vega est un vestige de l'ancien projet.

**Options à trancher** :
- Donner à Vega un phénomène CONSUME clair (ex : zone de snipe, marque de zone)
- Le remplacer par une tour qui s'inscrit mieux dans la logique élémentaire
- Le garder comme tour "pure DPS" sans phénomène, si cette niche est utile

---

## 4. LES PHÉNOMÈNES (CARTES CONSUME)

> Rappel : un phénomène DOIT être plus puissant qu'une tour.

Les phénomènes sont des zones temporaires créées en défaussant une carte.
Rayon et durée sont modifiables par les bonus (Zone Étendue, Persistance).

### 🟢 WATER_POOL — validé
- **Durée** : 6s
- **Rayon** : 96
- **Effet** : applique WET toutes les 0.5s aux ennemis dans la zone
- **Réaction croisée** : ennemi CHARGED dans la zone → **⚡ COURT-CIRCUIT !** (35 dégâts, stun 2.5s, cooldown 4s/ennemi)

### 🟢 ELECTRIC_FIELD — validé
- **Durée** : minimum 10s
- **Rayon** : 96
- **Effet** : applique CHARGED + 5 dégâts toutes les 0.25s à tous les ennemis
- **Réaction croisée** : ennemi WET dans la zone → stun 2s + "⚡ PARALYSÉ !"
- Flash d'entrée spectaculaire, arcs électriques animés

> ⚠️ Ces deux phénomènes sont à valider en priorité. Sont-ils amusants ? Est-ce que leur interaction crée un moment "AH OUAIS" ?

### 🟡 WIND_CURRENT — implémenté, à évaluer
- **Durée** : 6s
- **Rayon** : 96
- **Effet** : applique WINDMARK toutes les 0.5s
- **Knockback** : toutes les 3 secondes, repousse de 55px + rafale visuelle cyan

### 🔴 FIRE_ZONE — non implémenté
- Applique BURNING *(statut sans effet pour l'instant)*

### 🔴 THORN_PATCH — non implémenté
- Applique ROOTED *(statut sans effet pour l'instant)*

> Recommandation : se concentrer sur Water Pool + Electric Field jusqu'à validation du fun. Ajouter Wind/Fire/Thorn ensuite seulement.

---

## 5. LES RÉACTIONS

> Rappel : une réaction majeure DOIT être plus puissante qu'un phénomène.
> Le joueur doit dire "AH OUAIS." quand ça se déclenche.

### Mini Shock (automatique, faible)
- **Condition** : ennemi WET + CHARGED simultanément
- **Dégâts** : 8 base (+ bonus Court-Circuit)
- **Cooldown** : 1.0s par ennemi
- **Rôle** : réaction de base, lisible, compréhensible même sans lire les règles

### Électrocution (majeure, via ElectrocutionZone)
- **Condition** : déclenchée explicitement (carte CONSUME ou mécanique future)
- **Burst initial** : 40 dégâts (× Électrocution Fatale) + stun 3s
- **Ticks** : 15 dégâts / 0.35s pendant 3.5s
- **Rayon** : 112
- **Visuel** : arcs électriques, rayons depuis le centre, flash d'entrée
- **Ambition** : doit être le moment où la vague bascule

### Court-Circuit (Water Pool + ennemi CHARGED)
- **Condition** : ennemi CHARGED dans une zone Water Pool
- **Dégâts** : 35 (× Électrocution Fatale)
- **Stun** : 2.5s (+ Paralysie Prolongée)
- **Cooldown** : 4s par ennemi
- **Visuel** : flash cyan, arcs courts

### PARALYSÉ (Electric Field + ennemi WET)
- **Condition** : ennemi WET dans un Electric Field
- **Stun** : 2s supplémentaires
- **Visuel** : texte "⚡ PARALYSÉ !"

---

## 6. LES STATUTS

| Statut | ID | Effet actuel | État |
|---|---|---|---|
| WET | `wet` | Permet Mini Shock si CHARGED. Tick dégâts si Flaque Toxique. | ✅ |
| CHARGED | `charged` | Permet Mini Shock si WET. Court-Circuit si dans Water Pool. | ✅ |
| STUNNED | `stunned` | Vitesse = 0 pendant la durée. | ✅ |
| WINDMARK | `windmark` | Appliqué par Industrial Fan. Effet synergique à définir. | 🟡 |
| BURNING | `burning` | Statut codé, aucun effet pour l'instant. | 🔴 |
| ROOTED | `rooted` | Statut codé, aucun effet pour l'instant. | 🔴 |

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

### ExplosiveMob *(comportement à définir)*
| Stat | Valeur |
|---|---|
| HP | 100 |
| Vitesse | 150 px/s |
| Vague | 3 |

**Knockback** : cooldown de 3s par ennemi. Recul instantané de N pixels + freeze 0.3s.

---

## 8. LES VAGUES

| Vague | Ennemi | Nombre | Intervalle | Vitesse |
|---|---|---|---|---|
| 1 | SimpleMob | 6 | 3.0s | 200 px/s |
| 2 | TankMob | 3 | 5.0s | 80 px/s |
| 3 | ExplosiveMob | 6 | 3.0s | 100 px/s |

**Design vague 2** : 3 tanks très lents et très résistants. Avec 2 tours seules, le joueur passe tout juste. Il faut utiliser au moins un CONSUME pour s'en sortir confortablement. Cette vague valide la mécanique BUILD/CONSUME.

**Temps de préparation** : 20 secondes entre chaque vague.

---

## 9. LES BONUS (RÉCOMPENSES INTER-VAGUES)

Après chaque vague, le joueur choisit 1 bonus parmi une sélection.

### Bonus Tours
| Titre | Rareté | Effet |
|---|---|---|
| Munitions Renforcées | COMMON | +8 dégâts à toutes les tours |
| Canon Long | COMMON | +40 portée à toutes les tours |
| Mécanisme Huilé | RARE | Cadence de tir +25% |

### Bonus Eau
| Titre | Rareté | Effet |
|---|---|---|
| Canon à Eau Modifié | RARE | Statut WET dure 2s de plus |
| Flaque Toxique | RARE | Les ennemis WET subissent 3 dégâts/s |

### Bonus Électricité
| Titre | Rareté | Effet |
|---|---|---|
| Court-Circuit | COMMON | Mini Shock inflige +10 dégâts |
| Bobine Surchargée | EPIC | Mini Shock se déclenche 2× plus souvent |
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
| Fouille des Décombres | RARE | Pioche 1 carte supplémentaire après vague (max 4) |

---

## 10. SYNERGIES CONFIRMÉES

| Combo | Résultat |
|---|---|
| Tour Eau + Tour Électrique | Mini Shock automatique (WET + CHARGED) |
| Electric Field + ennemi WET | Stun 2s + PARALYSÉ |
| Water Pool + ennemi CHARGED | Court-Circuit (35 dégâts + stun 2.5s) |
| Tour Eau placée près d'un Electric Field | Cible en priorité les ennemis dans le champ |
| CONSUME Industrial Fan | Le phénomène repousse, la tour ralentit |

---

## 11. À FAIRE / À DÉCIDER

### Priorité 1 — valider le fun
- [ ] **BUILD = 4 / CONSUME = 2 / 15 caps** : implémenter et tester
- [ ] **La vague 2 valide-t-elle BUILD/CONSUME ?** Jouer sans CONSUME, puis avec. Est-ce décisif ?
- [ ] **Water Pool + Electric Field** : sont-ils assez puissants pour créer un "AH OUAIS" ?

### Priorité 2 — design en attente
- [ ] **Vega** : garder, refondre ou supprimer ? Doit avoir un phénomène CONSUME ou une niche claire
- [ ] **WINDMARK** : quel effet synergique ? (ex : les ennemis marqués subissent plus de dégâts ?)
- [ ] **ExplosiveMob** : explose à la mort ? dégâts de zone ?
- [ ] **BURNING / ROOTED** : statuts à connecter à des phénomènes futurs (Fire Zone, Thorn Patch)

### Priorité 3 — contenu futur
- [ ] **Nouvelles tours** liées aux phénomènes Fire et Thorn
- [ ] **Cartes récompenses** : créer les CardData pour distribuer les 14 bonus
- [ ] **Vague 4+** : progression et boss

### Technique
- [ ] **Anciens bonus** (sharpened_ammo, long_barrel, etc.) : à nettoyer ou remplacer par les 14 nouveaux
- [ ] **base_damage de Vega** : null dans le .tscn, à fixer
- [ ] **Description industrial_fan_card** : dit encore "Knockback toutes les 3s" — à corriger

---

## 12. ARCHITECTURE TECHNIQUE (RÉFÉRENCE RAPIDE)

| Script | Rôle |
|---|---|
| `card_manager.gd` | Main, pioche, BUILD, CONSUME |
| `wave_manager.gd` | Spawn des vagues, prep phase, récompenses |
| `reaction_manager.gd` | Vérifie WET+CHARGED → Mini Shock chaque frame |
| `phenomenon_manager.gd` | Crée et suit les phénomènes actifs |
| `phenomenon.gd` | Logique d'une zone (contamination, dégâts, knockback) |
| `enemy_base.gd` | HP, statuts, slow, knockback, mort |
| `base_tower.gd` | Stats, cadence, ciblage, bonus de run |
| `run_bonuses.gd` | Autoload — getters agrégés sur tous les bonus possédés |
| `player_data.gd` | Autoload Player — caps, HP de base, numéro de vague |

### Règles de la main
```
max_hand_size    = 4
refill_hand_size = 3   (pioche automatique fin de vague)
mulligan vague 1 = max 3 cartes échangées
échange vague 2+ = max 1 carte échangée
```

### Coûts
```
BUILD   = 4 caps  (pose une tour permanente)
CONSUME = 2 caps  (phénomène temporaire mais plus puissant)
Caps de départ = 15
```
