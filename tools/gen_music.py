#!/usr/bin/env python3
"""Генератор плейсхолдер-музыки (зацикленный WAV) для Timokha Escape.
Запуск из корня: python3 tools/gen_music.py  ->  audio/music/theme.wav
Лёгкий плакучий арпеджио-луп; заменяем drop-in.
"""
import wave
import struct
import math
import os

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio", "music")


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    w = wave.open(path, "w")
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    data = bytearray()
    for s in samples:
        v = int(max(-1.0, min(1.0, s)) * 32767)
        data += struct.pack("<h", v)
    w.writeframes(bytes(data))
    w.close()
    print("wrote", path, len(samples), "samples", round(len(samples) / SR, 2), "s")


def pluck(freq, dur, vol=0.18, decay=5.0):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t) * vol
        # лёгкая мягкость: основная + тихая октава
        val = math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * 2 * freq * t)
        out.append(val * env)
    return out


def add(buf, samples, at):
    for i, v in enumerate(samples):
        idx = at + i
        if idx < len(buf):
            buf[idx] += v


# 8 секунд, шаг 0.5 с (16 шагов). Пентатоника C: C D E G A.
C5, D5, E5, G5, A5 = 523.25, 587.33, 659.25, 783.99, 880.0
C4, G4 = 261.63, 392.0
melody = [C5, E5, G5, E5, A5, G5, E5, D5, C5, E5, G5, A5, G5, E5, D5, C5]
bass = {0: C4, 4: G4, 8: A5 / 2, 12: G4}

total = int(SR * 8.0)
buf = [0.0] * total
step = 0.5
for i, f in enumerate(melody):
    add(buf, pluck(f, 0.55, vol=0.16, decay=5.5), int(SR * i * step))
for i, f in bass.items():
    add(buf, pluck(f, 1.4, vol=0.14, decay=2.2), int(SR * i * step))

write("theme", buf)
print("done")
