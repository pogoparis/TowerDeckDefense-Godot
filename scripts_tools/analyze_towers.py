import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "towers", "punk")

def bbox_info(path):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    bbox = im.getbbox()  # non-transparent content bounding box
    if bbox is None:
        return w, h, None
    return w, h, bbox

def main():
    for dirpath, dirnames, filenames in os.walk(ROOT):
        pngs = [f for f in filenames if f.lower().endswith(".png")]
        if not pngs:
            continue
        print(f"\n=== {os.path.relpath(dirpath, ROOT)} ===")
        for f in sorted(pngs):
            path = os.path.join(dirpath, f)
            w, h, bbox = bbox_info(path)
            if bbox:
                bw = bbox[2] - bbox[0]
                bh = bbox[3] - bbox[1]
                # foot point = bottom-center of content bbox, in canvas coords
                foot_x = (bbox[0] + bbox[2]) / 2
                foot_y = bbox[3]
                print(f"  {f:45s} canvas={w}x{h:<5} content={bw}x{bh:<5} bbox={bbox} foot=({foot_x:.0f},{foot_y:.0f})")
            else:
                print(f"  {f:45s} canvas={w}x{h:<5} EMPTY/TRANSPARENT")

if __name__ == "__main__":
    main()
