# Synergies élémentaires — guide éditeur Godot

## Autoloads (déjà dans project.godot)

- `SynergyManager`, `SynergyGuideService`, `PhenomenonManager`, `ReactionManager`

## Tester l’UX placement

1. Ouvrir `scenes/test_synergy_placement.tscn`
2. *Projet → Paramètres du projet → Application → Scène principale* → définir temporairement cette scène
3. F6 : une Bobine Foudre est déjà posée ; placer Canon à Flotte ou Souffleur sur une case adjacente
4. Panneau « Synergies » (runs 0–2) + surbrillance des cases partenaires

## Niveau de guidage (debug)

Sur le nœud autoload `SynergyGuideService` (onglet Autoload dans les paramètres) :

- `force_guide_level = 0` → complet (panneau + halos)
- `force_guide_level = 1` → réduit (halos, pas de panneau)
- `force_guide_level = 2` → terrain seul (liens combat uniquement)

## Données

- Règles : `data/synergies/water_electric.tres`, `air_electric.tres`
- Tours Tempête : `data/towers/tower_*.tres`

## Scène principale

`scenes/level.tscn` — deck Tempête (3 cartes Eau / Élec / Air)
