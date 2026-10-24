# JUNKRIOT — Analyse & Game Design Document v3.0

**Tower Defense Deckbuilder — Punk Post-Apocalyptique**
Godot 4 · Solo dev · Document de référence interne
Rédigé le 4 septembre 2026

> **Structure du document**
> La **Partie I** est le diagnostic posé le 4 septembre 2026, conservé tel quel :
> il explique POURQUOI les chantiers ont été menés, et sert de référence quand
> une décision de design est remise en question. La **Partie II** est le design
> cible. La **Partie III** dit où en est le jeu aujourd'hui.
>
> Les tables de données (tours, sorts, ennemis, decks) ne sont PAS ici : elles
> vivent dans `JUNKRIOT_CONTENU_V1.md` et y sont **générées depuis le code**
> par `scripts_tools/sync_gdd.py`. Un document rédigé à la main dérive dès le
> premier réglage — ça s'est déjà produit deux fois.

---

# PARTIE I — DIAGNOSTIC

## 1. Ce que JunkRiot était le 4 septembre 2026

> Tableau **historique**, laissé tel quel : c'est le constat qui a déclenché les
> chantiers. Pour l'état actuel, voir la Partie III.

| Système | État | Détail |
|---|---|---|
| TD à chemin fixe, bande constructible | 🟢 | Grille 17×8 de 96 px, pose limitée à 4 cases du chemin |
| Économie double (Caps / Ferraille) | 🟢 | Caps → poser une tour · Ferraille → améliorer |
| Améliorations | 🟢 | 3 paliers, ×2.56 dégâts au max, 21 🔩 |
| 9 tours, 8 éléments | 🟢 | dont 4 signatures manuelles et 1 automatique |
| 5 types d'ennemis | 🟢 | Pillard, Kamikazé, Tank, Drone Jaune, Drone Punk, + MiniBoss |
| Affinités élémentaires | 🟢 | faiblesse ×2 / résistance ×0.5, blindage forfaitaire |
| 13 réactions (statut × statut, zone × zone) | 🟢 | le vrai différenciateur du jeu |
| Pioche / main / défausse / remélange | 🟢 | main de 4, deck de 10 |
| Choix de deck avant le niveau | 🟢 | 2 decks prédéfinis + briefing des menaces |
| Récompense entre vagues | 🟡 | 1 bonus parmi 3, **jamais de carte** |
| Charge (jauge + DÉCLENCHER) | 🟢 | plafond de 3 tours signature sur le terrain |
| **Le deck évolue pendant la run** | 🟢 | cartes, améliorations ★, épuration |
| **Sorts jouables** | 🟢 | 10 sorts, visée au clic |
| **Priorité de ciblage** | 🟢 | 5 modes, bouton par tour |
| **Boss à mécanique** | 🟢 | bouclier élémentaire tournant |
| **Méta-progression** | 🟡 | déblocage de cartes par niveau |

**Durée d'une partie** : ~10 min (12 vagues × 20 s de préparation + combats +
11 écrans de récompense). L'objectif « au moins 5 minutes » est atteint.

---

## 2. Le problème central : le jeu ne tient pas sa promesse

La promesse tient en une phrase, la tienne : **« un Bloons TD 6 avec la notion
de deck en plus »**.

La partie BTD6 est là. La partie deck ne l'est pas.

**Aujourd'hui, le deck est une contrainte, pas une construction.** Le joueur
choisit 10 cartes avant de lancer le niveau, et ces 10 cartes sont exactement
celles qu'il aura à la fin. Rien ne s'ajoute, rien ne se retire, rien ne
s'améliore. Le cycle pioche/défausse/remélange fonctionne parfaitement — mais
sur un deck figé, ce n'est pas un deck, **c'est un distributeur**.

Or ce qui rend un deckbuilder addictif n'est pas de *jouer* des cartes, c'est de
regarder son deck **devenir quelque chose**. Dans Slay the Spire, le plaisir
n'est pas dans le combat : il est dans le moment où l'on comprend que les trois
cartes ramassées forment un moteur. JunkRiot ne peut pas produire ce moment,
parce que le deck est le même au tour 1 et au tour 12.

**Conséquence directe sur la hype** : il n'y a **aucune découverte** dans une
partie. Le joueur voit ses 10 cartes sur l'écran de sélection, puis les rejoue
pendant 10 minutes. La deuxième partie sur le même niveau est identique à la
première.

---

## 3. Les cinq autres problèmes de fond

### 3.1 ✅ La double monnaie a supprimé LA décision de BTD6

> **Résolu.** La Ferraille n'existe plus ; tout se paie en Caps.

Dans BTD6, chaque round pose la même question : **« nouveau singe, ou upgrade
d'un singe existant ? »** C'est une seule monnaie, donc les deux options se
disputent le même argent. C'est la tension économique centrale du genre.

JunkRiot a séparé les deux : les **Caps** achètent des tours, la **Ferraille**
achète des améliorations. Elles ne se disputent rien. La décision n'existe pas —
on achète les deux dès qu'on peut, sans jamais arbitrer.

C'est un problème de conception, pas d'équilibrage : aucun réglage de valeurs ne
peut recréer un arbitrage entre deux ressources qui ne sont pas en concurrence.

### 3.2 ✅ Les récompenses entre vagues sont le mauvais type de choix

> **Résolu.** Cartes, améliorations ★ et épuration s'ajoutent aux bonus.

11 fois par partie, le joueur choisit 1 bonus parmi 3. La structure est bonne
(c'est celle de Slay the Spire), mais **le contenu est du stat-boost passif** :
+10 % de dégâts, +1 caps par vague, portée étendue.

Ces bonus changent *combien* on tape, jamais *comment* on joue. Ce sont
exactement les récompenses que BTD6 a reléguées en méta-progression (Monkey
Knowledge), justement parce qu'elles ne sont pas excitantes en cours de partie.

Le pool contient 18 bonus et **exclut explicitement les cartes**
(`get_random_rewards` filtre `RewardType.CARD`). La plomberie pour offrir des
cartes existe déjà et est désactivée.

### 3.3 ✅ Le joueur n'a presque rien à faire pendant une vague

> **Résolu.** 10 sorts jouables en vague + priorité de ciblage.

Verbes disponibles une fois la vague lancée :

- poser une tour (si assez de Caps)
- améliorer une tour (si assez de Ferraille)
- DÉCLENCHER une Charge — 3 tours maximum, 15 s de cooldown

Soit, en pratique, **un clic toutes les 15 secondes au mieux**. Le reste du
temps, on regarde.

À comparer : BTD6 offre en plus le changement de priorité de ciblage (First,
Last, Close, Strong) sur chaque tour — un système gratuit en interface et
profond en jeu. Kingdom Rush offre deux sorts à cooldown et un héros à déplacer.

### 3.4 ✅ Les réactions élémentaires sont la meilleure idée du jeu, et elles sont subies

> **Résolu.** Six sorts posent un phénomène : le joueur déclenche lui-même.

13 réactions existent. C'est réellement le différenciateur : aucun TD grand
public n'a ça. Mais **le joueur ne les déclenche pas, elles lui arrivent**. Il
pose deux tours compatibles, puis elles réagissent toutes seules quand les
conditions se présentent.

Genshin Impact — la référence sur les réactions élémentaires — les rend
euphorisantes parce que le joueur les **exécute** : un geste, puis un second
geste, puis l'explosion. Le crédit revient au joueur.

Ici le crédit revient au placement, ce qui est déjà bien, mais la réaction
elle-même ne procure aucune sensation d'action.

### 3.5 ✅ Le boss n'est pas un boss

> **Résolu.** Bouclier élémentaire tournant.

Le MiniBoss a 900 PV, marche lentement, inflige 999 de dégâts s'il passe. Il n'a
**aucune mécanique** : ni phases, ni capacité, ni comportement. C'est un Tank
avec un gros chiffre.

Or le boss est le moment de payoff du niveau. C'est là que le joueur doit
mesurer ce qu'il a construit. Un sac à PV ne mesure rien.

### 3.6 🟡 Rien ne donne envie de relancer

> **Partiellement résolu.** Déblocage de cartes par niveau ; il manque encore une collection et des modificateurs de difficulté.

Après la victoire : 3 étoiles, retour à la carte, niveau suivant débloqué. Après
le niveau 3 : plus rien. Aucune raison de rejouer un niveau déjà à 3 étoiles,
aucun objectif à poursuivre, aucune collection à compléter.

---

## 4. Ce que disent les références

| Jeu | Sa boucle addictive | JunkRiot l'a ? |
|---|---|---|
| **BTD6** | Une seule monnaie → arbitrage permanent poser/améliorer. Escalade jusqu'à la toute-puissance. | ❌ monnaie séparée · 🟡 escalade présente |
| **Slay the Spire** | Le deck se transforme. Chaque récompense est un choix identitaire. | ❌ deck figé |
| **Kingdom Rush** | Emplacements fixes → le placement est une décision définitive. Sorts + héros = agentivité continue. | 🟢 placement · ❌ sorts/héros |
| **Genshin** | Réactions déclenchées PAR le joueur, en deux gestes. | ❌ réactions passives |
| **Clash Royale** | Cycle de main sous pression, ressource qui remonte lentement. | 🟡 cycle présent, sans pression |
| **PvZ** | Chaque nouveau mob enseigne une règle. Lisibilité parfaite. | 🟢 c'est le point fort actuel |

**Ce que JunkRiot fait déjà mieux que ses références** : le briefing élémentaire
avant la partie. Aucun de ces jeux n'annonce aussi clairement « voici la menace,
voici ce qui y répond, voici la couverture de ton deck ». C'est un vrai acquis,
à ne pas perdre.

---

## 5. Où est la hype, concrètement

Un joueur relance une partie pour cinq raisons. Voici lesquelles JunkRiot
active :

| Moteur de hype | État | Ce qui manque |
|---|---|---|
| **Fantasme de puissance croissante** | 🟡 | Les améliorations montent, mais le plafond est atteint vers la vague 8 |
| **Identité de build** | 🟡 | Deux decks fixes = deux identités, jamais les siennes |
| **Découverte / surprise** | 🔴 | Zéro. Tout est connu avant de commencer |
| **Remontada** | 🔴 | 20 PV, on perd sans drame ni retournement possible |
| **Objectif à poursuivre** | 🔴 | Rien après le niveau 3 |

**Le diagnostic tient en une phrase** : le jeu a une excellente *mécanique* et
aucune *dramaturgie*. Il se joue bien et ne se raconte pas.

---

# PARTIE II — LE DESIGN CIBLE

## 6. Vision

> **JunkRiot est un Bloons TD 6 dont l'arsenal se construit pendant la partie.**

Trois piliers, dans cet ordre de priorité :

1. **La machine élémentaire** — poser des tours qui *réagissent entre elles*.
   C'est l'identité, c'est ce qu'aucun concurrent ne fait, tout doit la servir.
2. **Le deck qui devient tien** — on entre avec 10 cartes, on ressort avec 16
   qu'on a choisies une par une.
3. **Le chaos lisible** — ça pète partout, et on comprend toujours pourquoi.

Ce que JunkRiot **n'est pas** : un jeu d'arbres d'améliorations profonds (c'est
BTD6, et la profondeur doit venir du deck) ; un jeu de placement millimétré
(c'est TD classique) ; un roguelike punitif.

---

## 7. La boucle cible

```
CARTE DU MONDE
   └─ choix du niveau (menace annoncée : "🪨 Terre", "⚡ Élec")
        └─ CHOIX DE DECK (10 cartes de départ)
             └─ ┌───────────── PARTIE (12 vagues) ─────────────┐
                │  PRÉPARATION (20 s)                          │
                │    · poser des tours (Caps)                  │
                │    · améliorer (Caps — voir §8.1)            │
                │    · lire l'aperçu de la vague               │
                │  VAGUE                                        │
                │    · déclencher les Charges                   │
                │    · jouer des SORTS                          │
                │    · changer une priorité de ciblage          │
                │  RÉCOMPENSE : 1 carte parmi 3                │
                └───────────────────────────────────────────────┘
                     └─ VICTOIRE → étoiles + déblocage
```

Les deux ajouts qui changent tout sont en gras dans la roadmap : **la carte en
récompense** et **les sorts**.

---

## 8. Les chantiers, par rapport hype/effort

### 8.1 ✅ CARTE EN RÉCOMPENSE — *fait*

**Le problème résolu** : le deck ne change jamais.

**La proposition** : après chaque vague, le joueur choisit **1 carte parmi 3**,
qui rejoint sa défausse (donc son deck pour la suite de la partie). Sur 11
récompenses, un deck de 10 cartes devient un deck de ~16 cartes choisies.

**Pourquoi ça marche** :
- ça crée la **découverte** absente aujourd'hui : on ne sait pas ce qu'on va
  proposer au joueur ;
- ça crée l'**identité de build** : deux parties sur le même niveau divergent ;
- ça donne un sens rétroactif au choix de deck initial (une base, pas un total) ;
- **la plomberie existe déjà** — `RewardType.CARD` est implémenté et simplement
  filtré du pool dans `get_random_rewards`.

**Trois règles pour que ça ne dégénère pas** :
1. **Une carte proposée doit être jouable dans la partie en cours.** Proposer
   une tour Feu au Nid de Drones, où le Feu ne paie pas, est une non-récompense.
   Pondérer le tirage par la couverture élémentaire du niveau.
2. **Diluer le deck a un coût.** Ajouter des cartes rend la pioche moins fiable.
   Prévoir tôt une option « retirer une carte » (Slay the Spire l'a comprise).
3. **Alterner les types.** Une récompense sur trois doit être un Sort, sinon le
   joueur n'accumule que des tours qu'il n'a pas les Caps de poser.

### 8.2 ✅ LES SORTS — *fait, 10 sorts*

**Le problème résolu** : le joueur regarde sa vague au lieu de la jouer.

`CardType.SPELL` existe et n'est pas implémenté. Un sort est une carte de la
main, **consommée** à l'usage, coûtant des Caps, jouable **pendant** la vague.

Cinq sorts de départ, pensés pour agir sur les trois axes du jeu — dégâts,
contrôle, économie :

| Sort | Coût | Effet | Rôle |
|---|---|---|---|
| **Frappe de Ferraille** | 30 | Dégâts lourds sur une zone ciblée | Sauver une fuite |
| **Court-Circuit** | 20 | Stun 3 s dans un rayon | Contrôle d'urgence |
| **Huile de Vidange** | 20 | Flaque : ralentit + applique WET | Prépare une réaction |
| **Overdrive** | 25 | Une tour tire ×2 vite pendant 8 s | Récompense le placement |
| **Orage Punk** | 45 | Pose un `ELECTRIC_FIELD` n'importe où | **Réaction à la demande** |

Le dernier est le plus important : il transforme les réactions élémentaires de
*subies* en *exécutées*. Le joueur pose une zone là où il veut, sur la zone
d'une autre tour, et **déclenche lui-même** la fusion. C'est le geste de Genshin
transposé au TD, et c'est le geste qui manque au jeu.

**Règle de conception** : le contrôle est bon marché, les dégâts sont chers.
Un sort qui tue est une béquille ; un sort qui *permet de tuer* est une décision.

### 8.3 ✅ UNE SEULE MONNAIE — *fait*

**Le problème résolu** : poser et améliorer ne se disputent rien.

**La proposition** : supprimer la Ferraille, payer les améliorations en **Caps**.

Immédiatement, chaque fin de vague repose la question de BTD6 : *une tour de
plus, ou une tour meilleure ?* Le plafond de 3 signatures et la bande
constructible donnent déjà des raisons de préférer l'une ou l'autre — la
décision est déjà intéressante, il ne lui manque que la contrainte de ressource.

**Le risque à surveiller** : la Ferraille est aujourd'hui un butin aléatoire
(30 à 90 % de chance selon le mob), ce qui produit de la variance. En la
supprimant on perd cette petite loterie ; on peut la conserver comme *bonus* de
Caps sur certains mobs.

**Effort** : faible (deux appels à `spend_ferraille` → `spend_caps`), mais
l'équilibrage économique est entièrement à refaire. À ne pas lancer avant que
les deux chantiers précédents soient stables.

### 8.4 ✅ PRIORITÉ DE CIBLAGE — *fait, 5 modes*

**Le problème résolu** : peu de verbes, aucune expertise à développer.

Quatre modes par tour, changeables d'un clic quand elle est sélectionnée :
**Premier · Dernier · Plus proche · Plus costaud**.

C'est le système le plus rentable de BTD6 : trois lignes d'interface, une
profondeur infinie, et il récompense la connaissance du jeu. `find_target()` est
déjà surchargée par tour — l'architecture est prête, il faut juste exposer le
choix. Les surcharges actuelles deviennent le mode *par défaut* de chaque tour.

### 8.5 ✅ UN BOSS À MÉCANIQUE — *fait*

**Le problème résolu** : le climax du niveau est un sac à PV.

Un boss doit poser une **question**, pas un mur. Trois pistes, à choisir selon
l'identité du niveau :

- **Bouclier élémentaire tournant** — immunisé à un élément qui change toutes
  les 5 s, affiché au-dessus de lui. Force à avoir plusieurs éléments et à
  regarder le boss.
- **Invocateur** — libère des Pillards en continu tant qu'il vit. Impose de le
  tuer *vite* plutôt que de l'user.
- **Brise-tours** — désactive la tour la plus proche pendant 4 s en passant.
  Impose de ne pas tout empiler au même endroit.

La scission du Drone Punk est déjà un premier pas dans cette direction : tuer
n'est plus la fin. Le boss doit aller plus loin.

### 8.6 ✅ LA DRAMATURGIE DE LA DÉFAITE — *fait*

**Le problème résolu** : perdre n'est ni lisible ni excitant.

- Une fuite doit être un **évènement** : ralenti de 0.3 s, flash rouge, le
  compteur de PV qui tremble. Aujourd'hui elle est presque silencieuse.
- Sous 5 PV : bordure d'écran pulsante, musique qui monte. La remontada n'existe
  que si le joueur *sait* qu'il est en train de la faire.
- Écran de défaite qui dit **pourquoi** : « vague 9 · 14 fuites · la Terre
  couvrait 49 % de ce niveau, ton deck en couvrait 16 % ». Une défaite doit
  enseigner, sinon elle décourage.

### 8.7 🟡 UNE RAISON DE REVENIR — *déblocages faits ; collection et modificateurs à venir*

- **Déblocage de cartes** par la progression : gagner un niveau débloque une
  carte pour les decks futurs. C'est la collection qui manque.
- **Constructeur de deck** libre, une fois qu'il y a assez de cartes à choisir.
- **Modificateurs de difficulté** à la CHIMPS : « sans améliorations », « une
  seule signature », « deck imposé ». Rejouer un niveau à 3 étoiles doit
  proposer autre chose que la même partie.

---

## 9. Ordre d'exécution recommandé

| # | Chantier | État | Où c'est |
|---|---|---|---|
| 1 | **Carte en récompense** | 🟢 | `reward_database.gd` — pondérée par l'élément clé du niveau et par ce que le joueur ne possède pas |
| 2 | **Sorts** | 🟢 | 10 sorts, visée au clic (`spell_data.gd`, `placement_manager.gd`) |
| 3 | Priorité de ciblage | 🟢 | 5 modes, bouton 🎯 (`base_tower.gd`) |
| 4 | Dramaturgie fuite/défaite | 🟢 | `danger_overlay.gd` + débriefing de défaite |
| 5 | Boss à mécanique | 🟢 | `boss_mob.gd` — bouclier élémentaire tournant |
| 6 | Monnaie unique | 🟢 | Ferraille supprimée, améliorations à 35/80 Caps |
| 7 | Méta-progression | 🟡 | Déblocage de cartes par niveau. Manquent : modificateurs de difficulté, collection |

**Ajoutés en cours de route, hors feuille de route initiale :**

| Chantier | État | Pourquoi |
|---|---|---|
| Amélioration de carte ★ | 🟢 | La seule récompense qui améliore le deck sans l'alourdir |
| Épuration ✂ | 🟢 | Son pendant : sans elle un deck ne peut que grossir |
| Cartes utilitaires (économie / tactique) | 🟢 | Ce sont elles qui créent les archétypes |
| 3 échanges avant la partie | 🟢 | Personnalisation sans le risque du deck libre |
| Matrice de réactions complétée | 🟢 | 6 réactions manquantes ; la Glace n'en avait aucune |
| Les 5 vieilles réactions refondues | 🟢 | Elles faisaient toutes « 7 dégâts », elles n'enseignaient rien |

**Ne pas faire maintenant** : arbres d'améliorations profonds (contredit le
pilier deck), constructeur de deck libre (27 cartes très typées produiraient
surtout des decks injouables), tutoriel du niveau 1 (à réécrire quand les
systèmes seront figés).

---

## 10. Ce qu'il ne faut surtout pas casser

Le jeu a quatre acquis solides. Ils sont le socle, pas des variables
d'ajustement.

1. **Le système de réactions élémentaires.** 13 réactions, deux couches
   (statut × statut, zone × zone). C'est l'identité du jeu.
2. **Le briefing des menaces.** Il est *dérivé* du plan de vagues et des scènes
   d'ennemis, donc il ne peut pas mentir. Aucun concurrent ne fait aussi clair.
3. **La règle « un deck bon quelque part, mauvais ailleurs ».** C'est elle qui
   rend le choix de deck signifiant. Toute nouvelle carte doit s'y plier.
4. **Les trois langages de tour** (passive / automatique / signature). Ils
   protègent l'attention du joueur, qui est la ressource la plus rare.

---

## 11. Où trouver quoi

| Question | Document |
|---|---|
| Pourquoi le jeu est conçu ainsi | **ce document**, Partie I |
| Stats des tours, sorts, ennemis, decks | `JUNKRIOT_CONTENU_V1.md` (généré depuis le code) |
| Les 15 réactions et leurs effets | `JUNKRIOT_CONTENU_V1.md` § 2 |
| Les 12 règles de conception du contenu | `JUNKRIOT_CONTENU_V1.md` |
| Ce qu'on gagne entre deux vagues | `JUNKRIOT_RECOMPENSES.md` |
| Décisions historiques (obsolète) | `archive/JUNKRIOT_GDD_v2.3_OBSOLETE.md` |

**Régénérer les tables de données :**

```
python scripts_tools/sync_gdd.py
```

À lancer après tout changement de stats. Cet outil a déjà rattrapé trois
erreurs qui avaient faussé des décisions d'équilibrage : les portées des tours
annoncées à 120 au lieu de 170-210, la vitesse du Kamikazé à 90 au lieu de 180,
et deux sorts (Citerne Crevée, Orage Punk) qui n'avaient **aucun élément** —
ils ne comptaient donc ni dans la couverture des decks, ni dans la pondération
des récompenses.


---

# PARTIE III — OÙ EN EST LE JEU

*Mise à jour : 5 septembre 2026 (soir). Section à réviser après chaque session.*

## 12. État des systèmes

| Système | État | Détail |
|---|---|---|
| TD à chemin fixe, bande constructible | 🟢 | Grille 17×8 de 96 px, pose à ≤4 cases du chemin |
| **Monnaie unique (Caps)** | 🟢 | Poser, lancer un sort et améliorer puisent au même endroit |
| Améliorations de tour | 🟢 | 3 paliers, 35 puis 80 Caps |
| 9 tours, 9 éléments | 🟢 | 4 signatures manuelles, 1 automatique, 4 de base |
| **10 sorts jouables** | 🟢 | Visée au clic, consommés, payés en Caps |
| **8 cartes utilitaires** | 🟢 | Économie, tactique, amélioration gratuite |
| 6 types d'ennemis | 🟢 | Dont le Drone Punk qui se scinde en deux |
| **Boss à mécanique** | 🟢 | Bouclier élémentaire tournant toutes les 5 s |
| Affinités élémentaires | 🟢 | ×2 / ×0.5, blindage forfaitaire à plancher 45 % |
| **15 réactions statut × statut** | 🟢 | Matrice contrôle × dégâts complète |
| 5 réactions zone × zone | 🟢 | Les grosses fusions de phénomènes |
| **Le deck évolue pendant la partie** | 🟢 | Cartes, améliorations ★, épuration ✂ |
| **Priorité de ciblage** | 🟢 | 5 modes par tour |
| **Dramaturgie fuite / défaite** | 🟢 | Flash, micro-gel, bordure de danger, débriefing |
| **Personnalisation avant partie** | 🟢 | 3 échanges sur le deck préconstruit |
| Méta-progression | 🟡 | Déblocage de cartes par niveau. Pas de collection ni de modificateurs |
| Constructeur de deck libre | 🔴 | Repoussé volontairement |
| Tutoriel (niveau 1) | 🔴 | Gelé : à réécrire quand les systèmes seront figés |
| **Niveau 4 — La Fonderie** | 🟢 | ❄ Glace élément clé à 30 %, audité, branché sur la carte |
| **Drone Fournaise** | 🟢 | S'emballe jusqu'à ×2,2 ; le givre le refroidit 3× plus vite |
| **Décor et chemin PAR NIVEAU** | 🟢 | Une scène de chemin éditable à la souris, un fond par niveau |
| **L'ATELIER (niveau 99)** | 🟢 | Bac à sable : lâcher n'importe quel mob, PV infinis, vitesse du temps |
| **Outils de vérification** | 🟢 | Audit de niveau, aperçu de fond, 6 fumigènes headless |
| **Niveau 5 — Le Ciel de Ferraille** | 🟢 | ✨ Lumière 28 % + 🌪 Air 27 % ; premier niveau à deux éléments clés |
| **Zeppelin / Réparateur / Drone Fantôme** | 🟢 | Air, Nature et Lumière ont enfin chacun leur cible |
| **Les 9 éléments comptent** | 🟢 | Plus aucun élément sans ennemi qui le récompense |

## 13. Les cinq moteurs de hype

Rappel du diagnostic (§ 5) et où on en est.

| Moteur | Avant | Maintenant |
|---|---|---|
| Fantasme de puissance | 🟡 | 🟢 Améliorations, cartes ★, sorts, Overdrive |
| Identité de build | 🟡 | 🟢 5 archétypes viables, deck qui se construit |
| **Découverte / surprise** | 🔴 | 🟢 11 offres par partie, pool qui grandit avec la progression |
| **Remontada** | 🔴 | 🟢 Fuite spectaculaire, bordure de danger sous 6 PV |
| **Objectif à poursuivre** | 🔴 | 🟡 Déblocages par niveau ; rien encore après le niveau 3 |

## 14. Ce qui reste, par ordre de valeur

1. **Jouer le jeu.** Une quinzaine de systèmes ont été empilés sans playtest
   complet. C'est le travail le plus important qui reste, et le seul que le
   code ne peut pas faire.
2. **Illustrer les 8 cartes utilitaires** — les seules encore en texte.
3. **Illustrer le Zeppelin et le Réparateur.** Ils tournent avec une
   silhouette provisoire dessinée en code (`placeholder_art.gd`), qui
   s'efface d'elle-même dès qu'une texture leur est assignée. Le Drone
   Fantôme, lui, a ses quatre vues.
4. **Un 6ᵉ niveau**, ou des modificateurs de difficulté sur les cinq existants.
5. **Modificateurs de difficulté** à la CHIMPS — rejouer un niveau à 3 étoiles
   doit proposer autre chose que la même partie.
6. **Reliques** (`RewardType.RELIC` existe et n'est pas implémenté).
7. **Constructeur de deck libre**, quand il y aura 40-50 cartes.

## 13bis. La leçon du niveau 5 : un mob de remplissage ne porte pas un niveau

Le niveau 5 devait faire briller Air, Nature et Lumière. Premier audit :

```
Kamikazé       ×81   27.5 %   ← seul élément clé
Drone Fantôme  ×53   18.6 %
Zeppelin       ×27   12.7 %
```

Le Kamikazé, mob de remplissage présent partout, écrasait à lui seul les trois
menaces que le niveau était censé mettre en scène. Le pitch annonçait « trois
réponses », le jeu répondait « prends Brasier ». Il a suffi de le sortir du
roster :

```
Drone Fantôme  ×65   28.3 %   ✨ Lumière — élément clé
Zeppelin       ×46   26.9 %   🌪 Air     — élément clé
Réparateur     ×42   17.7 %   🌿 Nature
```

**La règle : l'identité d'un niveau se mesure en part de menace, pas en
intention.** Un mob nombreux et rapide pèse plus qu'un mob rare et lourd, même
si le second est « le boss du niveau » dans la tête du concepteur.

Effet de bord notable : c'est le premier niveau où **Orage est le meilleur
deck** (44,7 %). Il était le plus faible partout ailleurs — un deck qui n'a
jamais son moment finit par ne jamais être choisi.

## 14bis. Les outils de vérification

Trois erreurs de cette session venaient d'une estimation faite de tête : un
niveau 3 injouable (masse de PV comptée sans la vitesse), un deck sans aucune
prise sur un niveau, un chemin qui traversait les maisons. Chacune a produit un
outil, pour qu'elle ne puisse plus se reproduire en silence.

| Outil | Répond à |
|---|---|
| `scenes/tools/AuditLevel.tscn` | Ce niveau est-il jouable ? quel deck y répond ? |
| `scripts_tools/preview_background.py` | Ce décor laisse-t-il la place au chemin et à la grille ? |
| `scenes/tools/Smoke*.tscn` | Le niveau, la main, les récompenses, l'atelier tournent-ils vraiment ? |
| `scripts_tools/sync_gdd.py` | Les tables du GDD disent-elles ce que le code fait ? |
| `AuditLevel` (fin de sortie) | Un ennemi du catalogue n'apparaît-il dans AUCUN niveau ? |

Lancement type :

```
Godot --headless --path . scenes/tools/AuditLevel.tscn -- 4
python scripts_tools/preview_background.py assets/maps/Ruines.png docs/apercu.png --niveau=3
```

**Règle qui en découle : aucun chiffre d'équilibrage ne s'écrit à la main.**
La difficulté d'un niveau est `PV × vitesse`, pas `PV` — un mob deux fois plus
rapide coûte deux fois plus cher à tuer, parce qu'il reste deux fois moins
longtemps sous le feu.

## 15. Dettes techniques connues

| Dette | Risque |
|---|---|
| Le tutoriel utilise encore des cases scriptées et un deck imposé | Cassera si la grille ou les decks changent |
| `SynergyLibrary` contient une entrée morte « Mama Cog » | Inerte, mais trompeuse à la lecture |
| Les stats des cartes ★ sont génériques, pas sur mesure par carte | Moins savoureux que le tableau du GDD des récompenses |
| Pas de test de RÈGLES du jeu | Les fumigènes vérifient que ça tourne, pas que c'est équilibré |
| Le niveau 3 a un chemin +57 % plus long qu'avant | Le rend nettement plus facile ; à revalider en jouant |
