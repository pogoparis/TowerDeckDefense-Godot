> # ⛔ DOCUMENT OBSOLÈTE — NE PAS S'Y FIER
>
> Archivé le 5 septembre 2026. Il décrit un état du jeu qui n'existe plus et
> **contredit la réalité sur des points structurants** :
>
> - la **Ferraille** (15 mentions) n'existe plus : une seule monnaie, les Caps ;
> - les coûts d'amélioration y sont de 3 et 6 (ils sont de 35 et 80) ;
> - « Huile de Vidange » s'appelle désormais **Citerne Crevée** ;
> - les tables de tours/ennemis y sont périmées.
>
> **Documents à jour :**
> - `JUNKRIOT_GDD_v3.0.md` — diagnostic, vision, feuille de route
> - `JUNKRIOT_CONTENU_V1.md` — éléments, tours, sorts, réactions, ennemis, decks
> - `JUNKRIOT_RECOMPENSES.md` — le système de récompenses
>
> Conservé uniquement pour l'historique des décisions de design.

---

# JUNKRIOT — Game Design Document v2.3

**Tower Defense Deckbuilder — Punk Post-Apocalyptique**
Moteur : Godot 4 — Solo dev — Document de référence interne
Dernière mise à jour : Septembre 2026

---

## CHANGELOG v2.2 → v2.3

Passe d'équilibrage : le jeu manquait d'une raison de CHOISIR un deck.

1. **Affinités élémentaires** — chaque type d'ennemi a une **faiblesse** (dégâts ×2)
   et une **résistance** (×0.5). C'est le pilier qui transforme le choix de deck
   en décision : on prend le Brasier parce que le niveau est plein de Drones,
   pas par goût. Voir section 10bis.
2. **Blindage (`armor`)** — réduction FORFAITAIRE par coup, sur les mobs tardifs.
   Nouvel axe de difficulté : punit les tours rapides/faibles, épargne les
   grosses frappes. Force à varier le deck au lieu d'empiler la même tour.
3. **Nouveau mob : le Drone Jaune** — rapide, blindé, volant. Arrive V6.
4. **Plafond de 3 tours signature** sur le terrain : au-delà, « DÉCLENCHER »
   devenait du clic de routine. Deck Brasier recomposé (8 signatures sur 10 → 4).
5. **Grille 17×8 en cases de 96 px** (au lieu de 12×6 en 128) : même surface,
   136 emplacements au lieu de 72.
6. **Économie recalée** : prime de fin de vague 3 caps fixes → `10 + 2 × vague`.
7. **Le coût affiché vient de `mana_cost`**, plus du chiffre peint sur l'art.
8. **Nouvelle tour : le Pingouin Punk** (Glace) — givre cumulatif, contrôle
   durable là où l'Eau et l'Air n'agissent que par à-coups.
9. **Deux nouvelles réactions** : CRYOGÉNISATION (💧+❄) et TEMPÊTE DE SABLE
   (🪨+🌪). La Terre et la Glace ne posaient aucun statut, elles étaient donc
   hors du système de réactions. Voir section 8.
10. **Les réactions sont affichées dans les tooltips de cartes**, indexées par
   élément. Une difficulté qui repose sur des combos invisibles est un piège,
   pas un défi.
11. **`enemy_hp_growth` 1.18 → 1.10.** Cumulé à la montée des effectifs, 1.18
   rendait le niveau 2 mathématiquement infaisable dès la V9 (454 DPS requis
   pour un plafond joueur de 289), quel que soit le deck.
12. **`upgrade_costs` [3, 6] → [6, 15].** Voir section 9.
13. **Le plan de vagues est refondu** : catalogue d'ennemis + roster déclaré par
   niveau, au lieu de colonnes fixes. Ajouter un ennemi = une entrée dans
   `ENEMIES` + son id dans les rosters concernés ; briefing, part des PV,
   élément clé et couverture des decks en découlent automatiquement.

---

## CHANGELOG v2.1 → v2.2

Rework du **core loop** après challenge du design. Décisions actées :

1. **La Charge n'est plus sur toutes les tours — seulement sur les tours SIGNATURES** (1 par élément au départ, ajustable en playtest). Raison : une jauge active par tour = surcharge cognitive sur mobile + décision qui s'effondre en « je tape dès que ça brille ». L'attention active doit rester rare et précieuse.
2. **Les Cartes Sort deviennent jouables PENDANT la vague** (elles étaient interdites en v2.1). C'est le verbe actif qui manquait au joueur pendant les vagues.
3. **Les Cartes Sort entrent dans le MVP** (elles étaient post-MVP en v2.1). Elles musclent la couche deck : le deck contient Tours + Sorts, les Sorts sont consommables → le deck **cycle vraiment**.
4. **Abandon du mécanisme CONSUME / « phénomène par défausse de carte »** (divergence code jamais actée dans le GDD). Le moteur de zones (`spawn_phenomenon`) est **conservé et recyclé** comme *résultat* d'une Charge ou d'un Sort — on jette le déclencheur, pas la tech.
5. **Noms de tours réconciliés avec les vrais assets** (ex : la tour Feu signature = **Punk Explosif**, un bombardier, pas le fictif « Brasero Punk »).

**Les deux économies actives de la nouvelle boucle :**
- **Charge** — liée à la *tour*, se remplit en tirant → récompense le **placement**.
- **Sort** — lié à la *main*, consommable, coûte des Caps → récompense la **gestion de deck**.

---

## TABLE DES MATIÈRES

1. Vision & Pitch
2. Boucle de jeu complète
3. Les ressources
4. Les cartes & le deck
5. Les Sorts (NOUVEAU)
6. Les tours & les éléments
7. Le système de Charge (signatures)
8. Les interactions élémentaires
9. Les upgrades
10. Les ennemis
10bis. Affinités élémentaires & blindage
11. Structure d'une run (MVP)
12. L'interface utilisateur
13. Ce qu'on ne fait PAS pour le MVP
14. Roadmap technique

---

## 1. VISION & PITCH

**En une phrase**
> « Place tes tours depuis ta main, charge tes signatures, balance tes sorts au bon moment — combine les éléments pour survivre. »

**Concept**
Junkriot est un tower defense où les tours ne s'achètent pas dans un menu — elles se **piochent depuis un deck de cartes**. Le joueur défend son squat punk contre des vagues de pillards mutants dans un monde post-apocalyptique.

Le jeu repose sur **quatre couches de décision** :
- **Spatiale** (TD classique) — où je place mes tours, quelles zones je couvre.
- **Économique** (ressources) — quand je dépense mes Capsules de bière et ma Ferraille.
- **Temporelle — Charge** (tour-bound) — quand je déclenche la Charge d'une tour signature.
- **Tactique — Sorts** (main-bound) — quel sort je pioche et quand je le balance pendant la vague.

**Références**
- Tower defense : Bloons TD 6 (north star — le « pop pop pop »), Plants vs Zombies (lisibilité), Kingdom Rush (profondeur, capacités rares).
- Deckbuilding : Slay the Spire (cycle deck/main/défausse).
- Réactivité carte-en-main : Clash Royale (jouer une carte pendant l'action, ergonomie mobile).
- Ambiance : SteamWorld Dig, Mad Max, Borderlands.

**Plateforme cible**
- Mobile Android (cible principale) — Godot 4, export Android natif.

---

## 2. BOUCLE DE JEU COMPLÈTE

**DÉBUT DE PARTIE**
- Choix du deck thématique (MVP : Deck Brasier).
- 3 cartes piochées en main.
- Phase de placement initial (10 Caps de départ → 1-2 tours faibles).

**VAGUE EN COURS**
- Les tours tirent automatiquement ; les ennemis avancent ; Caps et Ferraille droppent.
- Actions disponibles :
  - ⚡ **Déclencher la Charge** d'une tour signature (clic) — si jauge pleine.
  - 🃏 **Jouer un Sort** depuis la main (drag sur le terrain) — coûte des Caps. *(NOUVEAU v2.2)*
  - 🔩 **Upgrader** une tour (si Ferraille dispo).
- Actions NON disponibles pendant la vague :
  - ❌ Poser une nouvelle tour (carte Tour).
  - ❌ Défausser/piocher (swap de carte).

**ENTRE LES VAGUES**
- Bonus fixe : +5 Caps.
- Poser des tours depuis la main ; upgrader ; swap 1 carte (défausser 1 → piocher 1, optionnel).
- Le joueur valide manuellement quand il est prêt (pas de timer).

**FIN DE RUN**
- Victoire : Boss de la vague 5 éliminé. Défaite : Squat à 0 HP.

---

## 3. LES RESSOURCES

Trois ressources distinctes, usage exclusif chacune.

### 🍺 Capsules de Bière — Monnaie principale
- **Thème** : capsules récupérées dans les ruines, monnaie universelle du squat.
- **Utilisation** : poser une carte Tour (entre les vagues) **ET** jouer une carte Sort (pendant la vague). *(NOUVEAU : les Sorts se paient aussi en Caps → tension « sort maintenant vs. tour au prochain inter-vague ».)*
- **Gains** : Pillard/Runner +1 · Kamikazé +2 · Tank +3 · Boss +10 · Bonus fin de vague +5.
- **Départ** : 10 🍺. S'accumulent sans limite, ne se perdent pas entre les vagues.

### 🔩 Ferraille — Monnaie d'upgrade
- **Thème** : boulons et pièces récupérés sur les ennemis vaincus.
- **Utilisation** : améliorer une tour posée (niveau 1 → 2 → 3).
- **Drop aléatoire** : Pillard/Runner 20 % (1) · Kamikazé 35 % (1-2) · Tank 60 % (2-3) · Boss 100 % (5).
- **Départ** : 0 🔩. Upgrades dispo pendant ET entre les vagues.

### ⚡ Charge — Énergie de tour (signatures uniquement)
- **Thème** : l'énergie punk accumulée par une tour signature en combattant.
- **Utilisation** : déclencher l'effet massif d'une **tour signature** (clic).
- **Gain** : +1 barre par tir qui touche un ennemi (uniquement sur les tours signatures).
- Jauge 0→5 (niv.1) jusqu'à 0→7 (niv.3). Ne se vide pas entre les vagues. Déclenchement → jauge à 0 + cooldown 15 s (tire mais n'accumule plus).

---

## 4. LES CARTES & LE DECK

### Composition
- **Taille fixe : 10 cartes** pour le MVP.
- **Mix Tours + Sorts** : ~6 cartes Tour + ~4 cartes Sort. *(NOUVEAU : les Sorts consommables font enfin cycler le deck.)*

### Types de cartes (MVP)
- **Carte Tour** — pose une tour permanente. Contient : nom, élément, coût 🍺, stats de base, illustration.
- **Carte Sort** — effet ponctuel jouable **pendant** la vague. Contient : nom, effet, coût 🍺, rôle (contrôle / dégât), illustration. *(NOUVEAU dans le MVP — voir §5.)*

### La main
| Règle | Valeur |
|---|---|
| Cartes en main au départ | 3 |
| Max en main | 4 |
| Cartes **Tour** jouables pendant la vague | ❌ Aucune |
| Cartes **Sort** jouables pendant la vague | ✅ Oui *(NOUVEAU)* |
| Cartes jouables entre les vagues | ✅ Toutes (Tours + Sorts) |

### Poser une tour (entre les vagues)
Sélection carte → coût 🍺 affiché (grisée si insuffisant) → clic cellule libre → tour posée, Caps déduites, carte à la défausse. Tour **permanente**.

### Jouer un Sort (pendant ou entre les vagues) — NOUVEAU
Sélection carte Sort → coût 🍺 affiché → drag/tap sur la cible (point au sol ou tour selon le sort) → effet appliqué, Caps déduites, carte à la défausse.

### Le cycle du deck
DECK → pioche → MAIN (3-4) → jouer une carte → DÉFAUSSE → reshuffle quand le deck est vide.

### Swap (entre les vagues)
Une fois par inter-vague : défausser 1 → piocher 1 (optionnel, indissociable).

---

## 5. LES SORTS (NOUVEAU)

Les Sorts sont le **verbe actif** du joueur pendant la vague et le moteur qui muscle le deck.

**Règle d'équilibrage** : **contrôle = bon marché / dégâts = cher**. Ainsi les Sorts complètent les tours (urgence, contrôle) sans les remplacer ; les Sorts-dégâts restent des coups d'éclat ponctuels.

### Sorts de départ — Deck Brasier (Feu + Électricité)

| Sort | Rôle | Coût | Effet | Synergie / note |
|---|---|---|---|---|
| **Court-Circuit** ⚡ | Contrôle | Bas | Zone : stun 1.5 s + applique **CHARGED** | Tes tours Feu tapent +30 % sur les CHARGED |
| **Huile de Vidange** 🛢️ | Contrôle | Bas | Flaque au sol : ralentit -40 % | S'enflamme si un molotov du bombardier tombe dedans (mini-combo) |
| **Overdrive** 🔧 | Buff | Bas/moyen | Cible 1 tour : +100 % cadence pendant 5 s | Accélère le remplissage de **Charge** d'une signature → dialogue entre les deux économies actives |
| **Frappe de Ferraille** 💥 | Dégâts | Élevé | Gros burst AoE à un point + applique BURNING | Coup d'urgence |
| **Orage Punk** ⚡ | Dégâts | Élevé/rare | Éclair en chaîne sur 4-5 ennemis | Le « gros » sort |

Toutes les valeurs sont MVP, à équilibrer en playtest. Le moteur de zones existant (`spawn_phenomenon`) matérialise les zones de Sort.

---

## 6. LES TOURS & LES ÉLÉMENTS

### Les 5 éléments
Pour le MVP : **Feu** et **Électricité** (Deck Brasier). Les autres arrivent avec les decks suivants.

| Élément | Dégâts | Statut appliqué | Couleur |
|---|---|---|---|
| 🔥 Feu | DoT | BURNING | Orange/Rouge |
| ⚡ Électricité | Burst | CHARGED | Jaune/Blanc |
| 💧 Eau | Ralentissement | WET | Bleu |
| 🌿 Nature | Poison | POISONED | Vert |
| 💨 Air | Knockback | — | Blanc/Gris |

### Les statuts ennemis
Un seul statut actif à la fois (un nouveau remplace l'ancien).

| Statut | Effet | Durée |
|---|---|---|
| BURNING 🔥 | Perd X HP/s | 4 s |
| CHARGED ⚡ | +50 % dégâts électriques | Jusqu'au prochain hit électrique |
| WET 💧 | Vitesse -40 % | 3 s |
| POISONED 🌿 | Perd X HP/s (plus lent que BURNING) | 6 s |

### Roster de tours — état réel

**Implémentées (assets + scènes existants) :**

| Tour (nom réel) | Élément | Rôle | Signature ? |
|---|---|---|---|
| **Punk Explosif** (bombardier, molotovs) | 🔥 Feu | Signature Feu | ✅ Porte une Charge |
| **Ours Éclair** | ⚡ Électricité | Signature Élec | ✅ Porte une Charge |
| Requin | 💧 Eau | (autre deck) | — |
| Chouette | 💨 Air | (autre deck) | — |
| Punk Rose | ❄️/💧 | (autre deck) | — |

**Prévues (pas encore implémentées) :** tours Feu et Élec « de base » (auto-fire simple, sans Charge) pour étoffer le Deck Brasier autour des signatures — ex. une tour Feu basique et une tour Élec basique. *(Les cartes « Tour de Feu » et « Vega » existent en .tres mais les tours ne sont pas réellement implémentées à ce jour.)*

> **Design cible du Deck Brasier** : 1-2 tours de base par élément (auto-fire, cheap) + la signature de chaque élément (Charge). Les tours de base font le DPS de fond ; les signatures apportent le pic actif.

---

## 7. LE SYSTÈME DE CHARGE (signatures)

### Principe
Seules les **tours signatures** possèdent une jauge de Charge (visible au-dessus d'elles). Elle se remplit à chaque tir qui touche un ennemi. *(Les tours de base n'ont PAS de jauge — elles tirent, point.)*

### Jauge selon le niveau
| Niveau de tour | Barres max |
|---|---|
| Niveau 1 (base) | 5 |
| Niveau 2 (upgrade 1) | 6 |
| Niveau 3 (upgrade 2) | 7 |

### Déclencher
Clic sur une signature à jauge pleine → effet immédiat → jauge à 0 → **cooldown 15 s** (tire normalement mais n'accumule pas de Charge ; icône de cooldown visible).

*Note de design : autoriser le déclenchement dès 3/5 barres (effet réduit) est à tester en playtest.*

### Effets de Charge des signatures (MVP)
| Signature | Élément | Effet de Charge |
|---|---|---|
| **Punk Explosif** | 🔥 Feu | **Bombardement napalm** — zone BURNING au sol (grande zone, plusieurs secondes) |
| **Ours Éclair** | ⚡ Électricité | **Tempête de foudre** — chaîne massive rebondissant sur 4-6 ennemis |

### Transfert de Charge (bonus d'adjacence)
Quand une signature déclenche sa Charge, elle transfère **1 barre** à chaque tour adjacente compatible (signature) — 4 cases directes uniquement.

---

## 8. LES INTERACTIONS ÉLÉMENTAIRES

> **Section de référence.** Elle décrit ce qui EXISTE dans le code
> (`reaction_manager.gd`, `phenomenon.gd`, `synergy_library.gd`).
> Toute réaction ajoutée au code doit être ajoutée ici, et inversement.

### 8.1 Les éléments

| Élément | Tour porteuse | Statut appliqué | Rôle |
|---|---|---|---|
| 🔥 Feu | Punk Explosif *(signature)* | `BURNING` — dégâts sur la durée | Burst + zone |
| ⚡ Électricité | Ours Éclair *(signature)* | `CHARGED` | Burst + chaîne |
| 🪨 Terre | Gardien Rocheux *(signature)* | `DUSTY` — poussière de roche | Grosse frappe anti-blindé |
| 🦇 Ombre | Vampire *(signature)* | `MARKED` — +40 % de dégâts subis | Amplificateur d'équipe |
| 💧 Eau | Requin Cracheur | `WET` | Marqueur de combo |
| 🌪 Air | Souffle-Chouette | `WINDMARK` + repoussée | Contrôle bref |
| ❄ Glace | Pingouin Punk | `CHILLED` — givre cumulatif | Contrôle durable |
| ✨ Lumière | Luciole | — | Halo : +25 % dégâts aux tours voisines |

**Règle** : une tour sans statut ne participe à aucune réaction. C'est ce qui
avait mis la Terre et la Glace hors-jeu jusqu'à ce qu'on leur en donne un.

### 8.2 Réactions statut × statut (tours de base)

Passives : dès qu'un ennemi porte les deux statuts, la réaction part. Chacune a
son propre cooldown par ennemi.

| Combinaison | Réaction | Effet |
|---|---|---|
| 💧 + ❄ | **CRYOGÉNISATION** | **Arrêt complet 2 s** + 14 dégâts. Consomme le WET |
| 🪨 + 🌪 | **TEMPÊTE DE SABLE** | 16 dégâts dans un rayon de 130 + ralentissement ×0.6 (2.5 s). Consomme la poussière |
| 💧 + ⚡ | **ÉLECTROCUTION** | Décharge répétée + stun |
| 💧 + 🔥 | VAPEUR | 8 dégâts |
| 🔥 + ⚡ | SURCHAUFFE | 8 dégâts |
| 🌪 + 🔥 | ATTISÉ | 7 dégâts |
| 🌪 + ⚡ | DÉCHARGE | 7 dégâts |
| 💧 + 🌪 | ÉCLABOUSSURE | 6 dégâts |

Les deux premières **consomment** un statut : ce sont des arbitrages (on dépense
le givre pour figer), pas des multiplicateurs permanents.

### 8.3 Phénomènes de zone (Charges des signatures)

Un phénomène est une flaque posée au sol — position, rayon, durée — qui agit sur
tout ennemi qui la traverse. Seules les **Charges** en posent aujourd'hui.

| Tour | Charge → phénomène | Rayon | Durée |
|---|---|---|---|
| Punk Explosif | `FIRE_ZONE` | 170 | 8 s |
| Ours Éclair | `ELECTRIC_FIELD` | 150 | 7 s |
| Vampire | `SHADOW_ZONE` | 160 | 8 s |
| Gardien Rocheux | `STONE_RAIN` | 180 | 6 s |

*Types définis mais sans porteur : `WATER_POOL`, `WIND_CURRENT`, `THORN_PATCH`.*

### 8.4 Réactions zone × zone

Quand deux phénomènes de types différents se **chevauchent**, ils fusionnent.
Ce sont les grosses réactions — le « pop pop pop ».

| Combinaison | Réaction | Effet |
|---|---|---|
| 💧 Flaque + 🔥 Feu | **VAPEUR** | 80 dégâts **+ 15 % des PV max**, ralentit ×0.2 pendant 5 s |
| 🔥 Feu + 🌪 Bourrasque | **TORNADE DE FEU** | 60 dégâts + 12 % des PV max, BURNING 5 s |
| 💧 Flaque + 🌪 Bourrasque | **TEMPÊTE** | WET de masse + repoussée |
| ⚡ Champ + 🔥 Feu | **SURCHARGE** | — |
| ⚡ Champ + 🌪 Bourrasque | **ORAGE** | Frappes de foudre répétées |

Le `+ % des PV max` est ce qui rend la Vapeur redoutable sur les Tanks : elle ne
dépend pas des dégâts des tours.

### 8.5 Communiquer les réactions — non négociable

Une difficulté qui repose sur des combos invisibles n'est pas un défi, c'est un
piège. Le tooltip d'une carte affiche donc **l'élément de la tour et toutes les
réactions auxquelles il participe**, avec l'élément partenaire.

Ces descriptions sont indexées **par élément, pas par nom de tour**
(`synergy_library.gd`) : une nouvelle tour de Glace hérite automatiquement des
réactions de la Glace, sans rien modifier.

---

## 9. LES UPGRADES

Améliorer n'importe quelle tour posée en dépensant de la **Ferraille 🔩**. Disponible pendant ET entre les vagues.

| Upgrade | Coût 🔩 | Bonus (multiplicatifs) |
|---|---|---|
| Niveau 1 → 2 | **6** | ×1.6 dégâts / ×0.88 cadence / ×1.12 portée / Charge max +1 |
| Niveau 2 → 3 | **15** | idem, cumulé → ×2.56 dégâts au total / Charge max +2 |

Total niveau 3 : **21 🔩**.

**Pourquoi 6/15 et pas 3/6.** Un niveau rapporte environ 204 ferrailles. À 9 🔩
la tour, le joueur pouvait en maxer 22 — donc toutes. L'amélioration n'était
plus une décision, juste une corvée de clics. À 21 🔩 il en max une dizaine au
maximum, et doit choisir lesquelles méritent l'investissement.

Feedback : apparence légèrement modifiée (particules, taille +5 %), étoile de
niveau affichée, jauge de Charge qui reflète le nouveau max immédiatement.

---

## 10. LES ENNEMIS

Tous suivent un chemin fixe de waypoints (non déviables sauf knockback temporaire). À l'arrivée au Squat, dégâts + disparition.

| Nom | HP | Vitesse | Dégâts Squat | 🍺 | 🔩 | Particularités |
|---|---|---|---|---|---|---|
| Pillard Basique | 50 | 60 px/s | 1 | +1 | 20 %/1 | Aucune |
| Runner Mutant | 30 | 130 px/s | 1 | +1 | 20 %/1 | Immunisé knockback |
| Tank Blindé | 200 | 30 px/s | 2 | +3 | 60 %/2-3 | Armure physique 50 % / marche↔roulade |
| Kamikazé | 40 | 90 px/s | 1 | +2 | 35 %/1-2 | Explose à la mort (AoE 50px, 5 dégâts aux ennemis) |
| Boss — War Rig | 1500 | 20 px/s | 5 | +10 | 100 %/5 | Régén 5 HP/s / immunisé aux statuts |

**Tank Blindé** : états WALK / ROLL (vitesse ×2, aléatoire 3-7 s, durée 2-4 s) / ROLL_ENRAGED (roulade permanente à HP ≤ 50 %). L'armure physique 50 % ne s'applique PAS aux dégâts élémentaires.
**Kamikazé** : à la mort, explose (rayon 50px, 5 dégâts aux ennemis ; les tours ne prennent PAS de dégâts au MVP).

---

---

## 10bis. AFFINITÉS ÉLÉMENTAIRES & BLINDAGE

### Pourquoi ce système existe

Sans lui, un deck se choisit par goût : toutes les tours font des dégâts, la
seule question est « laquelle en fait le plus ». Les affinités posent la vraie
question du genre : **« qu'est-ce qui m'attend, et qu'est-ce qui répond à ça ? »**
C'est ce qui rend l'écran de choix de deck signifiant, et ce qui donne envie de
rejouer un niveau avec l'autre deck.

### Les règles

| Cas | Multiplicateur | Ressenti visé |
|---|---|---|
| Bon élément (faiblesse) | **×2.0** | Le chiffre saute aux yeux (vert vif, gros) |
| Élément quelconque | ×1.0 | Neutre |
| Mauvais élément (résistance) | **×0.5** | Chiffre gris et petit : « ça glisse » |

**×2 / ×0.5 et pas ×1.3 / ×0.8** : en dessous de ce seuil le joueur ne *perçoit*
pas la différence, et un système imperceptible n'existe pas. Jamais ×0 : un
élément totalement inutile rendrait un deck injouable sur un niveau, ce qui
punit un choix fait avant d'avoir l'information complète.

### Ordre de calcul des dégâts

```
dégâts bruts
  → × affinité élémentaire   (×2 / ×1 / ×0.5)
  → − blindage               (plancher à 1)
  → × 1.4 si Marque d'Ombre
```

L'affinité passe **avant** le blindage : le bon élément aide donc à *percer*
une armure. Dans l'ordre inverse, on soustrait d'abord et on double ensuite —
la bonne réponse ne serait presque plus récompensée sur les cibles blindées.
La Marque d'Ombre passe **en dernier** : le Vampire amplifie ce qui traverse
réellement, ce qui en fait un multiplicateur d'équipe et non un substitut au
bon élément.

### Le blindage (`armor`)

Réduction **forfaitaire** retirée à chaque coup — pas un pourcentage. C'est ce
qui en fait un axe distinct des PV :

| Tour | Dégât brut | Contre `armor 4` | Perte |
|---|---|---|---|
| Luciole / tirs rapides | 5 | 1 | −80 % |
| Vampire | 6 | 2 | −67 % |
| Gardien Rocheux | 16 | 12 | −25 % |

Empiler dix tours rapides cesse de fonctionner : il faut une grosse frappe, du
ralentissement, ou le bon élément. Plancher à 1 dégât — blindé ne veut jamais
dire invincible.

### Table des affinités

| Ennemi | Faible contre | Résiste à | Blindage | Logique |
|---|---|---|---|---|
| Pillard | — | — | 0 | Chair à canon : aucune règle à apprendre au début |
| Kamikazé | 🔥 Feu ×2 | ⚡ Électricité | 0 | Bidon d'essence : ça s'enflamme |
| Tank | 🪨 Terre ×2 | 🔥 Feu | 0 | Blindé : on l'écrase, on ne le brûle pas |
| Drone Jaune | ⚡ Électricité ×2 | 🪨 Terre | **4** | Électronique, et la pluie de pierre rate ce qui vole |
| MiniBoss | — | 🦇 Ombre | 0 | Un boss n'a pas de raccourci élémentaire : il se gagne par la puissance de feu |

Construction voulue : **aucun deck ne couvre tout**.
- **Brasier** (Feu, Électricité, Ombre, Glace, Air, Lumière) → excelle contre Kamikazés, Drones et MiniBoss ; peine sur les Tanks.
- **Roche** (Terre, Eau, Air, Lumière) → écrase les Tanks et le MiniBoss ; souffre face aux Drones.

### Communiquer l'information — non négociable

Un système de faiblesses caché est une punition, pas une décision. Deux canaux :

1. **Avant** — l'écran de choix de deck affiche un encart « ⚠ CE QUI T'ATTEND »
   listant chaque menace avec sa faiblesse, sa résistance et son blindage. Ces
   valeurs sont **lues sur les scènes d'ennemis elles-mêmes**, donc le briefing
   ne peut jamais mentir après un rééquilibrage.
2. **Pendant** — le chiffre de dégâts change d'apparence : **vert vif et large**
   quand c'est le bon élément, **gris et petit** quand ça résiste. Le joueur
   apprend la table en jouant, sans jamais l'avoir lue.

### Identité de menace par niveau

Un système d'affinités ne vaut que si les niveaux **diffèrent**. Avec une liste
de vagues unique, le briefing élémentaire décorerait un choix qui n'existe pas.
Chaque niveau a donc sa propre composition, pensée en miroir :

| Niveau | Identité | Composition | Deck favorisé | Deck en difficulté |
|---|---|---|---|---|
| 2 | **La Casse aux Tanks** — « Un mur de blindés. Ce qui brûle glisse ; ce qui écrase passe. » | Tanks omniprésents (62), drones anecdotiques (16) | **Roche** (🪨 ×2 sur Tank) | Brasier (🔥 résisté par le Tank) |
| 3 | **Le Nid de Drones** — « Une nuée rapide et blindée. Le sol ne rattrape pas ce qui vole. » | Drones massifs (91), kamikazés nombreux (84), tanks rares (20) | **Brasier** (⚡ ×2 sur Drone, 🔥 ×2 sur Kamikazé) | Roche (🪨 résisté par le Drone) |

Règle de conception : **un deck doit être un bon choix quelque part et un
mauvais ailleurs.** Un deck bon partout ne se choisit pas, il se subit.

### L'élément clé : conclure, pas lister

Lister quatre faiblesses n'aide personne — chaque deck en coche une et le choix
s'évapore. L'écran annonce donc **l'élément qui paie**, calculé en poids NET :

```
poids(élément) = PV frappés ×2 par cet élément
               − PV qui lui résistent
```

La soustraction n'est pas cosmétique. Sans elle, *Le Nid de Drones*
recommanderait la Terre (4 400 PV de tanks) alors que ses 91 drones la
résistent (11 830 PV) : un conseil qui enverrait le joueur dans le mur. **Un
élément à poids net négatif est un piège, pas une option** — il n'est jamais
affiché. Résultat :

| Niveau | Poids nets | Affiché |
|---|---|---|
| La Casse aux Tanks | Terre +11 560 · Élec −230 · Feu −11 330 | 🪨 **Terre** |
| Le Nid de Drones | Élec +5 950 · Feu +1 480 · Terre −7 430 | ⚡ **Électricité**, 🔥 Feu |

En regard, chaque deck affiche les éléments qu'il embarque (lus sur ses tours) :
la mise en correspondance est immédiate.

**Corollaire de design :** le MiniBoss a perdu sa faiblesse Lumière. Avec une
faiblesse sur chaque type d'ennemi, tous les niveaux réclamaient tous les
éléments et le système s'annulait lui-même. Moins de faiblesses, mieux réparties,
valent mieux qu'une table exhaustive.

### Où l'information est affichée

1. **Carte du monde** — le pin porte le nom du lieu (« La Casse aux Tanks ») et
   son élément clé (« 🪨 Terre »). Le joueur commence à réfléchir avant même
   l'écran de deck. Rien n'est divulgué sur un niveau encore verrouillé.
2. **Écran de choix de deck** — encart avec le titre, le pitch, puis chaque type
   d'ennemi avec son effectif total, sa faiblesse, sa résistance, son blindage.
3. **En jeu** — chiffre vert vif et large sur une faiblesse, gris et petit sur
   une résistance.

**Contrainte technique tenue :** le roster affiché est **calculé depuis le plan
de vagues** (`WaveLibrary.get_threat_roster`) et les faiblesses sont **lues sur
les scènes d'ennemis**. Rien n'est recopié à la main, donc un rééquilibrage ne
peut pas rendre le briefing menteur. Seuls le titre et le pitch sont éditoriaux.


## 11. STRUCTURE D'UNE RUN (MVP)

**Le Squat** : 20 HP. Chaque ennemi arrivé au bout inflige ses dégâts. 0 HP → défaite.

| Vague | Composition | Difficulté |
|---|---|---|
| 1 | 5 Pillards | Tutoriel |
| 2 | 4 Pillards + 3 Runners | Facile |
| 3 | 5 Pillards + 4 Runners + 1 Tank | Moyen |
| 4 | 2 Tanks + 5 Kamikazés + 6 Runners | Difficile |
| 5 | 4 Pillards + BOSS + 4 Pillards (escorte) | Boss |

Caps de départ : 10 🍺. Inter-vague sans timer (validation manuelle).

---

## 12. L'INTERFACE UTILISATEUR

**HUD pendant la vague** : Caps · HP Squat · progression vague. Terrain avec jauges de Charge visibles **sur les signatures**. Main en bas : cartes **Tour grisées** (non jouables), cartes **Sort actives** (jouables, coût affiché). *(NOUVEAU : distinction Tour/Sort dans la main pendant la vague.)*

**HUD entre les vagues** : toutes les cartes actives (Tours + Sorts), bouton Défausser, bouton Lancer la vague.

**Panneau d'une tour (clic)** :
```
Ours Éclair ⚡  Niv.2
Dégâts : 27   Portée : 143px
Charge : ████░ 4/6        ← uniquement si signature
[DÉCLENCHER ⚡]           ← actif si charge pleine (signature)
[UPGRADER 🔩6] Niv.3      ← actif si Ferraille dispo
```
*(Les tours de base n'affichent pas de ligne Charge ni de bouton Déclencher.)*

---

## 13. CE QU'ON NE FAIT PAS POUR LE MVP

| Feature | Statut | Raison |
|---|---|---|
| Charge sur les tours de base | ❌ Post-MVP | Réservée aux signatures (attention active rare) |
| Mécanisme CONSUME / phénomène par défausse | ❌ Abandonné | Remplacé par Charge (tours) + Sorts (main) |
| Construction de deck custom | ❌ Post-MVP | Trop tôt pour valider le core loop |
| Boutique entre les vagues | ❌ Post-MVP | Pas nécessaire avec deck fixe |
| Méta-progression (reliques, talents) | ❌ Post-MVP | Hors scope MVP |
| Plus de 2 éléments actifs | ❌ Post-MVP | Deck Brasier suffit pour valider |
| Destruction volontaire de tours | ❌ Post-MVP | Complexité vs intérêt à évaluer |
| Multijoueur | ❌ Jamais | Hors concept |
| Timer d'inter-vague | ❌ Indésirable | Le joueur doit pouvoir réfléchir |

---

## 14. ROADMAP TECHNIQUE (Godot 4)

État réel (le projet est plus avancé que la roadmap v2.1 ne le laissait croire) : terrain, spawner, tank.gd, économie (Caps/Ferraille), cartes (deck/main/défausse/mulligan), tours directionnelles, synergies d'adjacence, moteur de zones — **déjà en place**.

**Chantiers du rework v2.2 :**

**A — Nettoyage (retirer le CONSUME)**
- [ ] Retirer le bloc consume de `card_manager.gd` (start/confirm/cancel_consume, ghost).
- [ ] Retirer les champs `consume_*` de `card_data.gd`.
- [ ] Découpler `phenomenon_manager` du déclencheur carte (garder `spawn_phenomenon` comme service de zones).

**B — Système de Charge (signatures)**
- [ ] Flag `is_signature` + jauge (courante/max 5-7 selon upgrade) sur `base_tower.gd`.
- [ ] +1 barre par tir qui touche (hook dans la boucle de tir / à l'impact).
- [ ] UI jauge au-dessus des signatures uniquement.
- [ ] Clic signature pleine → effet élémentaire (via `spawn_phenomenon`) → reset + cooldown 15 s.
- [ ] Transfert 1 barre aux signatures adjacentes compatibles.

**C — Sorts (nouveau verbe actif)**
- [ ] Implémenter `CardType.SPELL` dans `play_card` (aujourd'hui TODO).
- [ ] Données de Sort (effet, coût Caps, cible : point / tour).
- [ ] Ciblage mobile (drag carte → cible), déductible pendant la vague.
- [ ] Les 5 Sorts de départ (Court-Circuit, Huile de Vidange, Overdrive, Frappe de Ferraille, Orage Punk).
- [ ] Deck Brasier remixé ~6 Tours + ~4 Sorts.

**D — Contenu manquant**
- [ ] Tours Feu/Élec de base (auto-fire) pour étoffer le Deck Brasier.
- [ ] 5 vagues + Boss War Rig, écran victoire/défaite, polish, export Android.

---

*Document vivant — à mettre à jour à chaque décision de design. Toutes les valeurs numériques sont des valeurs MVP à ajuster en playtest.*
