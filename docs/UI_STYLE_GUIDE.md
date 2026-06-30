# Junkriot — Guide de style UI

> **Règle d'or : AUCUN style dans le code GDScript.**
> Le code fait la logique. L'éditeur Godot fait le visuel et les données.

---

## 1. Le thème unique

Tout le style UI du jeu vit dans **un seul fichier** :

```
res://resources/themes/junkriot_theme.tres
```

- Il s'édite **dans l'éditeur Godot** (double-clic → éditeur de thème).
- Il est assigné à la **racine de chaque scène UI** (propriété `theme`).
  Le thème se propage automatiquement à tous les enfants.
- Interdiction d'écrire `StyleBoxFlat.new()`, `add_theme_color_override()`,
  `add_theme_font_size_override()` etc. dans un script pour du style statique.

**Seule exception tolérée** : une couleur *dynamique* pilotée par la logique
(ex. PV de la base vert → orange → rouge). Dans ce cas la couleur est un
`@export` réglable dans l'inspecteur, jamais une constante en dur.

---

## 2. Les variations de thème disponibles

Assigner via l'inspecteur : `Control > Theme > Theme Type Variation`.

### Boutons
| Variation | Usage |
|---|---|
| *(défaut)* | Bouton standard sombre/doré (PauseMenu, RETOUR, CONFIRMER…) |
| `DangerButton` | Action destructive (QUITTER AU MENU) — teinte rouge |
| `GhostButton` | Zone cliquable invisible posée sur une image (MainMenu) — hover doré translucide |
| `HUDButton` | Petit bouton compact du TopHUD (vitesse, ⚙) |

### Panneaux
| Variation | Usage |
|---|---|
| `DarkPanel` (Panel) | Panneau modal sombre, bordure dorée, coins 14px |
| `HUDPanel` (PanelContainer) | Conteneur du TopHUD, bordure lavande |
| `CardBarPanel` (PanelContainer) | Bande sombre derrière les cartes en main |
| `PreviewPanel` (PanelContainer) | Encart "prochaine vague" en haut à droite |
| `TooltipPanel` (Panel) | Tooltip de carte (bordure dorée + ombre portée) |

### Barres
| Variation | Usage |
|---|---|
| `GoldBar` (ProgressBar) | Barre dorée sur fond sombre (splash, barre de vague) |

### Labels
| Variation | Taille | Usage |
|---|---|---|
| `TitleGold` | 26 | Titres de panneaux (PAUSE, OPTIONS…) |
| `OverlayTitle` | 32 | Titre d'overlay plein écran (mulligan) |
| `OverlaySub` | 18 | Sous-titre d'overlay |
| `ResultTitle` | 110 | VICTOIRE / DÉFAITE (couleur définie par le code via @export) |
| `SubtleText` | 20 | Texte secondaire discret |
| `FormLabel` | 14 | Étiquettes de formulaire (sliders, options) |
| `LoadingText` | 14 | Messages de chargement (avec ombre) |
| `StatusText` | 12 | Ligne de statut du TopHUD, coût des cartes (tooltip) |
| `HUDStatTitle` | 10 | Petits titres gris du HUD (VAGUE, KILLS…) |
| `HUDStatValue` | 20 | Valeurs blanches du HUD |
| `PreviewTitle` | 13 | Titre de l'encart "prochaine vague" (doré sombre) |
| `PreviewText` | 14 | Contenu de l'encart "prochaine vague" |
| `AlertText` | 13 | Alerte rouge (⚠ MINIBOSS) |
| `CardNameLabel` | 20 | Nom de carte dans le tooltip (doré clair) |

### RichTextLabel
| Variation | Taille | Usage |
|---|---|---|
| `TooltipBody` | 14 | Description de carte dans le tooltip |
| `SynergyText` | 13 | Synergies dans le tooltip (cyan) |

---

## 3. Ajouter un nouveau style

1. Ouvrir `junkriot_theme.tres` dans l'éditeur Godot
2. **Réutiliser** une variation existante si possible
3. Sinon : `+` → *Add Type* → nommer en `PascalCase` → définir `base_type`
4. Documenter la nouvelle variation **dans ce fichier** (tableau ci-dessus)

---

## 4. Scènes et scripts UI

| Principe | Concrètement |
|---|---|
| Scene-first | Toute arborescence visuelle vit dans un `.tscn`, jamais créée en code |
| Valeurs réglables | `@export` avec valeur par défaut — réglable dans l'inspecteur |
| Chemins de scènes | `@export_file("*.tscn")` — jamais de chemin en dur dans la logique |
| Textes fixes | Dans le `.tscn` (propriété `text`) |
| Textes dynamiques | Dans le script (formatage `%d/%d`…) |
| Effets visuels | Scène dédiée qui gère sa propre animation et son `queue_free()` |
| Docstrings | Chaque script commence par `##` expliquant son rôle |

---

## 5. Zones cliquables sur une image (pattern ImageAnchor)

Quand des boutons sont **dessinés dans une illustration** (ex. menu principal) :

1. Le fond est un `TextureRect` en `KEEP_ASPECT_COVERED`
2. Les zones cliquables (`GhostButton`) vivent dans un `AspectRatioContainer`
   avec `ratio = largeur/hauteur de l'image` et `stretch_mode = COVER`
3. Les anchors des boutons sont des **fractions de l'image** → les zones
   suivent l'image quelle que soit la taille/le ratio de la fenêtre
4. Si l'image change : mettre à jour `ratio` + ajuster les anchors dans l'éditeur

---

## 6. Images et assets

- Les images sont créées **par un humain**, jamais simulées en code
- Grandes images (splash, fonds de menu) : `res://assets/ui/`
- Icônes : `res://assets/icons/`
- Formats : PNG, nommage `snake_case`

### Assets UI actuels
| Fichier | Usage |
|---|---|
| `assets/ui/splash_bg.png` | Écran de chargement |
| `assets/ui/MENU_OK.png` | Fond du menu principal |
| `assets/ui/LogoGooglePlay.png` | Icône du projet/application |
| `assets/icons/reglages256.png` | Bouton paramètres du TopHUD |

### Assets en attente de création
- Icône engrenage (remplacer le caractère ⚙ du TopHUD) — 64×64
- Icônes réseaux sociaux (Discord, X, TikTok) — 64×64 chacune
