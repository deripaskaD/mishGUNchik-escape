#!/usr/bin/env python3
"""Генератор плейсхолдер-SFX (WAV) для Timokha Escape.
Запуск из корня проекта: python3 tools/gen_sfx.py
Создаёт короткие звуки в audio/sfx/. Это плейсхолдеры — заменяемы drop-in.
"""
import wave
import struct
import math
import os

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")


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
    print("wrote", path, len(samples), "samples")


def tone(freq, dur, vol=0.5, decay=6.0, shape="sine", vibrato=0.0):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t) * vol
        f = freq * (1.0 + vibrato * math.sin(2 * math.pi * 7 * t))
        ph = 2 * math.pi * f * t
        if shape == "square":
            val = 1.0 if math.sin(ph) >= 0 else -1.0
        elif shape == "saw":
            val = 2.0 * ((f * t) % 1.0) - 1.0
        else:
            val = math.sin(ph)
        out.append(val * env)
    return out


def sweep(f0, f1, dur, vol=0.5, decay=4.0):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (t / dur)
        env = math.exp(-decay * t) * vol
        out.append(math.sin(2 * math.pi * f * t) * env)
    return out


def mix(*tracks):
    m = max(len(t) for t in tracks)
    out = [0.0] * m
    for tr in tracks:
        for i, v in enumerate(tr):
            out[i] += v
    return out


def seq(*tracks):
    out = []
    for tr in tracks:
        out += tr
    return out


# tap — короткий клик
write("tap", tone(880, 0.06, vol=0.4, decay=22, shape="square"))
# task_start — восходящий блип
write("task_start", sweep(500, 900, 0.12, vol=0.4, decay=8))
# task_done — две весёлые ноты
write("task_done", seq(tone(660, 0.12, vol=0.45, decay=9), tone(990, 0.18, vol=0.45, decay=7)))
# caught — комичный нисходящий "ой" с вибрато
write("caught", sweep(520, 200, 0.22, vol=0.5, decay=5))
# exit_open — аккордик
write("exit_open", mix(tone(392, 0.3, vol=0.3, decay=4), tone(587, 0.3, vol=0.3, decay=4)))
# win — арпеджио C-E-G-C
write("win", seq(
    tone(523, 0.12, vol=0.4, decay=8),
    tone(659, 0.12, vol=0.4, decay=8),
    tone(784, 0.12, vol=0.4, decay=8),
    tone(1046, 0.28, vol=0.45, decay=5),
))
print("done")
