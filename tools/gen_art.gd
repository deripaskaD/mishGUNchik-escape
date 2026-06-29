extends SceneTree
## Генератор плейсхолдер-спрайтов: персонажи, выход, иконки задач.
## Запуск: godot --headless --script res://tools/gen_art.gd
## Пишет PNG в res://art/. Это плейсхолдеры — заменяй своими по тем же ключам.

const S := 128
const C := 64

func _initialize() -> void:
	_make_player()
	_make_timokha()
	_make_exit()
	_make_icon_pies()
	_make_icon_tea()
	_make_icon_wood()
	_make_icon_feed()
	_make_star("star", Color(1.0, 0.84, 0.25), Color(0.55, 0.40, 0.05))
	_make_star("star_empty", Color(0.74, 0.72, 0.66), Color(0.45, 0.42, 0.38))
	_make_app_icon()
	print("art generated: player, timokha, exit, icon_pies/tea/wood, star, star_empty, app icon")
	quit()

func _img() -> Image:
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

func _disc(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x < 0 or y < 0 or x >= S or y >= S:
				continue
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= r * r:
				img.set_pixel(x, y, col)

func _ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			if x < 0 or y < 0 or x >= S or y >= S:
				continue
			var nx := float(x - cx) / float(rx)
			var ny := float(y - cy) / float(ry)
			if nx * nx + ny * ny <= 1.0:
				img.set_pixel(x, y, col)

func _frect(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if x < 0 or y < 0 or x >= S or y >= S:
				continue
			img.set_pixel(x, y, col)

func _smile(img: Image, cx: int, cy: int, r: int, th: int, col: Color) -> void:
	for y in range(cy, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x < 0 or y < 0 or x >= S or y >= S:
				continue
			var dx := float(x - cx)
			var dy := float(y - cy)
			var d := sqrt(dx * dx + dy * dy)
			if dy > 0 and d <= r and d >= r - th:
				img.set_pixel(x, y, col)

func _eyes(img: Image, oy: int, pupil: Color) -> void:
	_disc(img, C - 18, C + oy, 12, Color(1, 1, 1))
	_disc(img, C + 18, C + oy, 12, Color(1, 1, 1))
	_disc(img, C - 15, C + oy + 2, 5, pupil)
	_disc(img, C + 21, C + oy + 2, 5, pupil)

func _make_player() -> void:
	var img := _img()
	_disc(img, C, C, 56, Color(0.16, 0.28, 0.15))
	_disc(img, C, C, 52, Color(0.30, 0.66, 0.35))
	_eyes(img, -8, Color(0.1, 0.1, 0.1))
	_smile(img, C, C + 6, 20, 5, Color(0.12, 0.22, 0.12))
	img.save_png("res://art/player.png")

func _make_timokha() -> void:
	var img := _img()
	var cap := Color(0.55, 0.14, 0.12)
	_disc(img, C, C, 58, Color(0.32, 0.10, 0.08))
	_disc(img, C, C, 54, Color(0.86, 0.27, 0.22))
	for y in range(C - 54, C - 12):
		for x in range(C - 54, C + 54):
			var dx := x - C
			var dy := y - C
			if dx * dx + dy * dy <= 54 * 54:
				img.set_pixel(x, y, cap)
	_disc(img, C + 6, C - 52, 7, cap)
	_eyes(img, -2, Color(0.1, 0.05, 0.05))
	_smile(img, C, C + 8, 24, 6, Color(0.30, 0.06, 0.05))
	img.save_png("res://art/timokha.png")

func _make_exit() -> void:
	var img := _img()
	_frect(img, C - 24, C - 38, C + 24, C + 46, Color(0.28, 0.16, 0.09))   # рама
	_frect(img, C - 19, C - 33, C + 19, C + 46, Color(0.52, 0.34, 0.18))   # дверь
	_frect(img, C - 12, C - 26, C + 12, C + 4, Color(0.42, 0.26, 0.13))    # верхняя филёнка
	_frect(img, C - 12, C + 12, C + 12, C + 40, Color(0.42, 0.26, 0.13))   # нижняя филёнка
	_disc(img, C + 12, C + 8, 4, Color(0.95, 0.82, 0.30))                  # ручка
	img.save_png("res://art/exit.png")

func _make_icon_pies() -> void:
	var img := _img()
	_ellipse(img, C, C + 6, 46, 32, Color(0.30, 0.20, 0.10))
	_ellipse(img, C, C + 6, 42, 28, Color(0.85, 0.68, 0.40))
	_disc(img, C - 14, C + 2, 3, Color(0.55, 0.38, 0.18))
	_disc(img, C + 12, C + 10, 3, Color(0.55, 0.38, 0.18))
	_disc(img, C + 2, C - 2, 3, Color(0.55, 0.38, 0.18))
	img.save_png("res://art/icon_pies.png")

func _make_icon_tea() -> void:
	var img := _img()
	_disc(img, C + 34, C + 6, 13, Color(0.85, 0.85, 0.82))   # ручка
	_disc(img, C + 34, C + 6, 6, Color(0.30, 0.22, 0.16))
	_disc(img, C, C + 6, 36, Color(0.30, 0.22, 0.16))         # обводка чашки
	_disc(img, C, C + 6, 32, Color(0.95, 0.95, 0.92))         # чашка
	_ellipse(img, C, C - 12, 24, 8, Color(0.45, 0.25, 0.10))  # чай
	img.save_png("res://art/icon_tea.png")

func _make_icon_wood() -> void:
	var img := _img()
	_ellipse(img, C, C + 4, 46, 26, Color(0.30, 0.18, 0.08))
	_ellipse(img, C, C + 4, 42, 22, Color(0.58, 0.38, 0.20))
	_ellipse(img, C, C + 4, 28, 15, Color(0.66, 0.46, 0.26))
	_ellipse(img, C, C + 4, 14, 8, Color(0.72, 0.52, 0.30))
	img.save_png("res://art/icon_wood.png")

func _make_icon_feed() -> void:
	var img := _img()
	_ellipse(img, C, C, 46, 20, Color(0.20, 0.35, 0.12))   # обводка
	_ellipse(img, C, C, 42, 16, Color(0.42, 0.62, 0.24))   # огурец
	_disc(img, C - 18, C - 4, 2, Color(0.30, 0.48, 0.16))
	_disc(img, C - 4, C + 3, 2, Color(0.30, 0.48, 0.16))
	_disc(img, C + 12, C - 3, 2, Color(0.30, 0.48, 0.16))
	_disc(img, C + 22, C + 4, 2, Color(0.30, 0.48, 0.16))
	img.save_png("res://art/icon_feed.png")

func _star_verts(cx: float, cy: float, ro: float, ri: float) -> Array:
	var v := []
	for i in 10:
		var ang := -PI / 2.0 + float(i) * PI / 5.0
		var r := ro if i % 2 == 0 else ri
		v.append(Vector2(cx + cos(ang) * r, cy + sin(ang) * r))
	return v

func _pt_in_poly(px: float, py: float, verts: Array) -> bool:
	var inside := false
	var n := verts.size()
	var j := n - 1
	for i in n:
		var vi: Vector2 = verts[i]
		var vj: Vector2 = verts[j]
		if (vi.y > py) != (vj.y > py) and px < (vj.x - vi.x) * (py - vi.y) / (vj.y - vi.y) + vi.x:
			inside = not inside
		j = i
	return inside

func _poly_fill(img: Image, verts: Array, col: Color) -> void:
	for y in range(0, S):
		for x in range(0, S):
			if _pt_in_poly(float(x) + 0.5, float(y) + 0.5, verts):
				img.set_pixel(x, y, col)

func _make_star(name: String, fill: Color, outline: Color) -> void:
	var img := _img()
	_poly_fill(img, _star_verts(C, C, 58, 25), outline)
	_poly_fill(img, _star_verts(C, C, 52, 22), fill)
	img.save_png("res://art/" + name + ".png")

func _make_app_icon() -> void:
	# Иконка приложения: лицо шалуна на тёплом фоне (непрозрачный квадрат).
	var img := Image.create_empty(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.86, 0.55))
	var cap := Color(0.55, 0.14, 0.12)
	_disc(img, C, C, 50, Color(0.32, 0.10, 0.08))
	_disc(img, C, C, 46, Color(0.86, 0.27, 0.22))
	for y in range(C - 46, C - 10):
		for x in range(C - 46, C + 46):
			var dx := x - C
			var dy := y - C
			if dx * dx + dy * dy <= 46 * 46:
				img.set_pixel(x, y, cap)
	_disc(img, C + 5, C - 44, 6, cap)
	_eyes(img, -2, Color(0.1, 0.05, 0.05))
	_smile(img, C, C + 6, 20, 5, Color(0.30, 0.06, 0.05))
	img.save_png("res://icon.png")
