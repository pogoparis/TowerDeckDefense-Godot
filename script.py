import os

def list_assets(directory, prefix=""):
    try:
        items = sorted(os.listdir(directory))
    except PermissionError:
        print(prefix + "⛔ Accès refusé :", directory)
        return

    for i, item in enumerate(items):
        path = os.path.join(directory, item)
        is_last = i == len(items) - 1

        connector = "└── " if is_last else "├── "
        print(prefix + connector + item)

        if os.path.isdir(path):
            extension = "    " if is_last else "│   "
            list_assets(path, prefix + extension)

# 👉 Remplace par le chemin vers ton dossier assets
assets_path = "assets"

print("📦 Structure du dossier assets :\n")
list_assets(assets_path)