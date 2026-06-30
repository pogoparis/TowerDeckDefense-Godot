"""Générateur d'effets sonores placeholder pour JunkRiot.

Produit des .wav 16-bit mono 44100 Hz dans assets/audio/sfx/.
Style synthétique rétro (sfxr-like). À remplacer par de vrais sons
quand la direction audio sera définie.

Usage : python tools/generate_sfx.py
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")


def write_wav(name: str, samples: list[float]) -> None:
    """Écrit une liste d'échantillons [-1, 1] en .wav 16-bit mono."""
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        )
        f.writeframes(frames)
    print(f"  {name} ({len(samples) / SAMPLE_RATE:.2f}s)")


def envelope(t: float, duration: float, attack: float = 0.005, release: float = 0.3) -> float:
    """Enveloppe attaque/release simple, t et duration en secondes."""
    if t < attack:
        return t / attack
    rel_start = duration * (1.0 - release)
    if t > rel_start:
        return max(0.0, 1.0 - (t - rel_start) / (duration - rel_start))
    return 1.0


def sine_sweep(duration, f_start, f_end, vol=0.8, release=0.4):
    n = int(SAMPLE_RATE * duration)
    out, phase = [], 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f = f_start + (f_end - f_start) * (t / duration)
        phase += 2 * math.pi * f / SAMPLE_RATE
        out.append(math.sin(phase) * envelope(t, duration, release=release) * vol)
    return out


def noise_burst(duration, vol=0.8, lowpass=1.0, release=0.6):
    n = int(SAMPLE_RATE * duration)
    out, prev = [], 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        raw = random.uniform(-1, 1)
        prev = prev + lowpass * (raw - prev)  # filtre passe-bas naïf
        out.append(prev * envelope(t, duration, release=release) * vol)
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for track in tracks:
        for i, s in enumerate(track):
            out[i] += s
    peak = max(abs(s) for s in out) or 1.0
    return [s / peak * 0.9 for s in out]


def arpeggio(notes, note_dur=0.12, vol=0.7, wave_fn=None):
    out = []
    for f in notes:
        n = int(SAMPLE_RATE * note_dur)
        phase = 0.0
        for i in range(n):
            t = i / SAMPLE_RATE
            phase += 2 * math.pi * f / SAMPLE_RATE
            s = math.sin(phase)
            if wave_fn == "square":
                s = 1.0 if s > 0 else -1.0
            out.append(s * envelope(t, note_dur, release=0.5) * vol)
    return out


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    random.seed(42)
    print("Génération des SFX placeholder :")

    # UI
    write_wav("ui_click.wav", sine_sweep(0.07, 900, 600, vol=0.5, release=0.7))
    write_wav("card_draw.wav", noise_burst(0.18, vol=0.45, lowpass=0.35, release=0.5))
    write_wav("card_place.wav", mix(
        sine_sweep(0.15, 180, 80, vol=0.9, release=0.8),
        noise_burst(0.08, vol=0.3, lowpass=0.5),
    ))

    # Flow de partie
    write_wav("wave_start.wav", mix(
        arpeggio([220, 220, 330], note_dur=0.16, wave_fn="square", vol=0.5),
        noise_burst(0.45, vol=0.15, lowpass=0.2),
    ))
    write_wav("base_hit.wav", mix(
        sine_sweep(0.4, 500, 120, vol=0.8, release=0.5),
        noise_burst(0.25, vol=0.4, lowpass=0.6),
    ))
    write_wav("victory.wav", arpeggio([392, 494, 587, 784], note_dur=0.15, vol=0.7))
    write_wav("defeat.wav", arpeggio([330, 277, 220, 165], note_dur=0.22, vol=0.7))

    # Combat
    write_wav("shot_water.wav", sine_sweep(0.12, 700, 200, vol=0.55, release=0.6))
    write_wav("shot_tesla.wav", mix(
        noise_burst(0.1, vol=0.7, lowpass=0.95, release=0.8),
        sine_sweep(0.1, 2200, 1400, vol=0.35, release=0.8),
    ))
    write_wav("shot_wind.wav", noise_burst(0.22, vol=0.4, lowpass=0.15, release=0.4))
    write_wav("shot_sniper.wav", mix(
        noise_burst(0.07, vol=0.9, lowpass=0.85, release=0.85),
        sine_sweep(0.2, 1200, 250, vol=0.4, release=0.7),
    ))
    write_wav("shot_fire.wav", mix(
        noise_burst(0.25, vol=0.55, lowpass=0.3, release=0.5),
        sine_sweep(0.2, 350, 120, vol=0.45, release=0.6),
    ))
    write_wav("enemy_death.wav", mix(
        noise_burst(0.18, vol=0.6, lowpass=0.7, release=0.7),
        sine_sweep(0.18, 300, 60, vol=0.5, release=0.7),
    ))
    write_wav("explosion.wav", mix(
        noise_burst(0.6, vol=0.9, lowpass=0.25, release=0.7),
        sine_sweep(0.5, 150, 40, vol=0.8, release=0.6),
    ))
    write_wav("lightning.wav", mix(
        noise_burst(0.3, vol=0.85, lowpass=0.9, release=0.8),
        sine_sweep(0.35, 90, 50, vol=0.5, release=0.5),
    ))

    print("Terminé.")


if __name__ == "__main__":
    main()
