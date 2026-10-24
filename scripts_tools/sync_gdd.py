"""Régénère les tables de données du GDD à partir du CODE.

Pourquoi cet outil existe
-------------------------
Les tables du GDD ont déjà menti deux fois : les portées des tours (le doc
disait 120, le vrai chiffre allait de 170 à 210 — j'avais lu la valeur par
défaut du script au lieu des scènes) et la vitesse du Kamikazé (90 au lieu de
180). Ces deux erreurs ont directement faussé des décisions d'équilibrage.

Un document rédigé à la main dérive dès le premier réglage. Ici, les tables
sont EXTRAITES des .tscn et .tres : elles ne peuvent pas se tromper, et une
relecture suffit à voir l'état réel du jeu.

Usage
-----
    python scripts_tools/sync_gdd.py

Les tables du fichier docs/JUNKRIOT_CONTENU_V1.md situées entre les marqueurs
<!-- AUTO:xxx --> et <!-- /AUTO:xxx --> sont remplacées. Tout le reste du
document (analyse, règles de design) est écrit à la main et n'est jamais touché.
"""
import glob
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), "..")
DOC = os.path.join(ROOT, "docs", "JUNKRIOT_CONTENU_V1.md")

ELEMENTS = {
    0: "—", 1: "🔥 Feu", 2: "💧 Eau", 3: "⚡ Élec", 4: "🌿 Nature",
    5: "🌪 Air", 6: "❄ Glace", 7: "🦇 Ombre", 8: "✨ Lumière", 9: "🪨 Terre",
}
PHENOMENA = {
    0: "—", 1: "WATER_POOL", 2: "ELECTRIC_FIELD", 3: "FIRE_ZONE",
    4: "THORN_PATCH", 5: "WIND_CURRENT", 6: "SHADOW_ZONE", 7: "STONE_RAIN",
}
EFFECTS = {0: "Dégâts", 1: "Étourdit", 2: "Pose un phénomène", 3: "Dope les tours"}


def prop(text, key, default=None):
    m = re.search(rf"^{key} = (.+)$", text, flags=re.M)
    return m.group(1).strip() if m else default


def num(text, key, default="0"):
    """Nombre lisible : '200.0' -> '200', mais '10' reste '10'.

    ⚠ Ne jamais rstrip('0') sans vérifier le point décimal : un entier comme
    10 deviendrait 1, et la table du GDD annoncerait des dégâts dix fois trop
    faibles. C'est exactement ce genre d'erreur silencieuse que cet outil est
    censé éliminer.
    """
    v = prop(text, key, default)
    return (v.rstrip("0").rstrip(".") or "0") if "." in v else v


def read(path):
    return open(path, encoding="utf-8").read()


def cards():
    """Toutes les cartes, indexées par nom de fichier."""
    out = {}
    for f in glob.glob(os.path.join(ROOT, "resources", "cards", "*.tres")):
        out[os.path.basename(f)[:-5]] = read(f)
    return out


# ── Tables ────────────────────────────────────────────

def table_towers(all_cards):
    # Coût et nom viennent de la CARTE, stats de la SCÈNE.
    by_scene = {}
    for cid, s in all_cards.items():
        m = re.search(r'path="res://scenes/towers/(\w+)\.tscn"', s)
        if m:
            by_scene[m.group(1)] = (prop(s, "card_name", '""').strip('"'),
                                    prop(s, "mana_cost", "0"))

    rows = []
    for f in sorted(glob.glob(os.path.join(ROOT, "scenes", "towers", "Tower*.tscn"))):
        s = read(f)
        scene = os.path.basename(f)[:-5]
        name, cost = by_scene.get(scene, (scene, "?"))
        if prop(s, "charge_auto", "false") == "true":
            kind = "**auto**"
        elif prop(s, "is_signature", "false") == "true":
            kind = "**signature**"
        else:
            kind = "base"
        rows.append((int(cost) if cost.isdigit() else 999, [
            name, ELEMENTS[int(prop(s, "element_type", "0"))], cost,
            num(s, "base_damage", "10"), prop(s, "base_fire_rate", "0.8"),
            num(s, "base_range", "120.0"), kind,
        ]))
    rows.sort(key=lambda r: r[0])

    out = ["| Tour | Élément | Coût | Dégâts | Cadence | Portée | Type |",
           "|---|---|---|---|---|---|---|"]
    out += ["| " + " | ".join(r[1]) + " |" for r in rows]
    return "\n".join(out)


def table_spells(all_cards):
    rows = []
    for cid, s in all_cards.items():
        if prop(s, "card_type", "0") != "1":
            continue
        m = re.search(r'path="res://resources/spells/(\w+)\.tres"', s)
        if not m:
            continue
        sp = read(os.path.join(ROOT, "resources", "spells", m.group(1) + ".tres"))
        effect = EFFECTS.get(int(prop(sp, "effect", "0")), "?")
        detail = []
        if prop(sp, "damage"):
            detail.append(f"{prop(sp, 'damage')} dégâts")
        ph = int(prop(sp, "phenomenon", "0"))
        if ph:
            detail.append(f"`{PHENOMENA[ph]}`")
        if prop(sp, "duration"):
            detail.append(f"{num(sp, 'duration')} s")
        if prop(sp, "buff_damage_mult"):
            detail.append(f"×{prop(sp, 'buff_damage_mult')} dégâts aux tours")
        cost = prop(s, "mana_cost", "0")
        rows.append((int(cost) if cost.isdigit() else 999, [
            prop(s, "card_name", '""').strip('"'),
            ELEMENTS[int(prop(sp, "element", "0"))], cost,
            num(sp, "radius", "0"), effect, " · ".join(detail) or "—",
        ]))
    rows.sort(key=lambda r: r[0])

    out = ["| Sort | Élément | Coût | Rayon | Effet | Détail |",
           "|---|---|---|---|---|---|"]
    out += ["| " + " | ".join(r[1]) + " |" for r in rows]
    return "\n".join(out)


def table_utility(all_cards):
    rows = []
    TYPES = {2: "Amélioration", 3: "Tactique", 4: "Économie"}
    for cid, s in all_cards.items():
        t = int(prop(s, "card_type", "0"))
        if t not in TYPES:
            continue
        eff = []
        if prop(s, "instant_caps"):
            eff.append(f"+{prop(s, 'instant_caps')} Caps")
        if prop(s, "caps_per_wave"):
            eff.append(f"+{prop(s, 'caps_per_wave')} Caps/vague")
        if prop(s, "draw_cards"):
            eff.append(f"pioche {prop(s, 'draw_cards')}")
        if prop(s, "free_upgrade") == "true":
            eff.append("améliore une tour gratuitement")
        cost = prop(s, "mana_cost", "0")
        rows.append((int(cost) if cost.isdigit() else 999, [
            prop(s, "card_name", '""').strip('"'), TYPES[t], cost,
            " · ".join(eff) or "—",
        ]))
    rows.sort(key=lambda r: r[0])

    out = ["| Carte | Type | Coût | Effet |", "|---|---|---|---|"]
    out += ["| " + " | ".join(r[1]) + " |" for r in rows]
    return "\n".join(out)


def table_enemies():
    NAMES = {
        "SimpleMob": "Pillard", "ExplosiveMob": "Kamikazé", "TankMob": "Tank",
        "DroneMob": "Drone Jaune", "DronePunkMob": "Drone Punk", "MiniBoss": "MiniBoss",
    }
    rows = []
    for f in sorted(glob.glob(os.path.join(ROOT, "scenes", "enemies", "*.tscn"))):
        s = read(f)
        key = os.path.basename(f)[:-5]
        hp = int(prop(s, "max_hp", "30"))
        spd = float(prop(s, "speed", "120.0"))
        rows.append((hp, [
            NAMES.get(key, key), str(hp), str(int(spd)),
            prop(s, "armor", "0"),
            ELEMENTS[int(prop(s, "weak_to", "0"))],
            ELEMENTS[int(prop(s, "resists", "0"))],
            prop(s, "cap_reward", "1"), prop(s, "leak_damage", "1"),
            # PV × vitesse : la seule mesure qui compare honnêtement deux
            # ennemis (voir RÈGLE 9bis).
            f"{hp * spd / 1000:.1f}k",
        ]))
    rows.sort(key=lambda r: r[0])

    out = ["| Ennemi | PV | Vitesse | Blindage | Faible à | Résiste à | Caps | Fuite | PV×vit |",
           "|---|---|---|---|---|---|---|---|---|"]
    out += ["| " + " | ".join(r[1]) + " |" for r in rows]
    return "\n".join(out)


def table_decks(all_cards):
    by_name = {}
    for cid, s in all_cards.items():
        by_name[cid] = prop(s, "card_name", '""').strip('"')

    out = []
    for f in sorted(glob.glob(os.path.join(ROOT, "resources", "decks", "deck_*.tres"))):
        s = read(f)
        ids = dict(re.findall(r'path="res://resources/cards/(\w+)\.tres" id="(\w+)"', s))
        rev = {v: k for k, v in ids.items()}
        seq = re.findall(r'ExtResource\("(\w+)"\)', prop(s, "cards", "[]"))
        counts = {}
        for ref in seq:
            cid = rev.get(ref)
            if cid:
                counts[by_name.get(cid, cid)] = counts.get(by_name.get(cid, cid), 0) + 1
        name = prop(s, "deck_name", '""').strip('"')
        listing = " · ".join(f"{n} ×{c}" for n, c in counts.items())
        out.append(f"**{name}** ({len(seq)} cartes) — {listing}")
    return "\n\n".join(out)


def table_counts(all_cards):
    kinds = {0: "Tours", 1: "Sorts", 2: "Améliorations", 3: "Tactiques", 4: "Économie"}
    counts = {}
    illustrated = 0
    for cid, s in all_cards.items():
        t = int(prop(s, "card_type", "0"))
        counts[t] = counts.get(t, 0) + 1
        if "card_texture" in s:
            illustrated += 1
    total = sum(counts.values())
    out = ["| Famille | Nombre |", "|---|---|"]
    for t, label in kinds.items():
        out.append(f"| {label} | {counts.get(t, 0)} |")
    out.append(f"| **Total cartes** | **{total}** |")
    out.append(f"| Illustrées | {illustrated} / {total} |")
    n_bonus = len(glob.glob(os.path.join(ROOT, "resources", "bonuses", "*.tres")))
    out.append(f"| Bonus de run | {n_bonus} |")
    return "\n".join(out)


def main():
    all_cards = cards()
    blocks = {
        "TOURS": table_towers(all_cards),
        "SORTS": table_spells(all_cards),
        "UTILITAIRES": table_utility(all_cards),
        "ENNEMIS": table_enemies(),
        "DECKS": table_decks(all_cards),
        "COMPTES": table_counts(all_cards),
    }

    doc = read(DOC)
    for key, body in blocks.items():
        # Tolère un bloc vide : au tout premier passage il n'y a rien entre
        # les deux marqueurs.
        pattern = re.compile(
            rf"(<!-- AUTO:{key} -->\n)(.*?)(<!-- /AUTO:{key} -->)", re.S)
        if not pattern.search(doc):
            print(f"  ! marqueur AUTO:{key} absent du document")
            continue
        doc = pattern.sub(lambda m: m.group(1) + body + "\n" + m.group(3), doc)
        print(f"  {key} : {len(body.splitlines())} lignes")

    open(DOC, "w", encoding="utf-8").write(doc)
    print("docs/JUNKRIOT_CONTENU_V1.md synchronise avec le code.")


if __name__ == "__main__":
    main()
