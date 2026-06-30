"""
JunkRiot — Rendu 8 directions depuis un .glb Meshy
═══════════════════════════════════════════════════
PRINCIPE (jeu top-down) :
  - Caméra FIXE au sud, surélevée (= la caméra du jeu)
  - Le MODÈLE tourne de 45° en 45° (via un PIVOT central) pour 8 orientations

Modifier GLB_PATH + OUTPUT_DIR puis Run Script (▶)
"""

import bpy
import math
import mathutils
import os

# ════════════════════════════════════════
#  CONFIGURATION
# ════════════════════════════════════════
GLB_PATH   = r"C:\Users\simone\Downloads\DeckTowerDefense-GODOT\3D\ThunderMesh.glb"
OUTPUT_DIR = r"D:\GodotProjects\deck-tower-defense\assets\towers\thunder"
TOWER_NAME = "thunder"

RENDER_SIZE  = 512
CAM_ELEV     = 52     # élévation de la caméra (degrés) — 45-60 pour vue 3/4 TD
CAM_DIST     = 3.0
ORTHO_SCALE  = 2.8    # agrandir si la tour est coupée
SAMPLES      = 96
# ════════════════════════════════════════

# ── Vider la scène ───────────────────────────────────────────
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# ── Importer le GLB ──────────────────────────────────────────
bpy.ops.import_scene.gltf(filepath=GLB_PATH)
imported = list(bpy.context.selected_objects)

# ── Centre du modèle (boîte englobante en coords monde) ──────
min_v = mathutils.Vector(( 1e9,  1e9,  1e9))
max_v = mathutils.Vector((-1e9, -1e9, -1e9))
for obj in imported:
    if obj.type == 'MESH':
        for corner in obj.bound_box:
            wc = obj.matrix_world @ mathutils.Vector(corner)
            min_v.x = min(min_v.x, wc.x); min_v.y = min(min_v.y, wc.y); min_v.z = min(min_v.z, wc.z)
            max_v.x = max(max_v.x, wc.x); max_v.y = max(max_v.y, wc.y); max_v.z = max(max_v.z, wc.z)
center = (min_v + max_v) * 0.5

# ── PIVOT central : on parente TOUT dessus et on tourne LE PIVOT ──
# (rotation robuste quelle que soit la hiérarchie du .glb)
pivot = bpy.data.objects.new("Pivot", None)
bpy.context.scene.collection.objects.link(pivot)
pivot.location = center

for obj in imported:
    if obj.parent is None:
        obj.parent = pivot
        obj.matrix_parent_inverse = pivot.matrix_world.inverted()

# Recentre le modèle à l'origine du monde
pivot.location = (0.0, 0.0, 0.0)

# ── Couleurs PÉTARD : gestion couleur "Standard" ─────────────
# (par défaut Blender utilise AgX/Filmic qui désature et assombrit)
scene = bpy.context.scene
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'None'
scene.view_settings.exposure = 0.0
scene.view_settings.gamma = 1.0

# ── Lumières ─────────────────────────────────────────────────
def add_light(name, ltype, energy, rot_deg):
    d = bpy.data.lights.new(name, ltype)
    d.energy = energy
    o = bpy.data.objects.new(name, d)
    bpy.context.scene.collection.objects.link(o)
    o.rotation_euler = tuple(math.radians(r) for r in rot_deg)

add_light("Key",  'SUN', 3.5, (50, 0, -30))
add_light("Fill", 'SUN', 1.5, (40, 0, 120))
add_light("Rim",  'SUN', 1.2, (20, 0, 195))

# ── Caméra FIXE au sud, surélevée ────────────────────────────
elev = math.radians(CAM_ELEV)
cam_data = bpy.data.cameras.new("Cam")
cam_data.type        = 'ORTHO'
cam_data.ortho_scale = ORTHO_SCALE
cam_obj = bpy.data.objects.new("Cam", cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
scene.camera = cam_obj
cam_obj.location = (
    0.0,
    -CAM_DIST * math.cos(elev),
     CAM_DIST * math.sin(elev)
)

target = bpy.data.objects.new("Target", None)
bpy.context.scene.collection.objects.link(target)
target.location = (0, 0, 0)
ct = cam_obj.constraints.new('TRACK_TO')
ct.target     = target
ct.track_axis = 'TRACK_NEGATIVE_Z'
ct.up_axis    = 'UP_Y'

# ── Rendu ────────────────────────────────────────────────────
scene.render.resolution_x = RENDER_SIZE
scene.render.resolution_y = RENDER_SIZE
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode  = 'RGBA'
scene.render.engine  = 'CYCLES'
scene.cycles.samples = SAMPLES

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── 8 orientations : on tourne LE PIVOT autour de Z ──────────
face_dirs = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]

for i, name in enumerate(face_dirs):
    pivot.rotation_euler.z = math.radians(i * 45.0)
    bpy.context.view_layer.update()

    out = os.path.join(OUTPUT_DIR, f"{TOWER_NAME}_facing_{name}.png")
    scene.render.filepath = out
    bpy.ops.render.render(write_still=True)
    print(f"✓ facing_{name} ({i*45:3d}°) → {out}")

print(f"\n✅ Terminé ! 8 sprites dans : {OUTPUT_DIR}")
