"""Normalise les sprites directionnels d'UNE tour au format standard du projet
(canvas 572x500, hauteur de contenu 400px, pieds ancrés à y=480), pour que
toutes les tours s'affichent à la même échelle en jeu.

Usage :
    python normalize_tower_dir.py <dossier_relatif_a_assets/towers>
Exemple :
    python normalize_tower_dir.py luciolles

Seuls les PNG dont le nom contient une direction (EST/NORD/SUD/WEST/OUEST)
sont traités — les planches sources sont ignorées.
Les originaux sont sauvegardés dans <dossier>/_backup.
"""
import os
import re
import shutil
import sys
from PIL import Image

# Mêmes valeurs que les tours déjà normalisées.
CANVAS_W = 572
CANVAS_H = 500
FOOT_Y = 480
TARGET_CONTENT_HEIGHT = 400

DIRECTION_RE = re.compile(r"(est|nord|sud|ouest|west)", re.IGNORECASE)


def main():
    if len(sys.argv) < 2:
        print("Usage: python normalize_tower_dir.py <dossier>")
        return

    src = os.path.join(
        os.path.dirname(__file__), "..", "assets", "towers", sys.argv[1]
    )
    if not os.path.isdir(src):
        print(f"Dossier introuvable : {src}")
        return

    backup = os.path.join(src, "_backup")
    os.makedirs(backup, exist_ok=True)

    files = [
        f for f in sorted(os.listdir(src))
        if f.lower().endswith(".png") and DIRECTION_RE.search(f)
    ]
    if not files:
        print("Aucun sprite directionnel trouvé.")
        return

    print(f"Canvas cible : {CANVAS_W}x{CANVAS_H}, pieds y={FOOT_Y}, "
          f"contenu {TARGET_CONTENT_HEIGHT}px\n")

    for name in files:
        path = os.path.join(src, name)

        backup_path = os.path.join(backup, name)
        if not os.path.exists(backup_path):
            shutil.copy2(path, backup_path)

        im = Image.open(path).convert("RGBA")
        bbox = im.getbbox()
        if bbox is None:
            print(f"  !! vide : {name}")
            continue

        cropped = im.crop(bbox)
        bw, bh = cropped.size
        scale = TARGET_CONTENT_HEIGHT / bh
        sw, sh = max(1, round(bw * scale)), max(1, round(bh * scale))
        resized = cropped.resize((sw, sh), Image.LANCZOS)

        canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
        canvas.paste(resized, (round((CANVAS_W - sw) / 2), FOOT_Y - sh), resized)
        canvas.save(path)

        print(f"  {name:28s} {bw}x{bh} -> {sw}x{sh}")

    print(f"\nOriginaux sauvegardés dans : {backup}")


if __name__ == "__main__":
    main()
