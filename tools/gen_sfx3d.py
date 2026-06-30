#!/usr/bin/env python3
"""Плейсхолдер-звуки для 3D-режима. python3 tools/gen_sfx3d.py -> audio/sfx3d/*.wav
Заменяемы. Только геймплейная обратная связь, без эстетики."""
import wave
import struct
import math
import os
import random

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx3d")
random.seed(7)


def write(name, s):
    os.makedirs(OUT, exist_ok=True)
    w = wave.open(os.path.join(OUT, name + ".wav"), "w")
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    d = bytearray()
    for x in s:
        d += struct.pack("<h", int(max(-1, min(1, x)) * 32767))
    w.writeframes(bytes(d))
    w.close()
    print("wrote", name, round(len(s) / SR, 2), "s")


def tone(f, dur, vol=0.5, decay=6.0):
    n = int(SR * dur)
    return [math.sin(2 * math.pi * f * (i / SR)) * math.exp(-decay * (i / SR)) * vol for i in range(n)]


def sweep(f0, f1, dur, vol=0.5, decay=4.0):
    n = int(SR * dur)
    o = []
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (t / dur)
        o.append(math.sin(2 * math.pi * f * t) * math.exp(-decay * t) * vol)
    return o


def sil(d):
    return [0.0] * int(SR * d)


def seq(*xs):
    o = []
    for x in xs:
        o += x
    return o


def wrap_xfade(o, n, f):
    """Бесшовный луп БЕЗ провала в тишину: o длиной n+f, голову смешиваем с продолжением хвоста (n..n+f),
    возвращаем n сэмплов. На стыке сигнал непрерывен → нет паузы/пульсации."""
    for i in range(f):
        k = i / f
        o[i] = o[i] * k + o[n + i] * (1.0 - k)
    return o[:n]


def rain(dur, vol=0.12):
    n = int(SR * dur)
    f = int(SR * 0.3)
    o = []
    p1 = 0.0
    p2 = 0.0
    for i in range(n + f):
        nz = random.uniform(-1, 1)
        p1 = p1 * 0.86 + nz * 0.14       # двойной низкочастотный фильтр →
        p2 = p2 * 0.90 + p1 * 0.10       # мягкое шуршание вместо широкополосной «статики»
        o.append(p2 * vol)
    return wrap_xfade(o, n, f)


def step(vol=0.30):
    n = int(SR * 0.13)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / SR
        env = math.exp(-28 * t) * vol
        prev = prev * 0.5 + random.uniform(-1, 1) * 0.5
        out.append((math.sin(2 * math.pi * 110 * t) * 0.6 + prev * 0.5) * env)
    return out


# шаги (две вариации — разный шум)
write("step1", step())
write("step2", step())
def wind(dur, vol=0.08):
    n = int(SR * dur)
    f = int(SR * 0.4)
    out = []
    prev = 0.0
    for i in range(n + f):
        t = i / SR
        prev = prev * 0.85 + random.uniform(-1, 1) * 0.15   # сильнее сглажен → ниже, мягче
        lfo = 0.55 + 0.45 * math.sin(2 * math.pi * 0.13 * t)  # медленные порывы
        out.append(prev * vol * lfo)
    return wrap_xfade(out, n, f)


# дождь-луп (длинный бесшовный, мягкое шуршание)
write("rain", rain(12.0, 0.6))
# ветер-эмбиент (длинный бесшовный)
write("wind", wind(15.0, 0.08))
# сердцебиение (lub-dub)
write("heartbeat", seq(tone(78, 0.12, 0.55, 16), sil(0.10), tone(62, 0.16, 0.45, 13)))
# выполнил дело
write("ding", seq(tone(660, 0.12, 0.45, 9), tone(990, 0.18, 0.45, 7)))
# поймали (комичный нисходящий)
write("caught", sweep(520, 170, 0.30, 0.55, 4.5))
# побег
write("win", seq(tone(523, 0.12, 0.4, 8), tone(659, 0.12, 0.4, 8), tone(784, 0.12, 0.4, 8), tone(1046, 0.3, 0.45, 5)))
# стингер появления Тимохи ночью (резкий нисходящий)
write("stinger", sweep(740, 190, 0.40, 0.6, 5.0))


def laugh(vol=0.5):
    """Комичный смех Тимохи при поимке: серия коротких «ха-ха» с вибрато, общий нисходящий тон."""
    out = []
    base = 440
    for k in range(5):
        f = base - k * 24
        dur = 0.11
        n = int(SR * dur)
        for i in range(n):
            t = i / SR
            vib = 1.0 + 0.06 * math.sin(2 * math.pi * 34 * t)   # вибрато → дребезжащий смешок
            env = math.sin(math.pi * (i / n)) * vol             # купол громкости на каждый слог
            out.append(math.sin(2 * math.pi * f * vib * t) * env)
        out += [0.0] * int(SR * 0.05)                            # пауза между слогами
    return out


# смех Тимохи при поимке (комичное «ха-ха-ха»)
write("laugh", laugh(0.5))


def crickets(dur, vol=0.05):
    """Ночной эмбиент: несколько «сверчков» — высокий тон с резким тремоло (чирпы). Бесшовный луп (wrap)."""
    n = int(SR * dur)
    fl = int(SR * 0.3)
    o = [0.0] * (n + fl)
    voices = []
    for _c in range(6):
        voices.append((random.uniform(3600, 5200), random.uniform(9, 15), random.uniform(0, 6.28)))
    for i in range(n + fl):
        t = i / SR
        s = 0.0
        for f, rate, ph in voices:
            trem = max(0.0, math.sin(2 * math.pi * rate * t + ph))
            trem = trem * trem * trem * trem   # резкие чирпы
            s += math.sin(2 * math.pi * f * t) * trem
        o[i] = s * vol
    return wrap_xfade(o, n, fl)


# ночной эмбиент сверчков (длинный бесшовный луп)
write("crickets", crickets(13.0, 0.05))


def owl(vol=0.4):
    """Уханье совы: мягкое низкое «ху… ху-у»."""
    def note(f, dur, v):
        n = int(SR * dur)
        out = []
        for i in range(n):
            t = i / SR
            env = math.sin(math.pi * min(1.0, t / dur))      # купол громкости
            vib = 1.0 + 0.02 * math.sin(2 * math.pi * 6 * t)  # лёгкое вибрато
            out.append(math.sin(2 * math.pi * f * vib * t) * env * v)
        return out
    return seq(note(320, 0.18, vol), sil(0.07), note(258, 0.36, vol * 0.9))


# уханье совы (ночной одиночный звук)
write("owl", owl(0.4))


def thunder(dur=1.8, vol=0.6):
    """Раскат грома: низкочастотный рокот с резким началом и длинным затуханием."""
    n = int(SR * dur)
    o = []
    prev = 0.0
    for i in range(n):
        t = i / SR
        prev = prev * 0.92 + random.uniform(-1, 1) * 0.08   # сглаженный шум → низкий рокот
        env = math.exp(-2.5 * t) * 0.6 + math.exp(-0.8 * t) * 0.7   # «кряк» + раскат
        rumble = 1.0 + 0.3 * math.sin(2 * math.pi * 7 * t)
        o.append(prev * env * rumble * vol)
    return o


# раскат грома (редкий, в дождь)
write("thunder", thunder(1.8, 0.6))


def dread(dur=10.0, vol=0.5):
    """Зловещий низкий дрон (слендер-саспенс): низкие тоны + диссонанс-биение + рокот. Бесшовный луп."""
    n = int(SR * dur)
    f = int(SR * 0.4)
    o = []
    prev = 0.0
    for i in range(n + f):
        t = i / SR
        s = math.sin(2 * math.pi * 55.0 * t) * 0.5       # низкий тон
        s += math.sin(2 * math.pi * 82.5 * t) * 0.28     # квинта
        s += math.sin(2 * math.pi * 58.3 * t) * 0.18     # лёгкое биение/диссонанс
        prev = prev * 0.7 + random.uniform(-1, 1) * 0.3
        s += prev * 0.22                                  # низкий рокот
        lfo = 0.7 + 0.3 * math.sin(2 * math.pi * 0.2 * t)  # медленное «дыхание»
        o.append(s * lfo * vol)
    return wrap_xfade(o, n, f)


# нарастающий саспенс-дрон (громкость рулится из игры по близости Мишганчика и прогрессу)
write("dread", dread(10.0, 0.5))


def boom(dur=1.1, vol=0.95):
    """Мемный «вайн-бум»: резкий низкий удар с быстрым падением частоты в саб + сатурация. Звук джампскейра."""
    n = int(SR * dur)
    o = []
    for i in range(n):
        t = i / SR
        f = 130.0 * math.exp(-3.2 * t) + 37.0          # частота быстро падает в саб-бас
        s = math.sin(2 * math.pi * f * t)
        s += 0.45 * math.sin(2 * math.pi * f * 0.5 * t)  # суб-октава
        s = math.tanh(s * 1.7)                           # мягкая сатурация → «бум»
        env = math.exp(-3.0 * t) * (1.0 - math.exp(-120.0 * t))  # резкая атака, быстрый спад
        o.append(s * env * vol)
    return o


# мемный «бум» на джампскейрах
write("boom", boom(1.1, 0.95))


def honk(dur=0.55, vol=0.6):
    """Дурацкий гудок-honk (мемно): квадрат-волна с падающей частотой. Когда Мишганчик заметил игрока."""
    n = int(SR * dur)
    o = []
    for i in range(n):
        t = i / SR
        f = 420.0 * math.exp(-1.6 * t) + 170.0
        sq = 1.0 if math.sin(2 * math.pi * f * t) > 0 else -1.0   # квадрат = «honky»
        env = math.exp(-2.6 * t) * (1.0 - math.exp(-90.0 * t))
        o.append(sq * env * vol * 0.5)
    return o


# дурацкий гудок «заметил тебя»
write("honk", honk(0.55, 0.6))
print("done")
