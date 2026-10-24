"""Normalise les sprites du Vampire au MÊME format que les tours punk déjà
normalisées (canvas 572x500, hauteur de contenu 400px, pieds ancrés à y=480),
pour qu'il s'affiche à la même échelle en jeu.
"""
import os
import shutil
from PIL import Image

SRC = os.path.join(os.path.dirname(__file__), "..", "assets", "towers", "vampire")
BACKUP = os.path.join(SRC, "_backup")

# Mêmes valeurs que la normalisation des tours punk.
CANVAS_W = 572
CANVAS_H = 500
FOOT_Y = 480
TARGET_CONTENT_HEIGHT = 400

FILES = ["VampireEST.png", "VampireNORD.png", "VampireSUD.png", "VampireWEST.png"]


def main():
    os.makedirs(BACKUP, exist_ok=True)
    print(f"Canvas cible : {CANVAS_W}x{CANVAS_H}, pieds y={FOOT_Y}, contenu {TARGET_CONTENT_HEIGHT}px\n")

    for name in FILES:
        path = os.path.join(SRC, name)
        if not os.path.exists(path):
            print(f"  !! introuvable : {name}")
            continue

        backup_path = os.path.join(BACKUP, name)
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
        paste_x = round((CANVAS_W - sw) / 2)
        paste_y = FOOT_Y - sh
        canvas.paste(resized, (paste_x, paste_y), resized)
        canvas.save(path)

        print(f"  {name:20s} {bw}x{bh} -> {sw}x{sh} sur {CANVAS_W}x{CANVAS_H}")

    print(f"\nOriginaux sauvegardés dans : {BACKUP}")


if __name__ == "__main__":
    main()
