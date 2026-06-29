#!/usr/bin/env python3
"""Бесшовные тайл-текстуры земли/травы/дороги для 3D. python3 tools/gen_ground_tex.py -> art/textures/*.png
Заменяемы. Процедурный value-noise с wrap (тайлится без швов)."""
from PIL import Image
import random
import os

SIZE = 256
OUT = os.path.join(os.path.dirname(__file__), "..", "art", "textures")


def grid_noise(cells, seed):
    rnd = random.Random(seed)
    g = [[rnd.random() for _ in range(cells)] for _ in range(cells)]

    def sample(u, v):
        x = u * cells
        y = v * cells
        x0 = int(x) % cells
        y0 = int(y) % cells
        x1 = (x0 + 1) % cells
        y1 = (y0 + 1) % cells
        fx = x - int(x)
        fy = y - int(y)
        fx = fx * fx * (3 - 2 * fx)
        fy = fy * fy * (3 - 2 * fy)
        a = g[y0][x0]
        b = g[y0][x1]
        c = g[y1][x0]
        d = g[y1][x1]
        return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy
    return sample


def grad(stops, t):
    t = max(0.0, min(1.0, t))
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        if t0 <= t <= t1:
            k = (t - t0) / (t1 - t0) if t1 > t0 else 0.0
            return tuple(int(c0[j] + (c1[j] - c0[j]) * k) for j in range(3))
    return stops[-1][1]


def make(stops, fname, seed):
    os.makedirs(OUT, exist_ok=True)
    n1 = grid_noise(8, seed)
    n2 = grid_noise(16, seed + 1)
    n3 = grid_noise(48, seed + 2)
    img = Image.new("RGB", (SIZE, SIZE))
    px = img.load()
    for j in range(SIZE):
        for i in range(SIZE):
            u = i / SIZE
            v = j / SIZE
            val = n1(u, v) * 0.5 + n2(u, v) * 0.32 + n3(u, v) * 0.18
            px[i, j] = grad(stops, val)
    img.save(os.path.join(OUT, fname))
    print("wrote", fname)


# трава — оттенки зелёного с тёмными/светлыми пятнами
make([(0.0, (40, 58, 30)), (0.45, (64, 92, 44)), (0.75, (88, 116, 56)), (1.0, (112, 140, 72))], "grass.png", 11)
# грунт/дорога — оттенки коричневого
make([(0.0, (54, 40, 28)), (0.5, (82, 62, 42)), (1.0, (112, 90, 64))], "dirt.png", 31)
print("done")
