"""Fabrique la vue OUEST d'un sprite à partir de sa vue EST (miroir horizontal).

Pourquoi
--------
Faire générer quatre vues cohérentes à une IA est le point qui casse : elle
intervertit les mains, déplace les accessoires, change les proportions. Or la
vue ouest n'a AUCUNE raison d'être générée — c'est le miroir exact de l'est, et
un retournement est parfait par construction.

Générer 2 vues au lieu de 4, c'est deux fois moins de travail ET deux fois
moins d'occasions d'incohérence.

⚠ Une seule contrainte : pas de TEXTE ni de logo asymétrique sur le sprite,
ils apparaîtraient inversés. Un symbole centré ou répété des deux côtés passe
sans problème.

Usage
-----
    python scripts_tools/mirror_view.py <chemin_vue_est.png> [chemin_sortie.png]

Sans chemin de sortie, le fichier est écrit à côté en remplaçant "est" par
"ouest" dans le nom (ou "East"/"West", "E_"/"W_").
"""
import os
import re
import sys

from PIL import Image

# Paires de substitution testées dans l'ordre, insensibles à la casse.
NAME_RULES = [
    ("ouest", "est"), ("west", "east"), ("_w", "_e"), ("-w", "-e"),
]


def output_path(src: str) -> str:
    base = os.path.basename(src)
    for west, east in NAME_RULES:
        pattern = re.compile(re.escape(east), re.IGNORECASE)
        if pattern.search(base):
            return os.path.join(os.path.dirname(src), pattern.sub(west, base, count=1))
    root, ext = os.path.splitext(src)
    return f"{root}_ouest{ext}"


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        return

    src = sys.argv[1]
    if not os.path.isfile(src):
        print(f"Introuvable : {src}")
        return

    dst = sys.argv[2] if len(sys.argv) > 2 else output_path(src)
    if os.path.abspath(dst) == os.path.abspath(src):
        print("Le fichier de sortie serait le fichier source — annulé.")
        return

    img = Image.open(src).convert("RGBA")
    img.transpose(Image.FLIP_LEFT_RIGHT).save(dst)
    print(f"{os.path.basename(src)} -> {os.path.basename(dst)}")


if __name__ == "__main__":
    main()
