# JUNKRIOT — Les récompenses

**Ce qu'on gagne entre deux vagues, et pourquoi**
Document de design — 5 septembre 2026

> La récompense entre deux vagues est le **seul moment où le joueur construit
> quelque chose**. Le reste du temps il dépense des Caps ; ici il décide de ce
> que sa partie va devenir. C'est donc le système le plus important du jeu
> après les réactions élémentaires — et le plus facile à rater.

---

## 1. Les trois règles d'une bonne récompense

### RÈGLE A — Une récompense doit changer *comment* on joue, pas *combien* on tape

C'était le défaut du système d'origine : 18 bonus, tous des stats passives
(+10 % de dégâts, +1 cap par vague). Ils ne posent aucune question. Le joueur
prend le plus gros chiffre et passe à la suite.

Une bonne récompense **ouvre une porte** : un élément qu'on n'avait pas, un
verbe qu'on ne pouvait pas jouer, un moteur économique qui change le tempo.

### RÈGLE B — Il doit toujours y avoir un vrai dilemme

Trois cartes du même genre, ce n'est pas un choix, c'est une file d'attente.
Une offre doit opposer des **natures** différentes : étoffer son deck contre
renforcer ce qu'on a, puissance immédiate contre puissance différée.

### RÈGLE C — Refuser doit être une option légitime

Sans bouton **PASSER**, une offre médiocre devient une punition : le joueur est
forcé de diluer son deck avec une carte qu'il ne veut pas. Slay the Spire l'a
compris — on peut toujours refuser contre autre chose.

Chez nous : **PASSER = +45 Caps**.

---

## 2. Les six familles de récompense

| # | Famille | Ce que ça change | État |
|---|---|---|---|
| 1 | **Carte Tour** | Un élément de plus dans le deck | 🟢 9 cartes |
| 2 | **Carte Sort** | Un verbe actif de plus | 🟢 10 cartes |
| 3 | **Carte Utilitaire** | Économie, pioche, améliorations gratuites | 🟢 8 cartes |
| 4 | **Amélioration de carte ★** | Transforme une carte du deck en version supérieure | 🟢 **fait** |
| 5 | **Bonus de run** | Stat passive globale | 🟢 18 bonus |
| 6 | **Épuration** | Retire une carte du deck | 🟢 **fait** |

Les six familles sont en place. La 4 était la plus
importante : c'est la seule qui rend un deck *personnel* au lieu de simplement
plus gros.

**Choix d'implémentation :** l'offre **nomme la carte** à améliorer plutôt que
d'ouvrir un sélecteur de deck. Le choix se fait alors parmi les trois
propositions, comme n'importe quelle récompense — même décision pour le joueur,
aucune interface supplémentaire à concevoir ni à apprendre.

---

## 3. L'amélioration de carte ★ — le chantier central

### Le problème qu'elle résout

Aujourd'hui, gagner des cartes ne fait que **grossir** le deck. Or un deck qui
grossit devient moins fiable : plus de cartes = moins de chances de piocher
celle qu'on veut. Passé 16-18 cartes, chaque ajout est presque une punition.

L'amélioration résout ça : elle rend une carte **meilleure sans en ajouter
une**. C'est la seule récompense qui améliore la fiabilité du deck au lieu de
la dégrader.

### Comment ça marche

Le joueur choisit une carte de son deck ; elle devient sa version **★**.
Une carte ne peut être améliorée qu'**une seule fois**.

**Tours ★** — un effet, jamais juste des chiffres :

| Carte | Version ★ |
|---|---|
| Punk Explosif ★ | Charge à **4 tirs** au lieu de 5 |
| Ours Éclair ★ | La chaîne touche **1 cible de plus** |
| Gardien Rocheux ★ | Ignore **la moitié du blindage** ennemi |
| Panda Punk ★ | Poison à **4 %** des PV max au lieu de 2,5 % |
| Vampire ★ | Marque à **+60 %** au lieu de +40 % |
| Requin Cracheur ★ | TREMPÉ dure **8 s** au lieu de 3 |
| Souffle-Chouette ★ | Repousse **deux fois plus loin** |
| Pingouin Punk ★ | Givre à **−18 %** par impact au lieu de −12 % |
| Luciole ★ | Halo **+55 px** de rayon |

**Sorts ★** — plus de rayon, plus de durée, ou un effet en plus :

| Carte | Version ★ |
|---|---|
| Cocktail Molotov ★ | Rayon **+40 %** |
| Orage Punk ★ | Durée **12 s** au lieu de 8 |
| Azote Liquide ★ | Gèle **4 s** au lieu de 2,5 |
| Frappe de Ferraille ★ | **110** dégâts au lieu de 70 |
| Court-Circuit ★ | Applique aussi **CHARGÉ** — donc il amorce une réaction |
| Citerne Crevée ★ | La flaque **ralentit deux fois plus** |
| Bourrasque ★ | Repousse en plus de marquer |
| Marque Collective ★ | Rayon **+50 %** |
| Nuée de Spores ★ | Empoisonne aussi ce qui entre |
| Plein Phare ★ | **12 s** au lieu de 8 |

**Utilitaires ★** — coût réduit ou effet doublé :

| Carte | Version ★ |
|---|---|
| Recyclage ★ | **+110** Caps au lieu de 75 |
| Contrebande ★ | **+28** Caps/vague au lieu de 18 |
| Bricolage ★ | **Gratuit** (0 Caps au lieu de 20) |
| Reconnaissance ★ | Pioche **4** cartes au lieu de 3 |

### ⚠ Le piège technique à ne pas manquer

Les `CardData` sont des **ressources partagées** : `preload()` renvoie la même
instance à tout le monde, et Godot la met en cache **entre les parties**.
Modifier une carte à chaud améliorerait donc la carte **définitivement**, y
compris dans les parties suivantes et dans les decks préconstruits.

La règle : **dupliquer le deck au démarrage de la partie**
(`card.duplicate()` pour chaque carte dans `setup_starting_deck`), et
n'améliorer que ces copies. Sans ça, le bug ne se verra pas tout de suite — il
se verra trois parties plus tard, quand tout sera déjà amélioré.

---

## 4. L'épuration — retirer une carte

Le pendant de l'amélioration. Le joueur retire **une carte de son deck**,
définitivement pour la partie.

Pourquoi c'est indispensable : sans elle, le deck ne peut que grossir. Retirer
sa 3ᵉ Chouette pour piocher plus souvent son Gardien est une décision de
deckbuilder pure — et c'est souvent le meilleur choix possible, ce qui en fait
une récompense qui ne paraît jamais faible.

À proposer **rarement** (1 offre sur 4 environ), sinon le joueur épure
mécaniquement jusqu'à un deck de 6 cartes et le hasard disparaît.

---

## 5. Rareté et montée en puissance

Une offre de vague 2 et une offre de vague 11 ne doivent pas se ressembler.
Sinon la fin de partie n'a pas d'enjeu.

| Rareté | Vagues | Exemples |
|---|---|---|
| **Commune** | 1-4 | Cartes de base, petits bonus, Recyclage |
| **Rare** | 5-8 | Signatures, sorts chers, améliorations ★, Contrebande |
| **Légendaire** | 9-12 | Sorts ★, épuration, reliques, doubles améliorations |

Règle d'implémentation : le tirage pondère par la vague en cours. En vague 1 on
ne propose jamais un Orage Punk à 45 Caps — le joueur ne peut pas le payer, et
une carte injouable dans une offre de trois, c'est un choix sur deux.

---

## 6. La composition d'une offre

Une offre contient **3 cartes + PASSER**. Composition voulue :

| Emplacement | Contenu | Pourquoi |
|---|---|---|
| 1 | Une carte qui **paie sur ce niveau** (son élément est l'élément clé) | Toujours quelque chose d'utile |
| 2 | Une carte de **l'autre type** (sort si la 1ʳᵉ est une tour) | Évite les offres monotypes |
| 3 | Une **amélioration ★**, une **épuration** ou un **bonus** | Le contrepoint : améliorer plutôt qu'ajouter |
| — | **PASSER : +45 Caps** | Refuser reste légitime |

Deux pondérations en plus, déjà implémentées :

- une carte que le joueur **ne possède pas** est favorisée (poids +3) → la
  découverte l'emporte sur la répétition ;
- une carte dont l'élément est **clé sur ce niveau** est favorisée (poids +4) →
  on ne propose pas du Feu là où le Feu ne paie pas.

---

## 7. État actuel du pool

| Famille | Nombre | Détail |
|---|---|---|
| Cartes Tour | **9** | Une par élément |
| Cartes Sort | **10** | Une par élément + Court-Circuit |
| Cartes Amélioration | **2** | Bricolage, Atelier Mobile |
| Cartes Tactique | **2** | Reconnaissance, Plan B |
| Cartes Économie | **4** | Recyclage, Décharge Sauvage, Contrebande, Pillage |
| **Total cartes** | **27** | |
| Bonus de run | 18 | Stats passives |

Sur une partie de 12 vagues, le joueur voit **11 offres**. Avec 27 cartes et 18
bonus, il n'y a aucune répétition forcée — mais il ne verra qu'un tiers du pool
par partie, ce qui est exactement ce qu'on veut : **deux parties ne se
ressemblent pas**.

---

## 8. Les archétypes que ce pool permet

C'est le test qui compte : est-ce qu'on peut construire des decks qui *racontent
quelque chose de différent* ?

| Archétype | Cartes clés | Comment il gagne |
|---|---|---|
| **Économie** | Contrebande, Pillage, Recyclage | Faible en début de partie, écrasant après la vague 7 |
| **Machine à réactions** | Requin + Punk Explosif + Citerne + Molotov | Peu de dégâts bruts, beaucoup de Vapeur |
| **Trois tours maxées** | Bricolage, Atelier, peu de tours | Mise tout sur la qualité |
| **Cycle rapide** | Reconnaissance, Plan B, sorts pas chers | Joue 3-4 cartes par vague |
| **Contrôle total** | Pingouin, Azote, Spores, Bourrasque | Ne tue presque pas, mais rien n'avance |

Cinq archétypes viables, c'est le seuil à partir duquel un deckbuilder devient
rejouable. **Sans les améliorations ★, il n'en reste que trois** : les deux qui
dépendent de la qualité plutôt que de la quantité disparaissent.

---

## 9. Ce qu'il reste à faire, dans l'ordre

1. ~~Dupliquer les cartes au démarrage~~ — **fait** (`setup_starting_deck`).
2. ~~Amélioration de carte ★~~ — **fait**.
3. ~~Épuration~~ — **fait** : proposée 1 offre sur 4, seulement au-dessus de
   12 cartes, et toujours sur une carte que le joueur possède en plusieurs
   exemplaires (là où elle a le plus de valeur).
4. **Pondération par rareté/vague** — pour que la fin de partie ait un enjeu.
5. **Illustrations** — 10 sorts et 8 utilitaires sont en texte.
6. **Reliques** — `RewardType.RELIC` existe et n'est pas implémenté. À garder
   pour plus tard : c'est la couche « objet unique très fort », elle n'a de sens
   qu'une fois les cinq archétypes équilibrés.
