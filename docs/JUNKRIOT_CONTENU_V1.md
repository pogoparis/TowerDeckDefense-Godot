# JUNKRIOT — Bible de contenu V1

**Éléments · Tours · Sorts · Réactions · Ennemis · Decks**
Document de travail — 5 septembre 2026

> Ce document décrit **tout le contenu jouable de la V1** et les règles qui le
> gouvernent. Il sert à deux choses : équilibrer ce qui existe, et créer de
> nouvelles cartes sans casser l'édifice. Chaque section se termine par la
> **règle** à respecter pour toute addition future.

---

## 1. Le squelette : 9 éléments, 3 rôles

Tout part de là. Chaque élément a **un rôle et un seul**, et **une tour et une
seule**. C'est cette rigueur qui rend le jeu lisible : quand le joueur voit un
élément, il sait ce qu'il fait.

### 🗡 DÉGÂTS — ils tuent

| Élément | Tour | Spécialité | Statut posé |
|---|---|---|---|
| 🔥 **Feu** | Punk Explosif | Foule, zone | `BURNING` |
| ⚡ **Électricité** | Ours Éclair | Chaîne entre cibles | `CHARGED` |
| 🪨 **Terre** | Gardien Rocheux | Gros coups, anti-blindé | `DUSTY` |
| 🌿 **Nature** | Panda Punk | % des PV max — anti-gros | `POISONED` |

### 🛡 CONTRÔLE — ils ne tuent pas, ils permettent de tuer

| Élément | Tour | Spécialité | Statut posé |
|---|---|---|---|
| 💧 **Eau** | Requin Cracheur | Marque et ralentit un peu | `WET` |
| 🌪 **Air** | Souffle-Chouette | **Repousse** sur le chemin | `WINDMARK` |
| ❄ **Glace** | Pingouin Punk | Givre **cumulatif**, durable | `CHILLED` |

### ✨ AMPLIFICATEURS — ils ne font rien seuls

| Élément | Tour | Spécialité | Statut posé |
|---|---|---|---|
| 🦇 **Ombre** | Vampire | +40 % de dégâts **subis** | `MARKED` |
| ✨ **Lumière** | Luciole | +25 % de dégâts **émis** (halo) | — |

> **RÈGLE 1 — Un élément, un rôle, une tour.**
> Une deuxième tour de Feu devra être une *variante* (portée, cadence,
> ciblage), jamais un second rôle. Un élément qui fait deux choses ne
> s'apprend pas.

> **RÈGLE 2 — Le contrôle ne tue pas, les dégâts ne contrôlent pas.**
> C'est ce qui force à mélanger. Le jour où une tour de contrôle tue
> correctement, plus personne ne prend de tour de dégâts.

---

## 2. La règle des réactions

> ### 🔑 **UN ÉLÉMENT DE CONTRÔLE + UN ÉLÉMENT DE DÉGÂTS = UNE RÉACTION**

C'est la seule chose que le joueur doit retenir. 3 contrôles × 4 dégâts = **12
réactions**, toutes garanties. Il n'a pas besoin de mémoriser la table : il lui
suffit de mettre du contrôle et des dégâts côte à côte.

|  | 🔥 Feu | ⚡ Élec | 🪨 Terre | 🌿 Nature |
|---|---|---|---|---|
| 💧 **Eau** | **VAPEUR** | **ÉLECTROCUTION** | **BOUE** | **INFUSION** |
| 🌪 **Air** | **ATTISÉ** | **DÉCHARGE** | **TEMPÊTE DE SABLE** | **SPORES** |
| ❄ **Glace** | **CHOC THERMIQUE** | **SUPRACONDUCTEUR** | **BRISURE** | **GANGRÈNE** |

### Ce que fait chacune

| Réaction | Effet | Type d'effet |
|---|---|---|
| VAPEUR | 8 dégâts | Dégâts |
| ÉLECTROCUTION | Décharge répétée + stun | Contrôle + dégâts |
| **BOUE** | Ralentit ×0.35 pendant 4 s | Contrôle |
| **INFUSION** | **8 % des PV max** d'un coup | Anti-gros |
| ATTISÉ | 7 dégâts | Dégâts |
| DÉCHARGE | 7 dégâts | Dégâts |
| TEMPÊTE DE SABLE | 16 dégâts en zone + ralentit | Zone |
| SPORES | **Propage le poison** aux voisins | Zone |
| **CHOC THERMIQUE** | 45 + 6 % PV max — **consomme le givre** | Burst |
| **SUPRACONDUCTEUR** | 30 + chaîne à tous les **gelés** proches | Zone |
| **BRISURE** | 35 + jusqu'à 90 selon la **profondeur du gel** | Burst |
| **GANGRÈNE** | Poison prolongé à 12 s | Durée |

### Les 3 exceptions historiques (hors règle)

| Réaction | Combinaison | Effet |
|---|---|---|
| SURCHAUFFE | 🔥 + ⚡ (dégâts × dégâts) | 8 dégâts |
| ÉCLABOUSSURE | 💧 + 🌪 (contrôle × contrôle) | 6 dégâts |
| CRYOGÉNISATION | 💧 + ❄ (contrôle × contrôle) | **Arrêt complet 2 s** |

> **RÈGLE 3 — Une réaction doit ENSEIGNER, pas juste taper.**
> Regarde la colonne « type d'effet » : burst, durée, zone, contrôle, anti-gros.
> Une réaction qui fait « encore des dégâts » n'apprend rien sur les deux
> éléments qui l'ont produite. Les quatre plus vieilles (Vapeur, Attisé,
> Décharge, Surchauffe) sont justement les plus fades — à retravailler.

> **RÈGLE 4 — Les amplificateurs n'ont PAS de réaction.**
> Ombre et Lumière multiplient tout le reste : leur donner des réactions en
> ferait les meilleurs éléments du jeu à tous les coups.

### La deuxième couche : zone × zone

Les Charges des tours signature et certains sorts posent des **phénomènes**.
Deux phénomènes qui se chevauchent fusionnent — ce sont les grosses réactions.

| Combinaison | Réaction | Effet |
|---|---|---|
| 💧 Flaque + 🔥 Feu | **VAPEUR** | 80 dégâts **+ 15 % PV max**, ralentit ×0.2 · 5 s |
| 🔥 Feu + 🌪 Bourrasque | **TORNADE DE FEU** | 60 + 12 % PV max, BURNING |
| 💧 Flaque + 🌪 Bourrasque | **TEMPÊTE** | WET de masse + repoussée |
| ⚡ Champ + 🔥 Feu | **SURCHARGE** | — |
| ⚡ Champ + 🌪 Bourrasque | **ORAGE** | Frappes de foudre répétées |

---

## 3. Les tours

> Table générée depuis les scènes par `scripts_tools/sync_gdd.py`.
> Ne la modifie pas à la main — elle serait écrasée, et surtout elle mentirait.

<!-- AUTO:TOURS -->
| Tour | Élément | Coût | Dégâts | Cadence | Portée | Type |
|---|---|---|---|---|---|---|
| Souffle-Chouette | 🌪 Air | 20 | 10 | 0.8 | 180 | base |
| Pingouin Punk | ❄ Glace | 25 | 4 | 0.55 | 200 | base |
| Luciole | ✨ Lumière | 25 | 4 | 1.0 | 170 | base |
| Requin Cracheur | 💧 Eau | 25 | 10 | 0.9 | 200 | base |
| Vampire | 🦇 Ombre | 30 | 6 | 1.1 | 200 | **auto** |
| Punk Explosif | 🔥 Feu | 35 | 7 | 1.0 | 210 | **signature** |
| Panda Punk | 🌿 Nature | 35 | 5 | 1.0 | 210 | **signature** |
| Ours Éclair | ⚡ Élec | 35 | 6 | 0.8 | 200 | **signature** |
| Gardien Rocheux | 🪨 Terre | 40 | 16 | 1.6 | 190 | **signature** |
<!-- /AUTO:TOURS -->

### Trois langages de tour

| | Jauge | Bouton | Plafond de 3 | Cooldown |
|---|---|---|---|---|
| **Base** | aucune | — | non | — |
| **Automatique** | discrète, verte | — | **non** | 3 s |
| **Signature** | dorée, halo pulsant | DÉCLENCHER | **oui** | 15 s |

> **RÈGLE 5 — Maximum 3 signatures sur le terrain.**
> Le plafond protège l'**attention** du joueur, pas la puissance. Avec cinq
> jauges à l'écran, DÉCLENCHER devient du clic de routine. Toute nouvelle tour
> à effet devrait être **automatique** par défaut.

> **RÈGLE 6 — Un deck ne contient jamais plus de 4 cartes signature sur 10.**
> Au-delà, on pioche des cartes injouables à cause du plafond.

---

## 4. Les sorts

Un sort est une carte jouée **pendant** la vague, consommée à l'usage, payée en
Caps. On vise un point, on clique.

<!-- AUTO:SORTS -->
| Sort | Élément | Coût | Rayon | Effet | Détail |
|---|---|---|---|---|---|
| Bourrasque | 🌪 Air | 20 | 150 | Pose un phénomène | `WIND_CURRENT` · 6 s |
| Citerne Crevée | 💧 Eau | 20 | 140 | Pose un phénomène | `WATER_POOL` · 7 s |
| Court-Circuit | ⚡ Élec | 20 | 150 | Étourdit | 10 dégâts · 3 s |
| Azote Liquide | ❄ Glace | 25 | 150 | Étourdit | 2.5 s |
| Cocktail Molotov | 🔥 Feu | 25 | 145 | Pose un phénomène | `FIRE_ZONE` · 7 s |
| Plein Phare | ✨ Lumière | 25 | 160 | Dope les tours | 8 s · ×1.5 dégâts aux tours |
| Frappe de Ferraille | 🪨 Terre | 30 | 130 | Dégâts | 70 dégâts |
| Nuée de Spores | 🌿 Nature | 30 | 150 | Pose un phénomène | `THORN_PATCH` · 7 s |
| Marque Collective | 🦇 Ombre | 35 | 160 | Pose un phénomène | `SHADOW_ZONE` · 6 s |
| Orage Punk | ⚡ Élec | 45 | 155 | Pose un phénomène | `ELECTRIC_FIELD` · 8 s |
<!-- /AUTO:SORTS -->

> **RÈGLE 7 — Le contrôle est bon marché, les dégâts sont chers.**
> 20 caps pour un stun, 30 pour des dégâts directs. Un sort qui **tue** est une
> béquille ; un sort qui **permet de tuer** est une décision. C'est aussi ce qui
> empêche les sorts de rendre les tours inutiles.

> **RÈGLE 8 — Les sorts qui posent un phénomène sont les plus importants.**
> Ce sont les seuls qui permettent au joueur de **déclencher lui-même** une
> réaction, au lieu de la subir. Six des dix en posent un — c'est volontaire.

---

## 5. Les ennemis

<!-- AUTO:ENNEMIS -->
| Ennemi | PV | Vitesse | Blindage | Faible à | Résiste à | Caps | Fuite | PV×vit |
|---|---|---|---|---|---|---|---|---|
| Pillard | 40 | 150 | 0 | — | — | 1 | 1 | 6.0k |
| Kamikazé | 70 | 180 | 0 | 🔥 Feu | ⚡ Élec | 3 | 1 | 12.6k |
| Drone Jaune | 90 | 165 | 1 | ⚡ Élec | — | 4 | 2 | 14.8k |
| PhantomDrone | 100 | 130 | 0 | ✨ Lumière | — | 4 | 2 | 13.0k |
| Repairer | 140 | 90 | 0 | 🌿 Nature | — | 5 | 2 | 12.6k |
| FurnaceDrone | 160 | 80 | 0 | ❄ Glace | — | 5 | 3 | 12.8k |
| Tank | 220 | 60 | 0 | 🪨 Terre | 🔥 Feu | 5 | 3 | 13.2k |
| Zeppelin | 250 | 70 | 0 | 🌪 Air | — | 6 | 3 | 17.5k |
| Drone Punk | 420 | 85 | 5 | 💧 Eau | — | 9 | 4 | 35.7k |
| MiniBoss | 900 | 40 | 0 | — | 🦇 Ombre | 15 | 999 | 36.0k |
<!-- /AUTO:ENNEMIS -->

La colonne **PV×vit** est la seule mesure honnête pour comparer deux ennemis :
un mob rapide passe moins de temps sous le feu, donc il coûte plus de DPS à PV
égaux. Voir RÈGLE 9bis.

**Multiplicateurs** : faiblesse **×2**, résistance **×0.5**. Le blindage retire
un **forfait** par coup, avec un plancher à **45 %** des dégâts entrants — sinon
il ne réduit pas les petites tours, il les supprime.

**Ordre de calcul** : `brut → × affinité → − blindage → × 1.4 si MARQUÉ`.
L'affinité passe avant le blindage pour que le bon élément aide à le **percer**.

> **RÈGLE 9 — Un ennemi a une faiblesse OU une résistance, jamais les deux avec
> du blindage.** Le Drone Jaune cumulait résistance Terre + blindage : le
> Gardien tombait à 2.5 DPS contre lui, c'était injouable.

> **RÈGLE 9bis — La VITESSE est un multiplicateur de difficulté caché.**
> Le temps qu'un ennemi passe sous le feu d'une tour vaut `2 × portée ÷ vitesse`.
> Un Tank à 60 px/s reste 6,3 s dans une tour de portée 190 ; un Drone à
> 195 px/s n'y restait que 2,0 s. À PV égaux, le drone demandait donc **trois
> fois plus de DPS**. Compter les PV ne suffit jamais : il faut compter
> **PV × vitesse**.
>
> Corollaire : ne JAMAIS cumuler vitesse élevée, blindage et arrivée serrée sur
> le même ennemi. Le Drone Jaune avait les trois — il fallait 27 Ours Éclair
> pour en tuer un seul en vague 12.

> **RÈGLE 10 — Peu de faiblesses, bien réparties.**
> Quand chaque ennemi avait une faiblesse, chaque niveau réclamait tous les
> éléments et le système s'annulait. Le Pillard et le MiniBoss n'en ont
> volontairement aucune.

### Ce qui manque encore côté ennemis

- Un ennemi faible à ❄ **Glace**, 🌪 **Air**, ✨ **Lumière** ou 🌿 **Nature** —
  ces quatre éléments ne sont la faiblesse de personne, donc jamais « l'élément
  clé » d'un niveau.
- Un ennemi **soigneur** (rend des PV aux voisins) — force à tuer vite.
- Un ennemi **bouclier** (absorbe N coups quelle que soit leur force) — la
  réponse est la cadence, pas la puissance : le miroir exact du blindage.
- Un **boss à mécanique**, pas un sac à PV.

---

## 6. Les decks préconstruits

Les 9 éléments se répartissent en 3 decks de 3 éléments, chacun avec au moins
une réaction native. Aucun deck ne couvre tout.

<!-- AUTO:DECKS -->
**Brasier** (10 cartes) — Punk Explosif ×2 · Requin Cracheur ×2 · Vampire ×1 · Luciole ×1 · Cocktail Molotov ×1 · Citerne Crevée ×1 · Frappe de Ferraille ×1 · Marque Collective ×1

**Orage** (10 cartes) — Ours Éclair ×3 · Souffle-Chouette ×2 · Panda Punk ×1 · Orage Punk ×1 · Bourrasque ×1 · Nuée de Spores ×1 · Court-Circuit ×1

**Roche** (10 cartes) — Gardien Rocheux ×2 · Pingouin Punk ×2 · Luciole ×2 · Azote Liquide ×1 · Plein Phare ×1 · Frappe de Ferraille ×1 · Court-Circuit ×1
<!-- /AUTO:DECKS -->

### Comment ils se jouent

**🔥 Brasier — Feu · Eau · Ombre.** Requin devant pour tremper, Punk Explosif
derrière pour convertir en VAPEUR. Le Vampire amplifie, la Marque Collective
double la mise avant un gros coup. Faible contre les blindés.

**🪨 Roche — Terre · Glace · Lumière.** Les Pingouins gèlent en profondeur, le
Gardien brise — et plus le gel est profond, plus la BRISURE fait mal. Les
Lucioles compensent la faible cadence. Le plus lent à démarrer, le plus solide
en fin de partie.

**⚡ Orage — Électricité · Air · Nature.** Le seul deck à deux réactions natives
(DÉCHARGE, SPORES), mais sans amplificateur : il tape fort et n'a aucun filet.

> **RÈGLE 11 — 10 cartes, dont 3 à 4 sorts.**
> Moins de 3 sorts : rien à faire pendant la vague. Plus de 4 : les sorts
> mangent les Caps qui devaient poser des tours.

> **RÈGLE 12 — Une seule monnaie : les Caps.**
> Poser une tour, lancer un sort et améliorer puisent au MÊME endroit. C'est ce
> qui recrée la question centrale de BTD6 à chaque fin de vague : *une tour de
> plus, ou une tour meilleure ?* Tant que les améliorations se payaient en
> Ferraille, elles ne se disputaient rien et on prenait les deux.
> Une partie de La Casse rapporte **1073 Caps**. Poser ~10 tours et lancer
> ~8 sorts en consomme 500 ; il reste de quoi maxer **5 tours sur 10**.
> Coût d'amélioration : **35** puis **80** Caps.

> **RÈGLE 13 — Caps de départ ≥ les deux cartes les plus chères du deck.**
> La vague 1 réclame ~17 DPS et **aucune tour seule** n'y arrive. À 50 caps,
> toute ouverture incluant le Gardien (40) était impossible : le niveau était
> mathématiquement infranchissable. Caps de départ actuelles : **70**.

---

## 7. Récapitulatif

<!-- AUTO:COMPTES -->
| Famille | Nombre |
|---|---|
| Tours | 9 |
| Sorts | 10 |
| Améliorations | 2 |
| Tactiques | 2 |
| Économie | 4 |
| **Total cartes** | **27** |
| Illustrées | 19 / 27 |
| Bonus de run | 18 |
<!-- /AUTO:COMPTES -->

Sur une partie de 12 vagues le joueur voit 11 offres de récompense : il ne
croise donc qu'une fraction du pool par partie, ce qui est exactement le but —
**deux parties ne se ressemblent pas**.

Les cartes utilitaires sont listées ici :

<!-- AUTO:UTILITAIRES -->
| Carte | Type | Coût | Effet |
|---|---|---|---|
| Recyclage | Économie | 0 | +75 Caps |
| Reconnaissance | Tactique | 10 | pioche 3 |
| Plan B | Tactique | 15 | +25 Caps · pioche 2 |
| Bricolage | Amélioration | 20 | améliore une tour gratuitement |
| Décharge Sauvage | Économie | 20 | +55 Caps · pioche 1 |
| Atelier Mobile | Amélioration | 45 | pioche 1 · améliore une tour gratuitement |
| Contrebande | Économie | 45 | +18 Caps/vague |
| Pillage | Économie | 60 | +30 Caps/vague |
<!-- /AUTO:UTILITAIRES -->

---

## 7bis. La personnalisation avant la partie

Le constructeur de deck LIBRE reste repoussé — avec 27 cartes très typées, il
produirait surtout des decks injouables, et le joueur n'a pas encore les repères
pour en juger.

Le compromis en place : **3 échanges maximum** sur l'écran de deck, après avoir
choisi un deck préconstruit. Le joueur clique une carte de son deck, puis une
carte disponible qui la remplace.

Pourquoi trois et pas dix : c'est assez pour **corriger un deck face au briefing
qu'il vient de lire** (« ce niveau demande de la Terre, j'échange mes deux
Chouettes ») et trop peu pour dénaturer l'archétype. Le deck reste cohérent,
mais il devient un peu le sien.

Les échanges valent pour **une partie** : repartir sur un autre niveau
réinitialise le deck. Sans ça, un deck taillé pour La Casse serait rejoué tel
quel au Nid, qui demande exactement l'inverse.

Le pool proposé à l'échange ne contient que les cartes **débloquées** — la
méta-progression élargit donc aussi la personnalisation, pas seulement les
récompenses.

---

## 8. Ce qu'il reste à construire

Par ordre de priorité (voir `JUNKRIOT_GDD_v3.0.md` pour le raisonnement).

### Fait depuis la première rédaction

- ✅ **Carte en récompense** — 1 parmi 3 après chaque vague, avec améliorations ★
  et épuration ✂. Chaque offre annonce désormais son TYPE : une amélioration ne
  peut plus être prise pour la carte elle-même.
- ✅ **Illustrations des sorts** — les 10 sorts sont illustrés.
- ✅ **Réactions retravaillées** — Vapeur, Attisé, Décharge et Surchauffe ont
  chacune un effet propre au lieu de 7-8 dégâts anonymes.
- ✅ **Boss à mécanique** — bouclier élémentaire tournant toutes les 5 s.
- ✅ **Un ennemi faible à ❄ Glace** — le Drone Fournaise, qui s'emballe et que
  seul le givre refroidit. Il fait de la Glace l'élément clé du niveau 4.
- ✅ **Air, Nature et Lumière ont enfin leur cible.** Le Zeppelin (que le vent
  renvoie 3× plus loin), le Réparateur (qui soigne ses voisins et que la Nature
  grippe) et le Drone Fantôme (camouflé à −50 % tant que la Lumière ne l'a pas
  révélé). Les neuf éléments récompensent désormais tous quelque chose.

### Ce qui reste

1. **Illustrer les 8 cartes utilitaires** — les seules encore en texte
   (`util_*.tres`). Le repli visuel fonctionne, mais il ne donne envie à
   personne.
2. **Illustrer le Zeppelin et le Réparateur.** Ils sont jouables avec une
   silhouette provisoire dessinée en code : elle disparaît d'elle-même dès
   qu'on leur assigne des textures, aucun code à retoucher.
3. **Un 6ᵉ niveau**, ou des modificateurs de difficulté sur les cinq existants.
4. **Reliques** — `RewardType.RELIC` existe et n'est pas implémenté.
5. **Modificateurs de difficulté** — rejouer un niveau à 3 étoiles doit
   proposer autre chose que la même partie.

### Ce qui n'est PAS un manque

Le nombre de cartes. 27 cartes très typées suffisent aux 3 decks
préconstruits et au pool de récompenses : sur 12 vagues le joueur voit 11
offres, il ne croise donc jamais tout le pool en une partie. En ajouter avant
d'avoir joué produirait du contenu qu'on n'a pas les moyens de juger.

Le constructeur de deck libre reste repoussé pour la même raison.
