"""Superpose la grille de jeu sur un fond de niveau, avant de l'intégrer.

Pourquoi
--------
Un fond se juge sur ce qu'il LAISSE LIBRE, pas sur sa beauté. La grille occupe
une zone précise de l'écran ; si le décor y pose une maison ou un arbre, les
tours s'afficheront par-dessus et la lecture du terrain sera brouillée. Le
vérifier après intégration coûte un aller-retour complet dans Godot — ici c'est
immédiat, et sur l'image source.

L'aperçu montre trois choses :
  • la grille 17x8 telle qu'elle sera à l'écran,
  • le cadre rouge de la zone jouable,
  • ce que devient l'image une fois mise à l'échelle par le jeu (« cover »),
    donc ce qui sera rogné sur les bords.

Usage
-----
    python scripts_tools/preview_background.py <image.png> [sortie.png] [--niveau=N]

Sans --niveau, c'est le trace par defaut de level.tscn qui est affiche.
"""
import os
import re
import sys

from PIL import Image, ImageDraw

# Doivent rester alignés sur grid_manager.gd et project.godot.
SCREEN = (1920, 1080)
GRID_W, GRID_H, CELL = 17, 8, 96
OFFSET = (200, 200)

LEVEL_SCENE = "scenes/ui/level.tscn"
LEVEL_SCRIPT = "scripts/core/level.gd"


def read_card_bar_top():
    """Hauteur a laquelle la barre de cartes commence a masquer le terrain.

    Lue dans la scene : c'est la seule facon que l'apercu reste juste quand la
    barre est retaillee — et c'est exactement ce qu'on vient de faire.
    """
    src = open(LEVEL_SCENE, encoding="utf-8").read()
    block = src.split('[node name="CardBarBackground"', 1)
    if len(block) < 2:
        return None
    mo = re.search(r"offset_top = (-[\d.]+)", block[1])
    return SCREEN[1] + float(mo.group(1)) if mo else None


def read_level_path(level_id):
    """Trace propre a un niveau, lu dans sa scene d'edition.

    C'est la scene que Simone ouvre dans Godot pour deplacer les points ; le
    jeu n'en lit rien d'autre que cette courbe. L'apercu lit donc la meme
    source, et reste juste apres chaque coup de souris.
    """
    path = os.path.join("scenes", "paths", f"chemin_niveau_{level_id}.tscn")
    if not os.path.isfile(path):
        return []
    src = open(path, encoding="utf-8").read()
    m = re.search(r'"points": PackedVector2Array\(([^)]+)\)', src)
    if not m:
        return []
    nums = [float(v) for v in m.group(1).split(",")]
    # Format Godot : (in_x, in_y, out_x, out_y, pos_x, pos_y) par point.
    return [(nums[i + 4], nums[i + 5]) for i in range(0, len(nums), 6)]


def read_path():
    """Trace du chemin, LU dans la scene plutot que recopie ici.

    Recopier les points condamnerait l'outil a mentir des le premier chemin
    modifie — et c'est precisement quand on retouche le trace qu'on a besoin
    de verifier ce qu'il recouvre.
    """
    src = open(LEVEL_SCENE, encoding="utf-8").read()
    m = re.search(r'"points": PackedVector2Array\(([^)]+)\)', src)
    if not m:
        return []
    nums = [float(v) for v in m.group(1).split(",")]
    # Format Godot : (in_x, in_y, out_x, out_y, pos_x, pos_y) par point.
    pts = [(nums[i + 4], nums[i + 5]) for i in range(0, len(nums), 6)]

    # Le Path2D porte lui-meme un decalage : sans lui, le trace serait affiche
    # a 70 px a gauche et 129 px au-dessus de sa vraie position.
    off = (0.0, 0.0)
    block = src.split('[node name="Path2D"', 1)
    if len(block) > 1:
        mo = re.search(r"position = Vector2\(([-\d.]+), ?([-\d.]+)\)", block[1])
        if mo:
            off = (float(mo.group(1)), float(mo.group(2)))
    return [(x + off[0], y + off[1]) for x, y in pts]


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        return

    src = sys.argv[1]
    if not os.path.isfile(src):
        print(f"Introuvable : {src}")
        return

    im = Image.open(src).convert("RGBA")
    print(f"Source      : {im.size[0]}x{im.size[1]}  (ratio {im.size[0]/im.size[1]:.3f})")
    print(f"Ecran       : {SCREEN[0]}x{SCREEN[1]}  (ratio {SCREEN[0]/SCREEN[1]:.3f})")

    # Le jeu couvre l'ecran sans deformer : meme facteur sur les deux axes.
    factor = max(SCREEN[0] / im.size[0], SCREEN[1] / im.size[1])
    scaled = im.resize((round(im.size[0] * factor), round(im.size[1] * factor)),
                       Image.LANCZOS)
    print(f"Facteur     : x{factor:.3f}  ->  {scaled.size[0]}x{scaled.size[1]}")

    crop_x = (scaled.size[0] - SCREEN[0]) // 2
    crop_y = (scaled.size[1] - SCREEN[1]) // 2
    if crop_x or crop_y:
        print(f"Rogne       : {crop_x} px de chaque cote, {crop_y} px en haut et en bas")
    else:
        print("Rogne       : aucun, l'image tombe pile")

    canvas = Image.new("RGBA", SCREEN, (0, 0, 0, 255))
    canvas.alpha_composite(scaled, (-crop_x, -crop_y))

    grid = Image.new("RGBA", SCREEN, (0, 0, 0, 0))
    d = ImageDraw.Draw(grid)
    x0, y0 = OFFSET
    x1, y1 = x0 + GRID_W * CELL, y0 + GRID_H * CELL

    for i in range(GRID_W + 1):
        d.line([(x0 + i * CELL, y0), (x0 + i * CELL, y1)], (255, 255, 255, 70), 1)
    for j in range(GRID_H + 1):
        d.line([(x0, y0 + j * CELL), (x1, y0 + j * CELL)], (255, 255, 255, 70), 1)
    d.rectangle([x0, y0, x1, y1], outline=(255, 60, 60, 230), width=3)

    # Le chemin : c'est LUI qui decide ce que le decor doit laisser libre.
    # Un fond magnifique dont la clairiere ne recouvre pas le trace est un
    # fond a refaire.
    level = None
    for arg in sys.argv[1:]:
        if arg.startswith("--niveau="):
            level = int(arg.split("=")[1])
    pts = read_level_path(level) if level else []
    if not pts:
        pts = read_path()
    if len(pts) > 1:
        d.line(pts, fill=(60, 200, 255, 200), width=CELL // 2 + 6, joint="curve")
        d.line(pts, fill=(255, 255, 255, 210), width=3, joint="curve")
        for i, (px, py) in enumerate(pts):
            d.ellipse([px - 7, py - 7, px + 7, py + 7],
                      fill=(255, 255, 255, 230), outline=(20, 90, 130, 255), width=2)
        rows = [(py - y0) / CELL for _, py in pts]
        print(f"Chemin      : {len(pts)} points, rangees {min(rows):.1f} a {max(rows):.1f} sur {GRID_H}")

    # La barre de cartes mange le bas de l'ecran : tout ce qui passe dessous
    # est invisible en jeu, decor comme chemin.
    bar = read_card_bar_top()
    if bar:
        for x in range(0, SCREEN[0], 24):
            d.line([(x, bar), (x + 14, bar)], (255, 140, 40, 220), 3)
        d.text((16, bar + 8), "BARRE DE CARTES — masque tout ce qui est dessous",
               fill=(255, 170, 70, 255))
        hidden = max(0.0, (y1 - bar) / CELL)
        print(f"Barre cartes: commence a y={bar:.0f}, masque {hidden:.1f} rangee(s) sur {GRID_H}")

    canvas.alpha_composite(grid)

    extra = [a for a in sys.argv[2:] if not a.startswith("--")]
    dst = extra[0] if extra else "docs/apercu_fond.png"
    canvas.convert("RGB").save(dst, quality=95)
    print(f"\nZone jouable: x {x0}-{x1}, y {y0}-{y1}  ({GRID_W}x{GRID_H} cases de {CELL} px)")
    print(f"Ecrit       : {dst}")


if __name__ == "__main__":
    main()
