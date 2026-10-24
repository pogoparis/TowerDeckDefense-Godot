import os
import re
import shutil
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "towers", "punk")
BACKUP = os.path.join(ROOT, "_backup")

TARGET_CONTENT_HEIGHT = 400
MARGIN = 40  # px of transparent padding around the tallest/widest scaled sprite
FOOT_MARGIN_BOTTOM = 20  # px between feet and canvas bottom edge

DIRECTION_RE = re.compile(r"(est|nord|sud|ouest|west)", re.IGNORECASE)


def find_orientation_files(dirpath, filenames):
    return sorted(f for f in filenames if f.lower().endswith(".png") and DIRECTION_RE.search(f))


def content_bbox(im):
    return im.getbbox()


def main():
    towers = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        if os.path.abspath(dirpath).startswith(os.path.abspath(BACKUP)):
            continue
        files = find_orientation_files(dirpath, filenames)
        if files:
            towers.append((dirpath, files))

    # Pass 1: compute a scale factor PER IMAGE (not per tower) so every
    # orientation ends up with the same content height, even if the source
    # art drew nord/sud smaller than est/ouest.
    tower_data = []
    for dirpath, files in towers:
        infos = []
        for f in files:
            path = os.path.join(dirpath, f)
            im = Image.open(path).convert("RGBA")
            bbox = content_bbox(im)
            if bbox is None:
                continue
            bh = bbox[3] - bbox[1]
            scale = TARGET_CONTENT_HEIGHT / bh
            infos.append((f, im, bbox, scale))
        if infos:
            tower_data.append((dirpath, infos))

    # Pass 2: compute max scaled width/height to size a single common canvas
    max_w, max_h = 0, 0
    for dirpath, infos in tower_data:
        for f, im, bbox, scale in infos:
            bw = bbox[2] - bbox[0]
            bh = bbox[3] - bbox[1]
            sw, sh = round(bw * scale), round(bh * scale)
            max_w = max(max_w, sw)
            max_h = max(max_h, sh)

    canvas_w = max_w + MARGIN * 2
    canvas_h = max_h + MARGIN * 2 + FOOT_MARGIN_BOTTOM
    foot_y = canvas_h - FOOT_MARGIN_BOTTOM
    print(f"Canvas commun choisi : {canvas_w}x{canvas_h}, pieds à y={foot_y}")

    # Pass 3: backup + write normalized images
    for dirpath, infos in tower_data:
        rel = os.path.relpath(dirpath, ROOT)
        print(f"\n=== {rel} ===")
        for f, im, bbox, scale in infos:
            src_path = os.path.join(dirpath, f)

            backup_dir = os.path.join(BACKUP, rel)
            os.makedirs(backup_dir, exist_ok=True)
            backup_path = os.path.join(backup_dir, f)
            if not os.path.exists(backup_path):
                shutil.copy2(src_path, backup_path)

            cropped = im.crop(bbox)
            bw, bh = cropped.size
            sw, sh = max(1, round(bw * scale)), max(1, round(bh * scale))
            resized = cropped.resize((sw, sh), Image.LANCZOS)

            canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
            paste_x = round((canvas_w - sw) / 2)
            paste_y = round(foot_y - sh)
            canvas.paste(resized, (paste_x, paste_y), resized)

            canvas.save(src_path)
            print(f"  {f:40s} {bw}x{bh} -> {sw}x{sh} sur canvas {canvas_w}x{canvas_h}")

    print(f"\nOriginaux sauvegardés dans: {BACKUP}")


if __name__ == "__main__":
    main()
