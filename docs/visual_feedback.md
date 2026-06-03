# Junkriot - Visual Feedback & Synergy Language

## Philosophy

Une synergie qui n'est pas visible pour le joueur n'existe pas.

Chaque synergie active doit être identifiable en moins d'une seconde.

Les feedbacks visuels doivent rester lisibles sur mobile, même avec de nombreux ennemis à l'écran.

---

# Buff Visual System

## Mama Cog

Les tours affectées par Mama Cog reçoivent :

* Un contour lumineux doré autour de leur silhouette.
* Un FloatingText "+10%" lors de l'activation.
* (Plus tard) une icône d'engrenage sur Mama Cog.

Implementation :

* Shader Outline sur Sprite2D.
* Outline Size activé lorsque le buff est présent.
* Outline Size à 0 lorsque le buff disparaît.

Couleur :

Hex : #FFD54A

RGB : 255, 213, 74

---

# Synergy Colors

## Mama Cog

Nom : Gold

Hex : #FFD54A

RGB : 255, 213, 74

Utilisation :

* Outline
* FloatingText
* Icônes de support

---

## Execution Froide

Nom : Aggressive Red

Hex : #FF4D4D

RGB : 255, 77, 77

Utilisation :

* Ligne entre Vega et Grumbolt
* Projectiles guidés
* FloatingText "TIRS GUIDÉS !"
* Futur contour rouge

---

## Glace Pilonnée

Nom : Ice Blue

Hex : #6FD9FF

RGB : 111, 217, 255

Utilisation :

* Effets de givre
* Impacts gelés
* FloatingText

---

## Mur Tesla

Nom : Electric Cyan

Hex : #00E5FF

RGB : 0, 229, 255

Utilisation :

* Arcs électriques
* Liaisons Tesla
* Effets de chaîne

---

## Poison Maudit

Nom : Cursed Purple

Hex : #B266FF

RGB : 178, 102, 255

Utilisation :

* Malédictions
* Poison
* Effets Hex

---

## Brouillard Toxique

Nom : Toxic Green

Hex : #66FF66

RGB : 102, 255, 102

Utilisation :

* Nuages toxiques
* Poison de zone

---

## Sentence

Nom : Burnt Orange

Hex : #FF884D

RGB : 255, 136, 77

Utilisation :

* Exécutions
* Gros impacts

---

## Rafale Électrique

Nom : Electric Blue

Hex : #4DA6FF

RGB : 77, 166, 255

Utilisation :

* Chaînes électriques
* Tirs électriques rapides

---

# Feedback Priority

Une synergie devrait idéalement fournir :

1. FloatingText
2. Outline lumineux
3. Ligne de connexion (si applicable)
4. Modification du projectile
5. Modification de l'impact
6. Icône persistante

---

# Official Visual Rules

## Outline Colors

Les outlines sont réservés aux buffs ou synergies actives.

Ils ne doivent jamais être utilisés pour :

- La sélection de tour
- Les dégâts
- Les critiques
- Les états temporaires

Une couleur = une famille de synergies.

---

## Floating Text Rules

Mama Cog :
+10%

Execution Froide :
TIRS GUIDÉS !

Glace Pilonnée :
GLACE PILONNÉE !

Mur Tesla :
MUR TESLA !

Poison Maudit :
POISON MAUDIT !

Les FloatingText doivent durer entre 1 et 2 secondes maximum.

Ils ne doivent apparaître qu'à l'activation de la synergie et non en continu.

---

# Technical Architecture

Le système de synergies repose sur :

SynergyManager

Responsabilités :

- Recalculer toutes les synergies
- Activer les bonus
- Activer les feedbacks visuels
- Créer les FloatingText
- Créer les liens visuels

Les tours ne doivent pas gérer directement leurs synergies.

Toute nouvelle synergie doit être implémentée dans SynergyManager.

---

# Current State

Implemented :

* FloatingText
* Mama Cog Outline
* Execution Froide Link
* Execution Froide Damage Bonus
* SynergyManager centralisé

Planned :

* Icônes de synergies
* Couleurs de projectiles par synergie
* Impacts spécifiques par synergie
* UI des synergies actives sur tour sélectionnée
