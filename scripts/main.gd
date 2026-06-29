extends Node2D
## Main — менеджер экранов: MENU / CHAPTER_SELECT / GAME / RESULTS.
## Меню — Control/Button на CanvasLayer; геймплей — узел World (_draw).

const WORLD_SCRIPT := preload("res://scripts/core/world.gd")

var ui: CanvasLayer
var screen_root: Control
var pause_root: Control = null
var world: Node2D = null
var current_idx: int = 0

func _ready() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	Music.play("theme")
	# Отладочный авто-старт для headless-проверки: `Godot --headless --path . -- --autostart`
	if "--autostart" in OS.get_cmdline_args() or "--autostart" in OS.get_cmdline_user_args():
		start_game(0)
	else:
		show_menu()

# ───────────────── каркас экранов ─────────────────
func _clear_screen() -> void:
	_clear_pause()
	if world != null:
		world.queue_free()
		world = null
	if screen_root != null:
		screen_root.queue_free()
		screen_root = null

func _new_screen() -> Control:
	_clear_screen()
	screen_root = Control.new()
	screen_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(screen_root)
	var bg := ColorRect.new()
	bg.color = Color(0.86, 0.80, 0.66)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_root.add_child(bg)
	return screen_root

func _label(parent: Control, text: String, pos: Vector2, size: int, col: Color = Color(0.2, 0.15, 0.1)) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

func _button(parent: Control, text: String, pos: Vector2, size_px: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = size_px
	b.size = size_px
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _sprite(parent: Control, key: String, pos: Vector2, size: float) -> void:
	var t: Texture2D = Art.tex(key)
	if t == null:
		return
	var tr := TextureRect.new()
	tr.texture = t
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = pos
	tr.size = Vector2(size, size)
	tr.custom_minimum_size = Vector2(size, size)
	parent.add_child(tr)

func _stars_row(parent: Control, pos: Vector2, filled: int, total: int = 3, size: float = 44.0) -> void:
	for i in total:
		var tr := TextureRect.new()
		tr.texture = Art.tex("star" if i < filled else "star_empty")
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.position = pos + Vector2(float(i) * (size + 8.0), 0.0)
		tr.custom_minimum_size = Vector2(size, size)
		tr.size = Vector2(size, size)
		parent.add_child(tr)

# ───────────────── MENU ─────────────────
func show_menu() -> void:
	var root := _new_screen()
	_label(root, "TIMOKHA ESCAPE", Vector2(360, 130), 64, Color(0.5, 0.25, 0.1))
	_label(root, "Побег от шалуна: беги, делай дела, удирай!", Vector2(360, 215), 26)
	_button(root, "ИГРАТЬ", Vector2(530, 300), Vector2(230, 84), show_chapter_select)
	_button(root, "Настройки", Vector2(530, 404), Vector2(230, 60), show_settings)
	_label(root, "Всего звёзд: %d" % GS.total_stars(), Vector2(560, 486), 22)
	# титульная сценка: шалун гонится за игроком
	_sprite(root, "timokha", Vector2(470, 548), 110.0)
	_sprite(root, "player", Vector2(640, 552), 104.0)

# ───────────────── SETTINGS ─────────────────
func show_settings() -> void:
	var root := _new_screen()
	_label(root, "Настройки", Vector2(360, 90), 44, Color(0.4, 0.25, 0.1))
	_button(root, "Музыка: %s" % ("ВКЛ" if GS.music_on else "ВЫКЛ"), Vector2(430, 220), Vector2(420, 66), _toggle_music)
	_button(root, "Звук: %s" % ("ВКЛ" if GS.sfx_on else "ВЫКЛ"), Vector2(430, 302), Vector2(420, 66), _toggle_sfx)
	_button(root, "Сбросить прогресс", Vector2(430, 400), Vector2(420, 60), _reset_in_settings)
	_button(root, "Назад", Vector2(430, 490), Vector2(200, 60), show_menu)

func _toggle_music() -> void:
	GS.set_music(not GS.music_on)
	show_settings()

func _toggle_sfx() -> void:
	GS.set_sfx(not GS.sfx_on)
	show_settings()

func _reset_in_settings() -> void:
	GS.reset_progress()
	show_settings()

# ───────────────── CHAPTER SELECT ─────────────────
func show_chapter_select() -> void:
	var root := _new_screen()
	_label(root, "Выбери главу", Vector2(360, 80), 44, Color(0.4, 0.25, 0.1))
	_label(root, "Звёзд: %d" % GS.total_stars(), Vector2(900, 100), 24)
	var y := 190.0
	for i in GameData.chapter_count():
		var ch: Dictionary = GameData.get_chapter(i)
		var cid: String = str(ch.get("id", ""))
		var unlocked: bool = GS.is_unlocked(i)
		var text: String
		if unlocked:
			text = "%s" % ch.get("name", "")
		else:
			text = "%s   [ЗАКРЫТО]" % ch.get("name", "")
		var b := _button(root, text, Vector2(300, y), Vector2(560, 72), start_game.bind(i))
		b.disabled = not unlocked
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if unlocked:
			_stars_row(root, Vector2(876, y + 18.0), GS.best_for(cid), 3, 36)
		y += 92.0
	_button(root, "Назад", Vector2(360, y + 10.0), Vector2(200, 60), show_menu)

# ───────────────── GAME ─────────────────
func start_game(idx: int) -> void:
	current_idx = idx
	_clear_screen()
	world = WORLD_SCRIPT.new()
	add_child(world)
	world.finished.connect(_on_world_finished)
	world.quit_to_menu.connect(show_chapter_select)
	world.pause_requested.connect(_show_pause)
	world.setup(GameData.get_chapter(idx))

# ───────────────── PAUSE ─────────────────
func _show_pause() -> void:
	if pause_root != null:
		return
	pause_root = Control.new()
	pause_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(pause_root)
	_button(pause_root, "Продолжить", Vector2(530, 300), Vector2(220, 66), _resume)
	_button(pause_root, "Заново", Vector2(530, 382), Vector2(220, 66), _restart_chapter)
	_button(pause_root, "В меню глав", Vector2(530, 464), Vector2(220, 66), _pause_to_menu)

func _clear_pause() -> void:
	if pause_root != null:
		pause_root.queue_free()
		pause_root = null

func _resume() -> void:
	_clear_pause()
	if world != null:
		world.set_paused(false)

func _restart_chapter() -> void:
	start_game(current_idx)

func _pause_to_menu() -> void:
	show_chapter_select()

func _on_world_finished(stars: int) -> void:
	GS.record_chapter(current_idx, stars)
	await get_tree().create_timer(1.2).timeout
	show_results(current_idx, stars)

# ───────────────── RESULTS ─────────────────
func show_results(idx: int, stars: int) -> void:
	var root := _new_screen()
	var ch: Dictionary = GameData.get_chapter(idx)
	_label(root, "Глава пройдена!", Vector2(420, 120), 48, Color(0.15, 0.45, 0.2))
	_label(root, str(ch.get("name", "")), Vector2(420, 190), 28)
	_stars_row(root, Vector2(430, 244), stars, 3, 58)
	_label(root, "Лучший результат: %d / 3" % GS.best_for(str(ch.get("id", ""))), Vector2(420, 322), 22)
	_button(root, "Ещё раз", Vector2(420, 364), Vector2(240, 66), start_game.bind(idx))
	var nxt := idx + 1
	if nxt < GameData.chapter_count() and GS.is_unlocked(nxt):
		_button(root, "Следующая глава", Vector2(420, 444), Vector2(300, 66), start_game.bind(nxt))
		_button(root, "В меню", Vector2(420, 524), Vector2(240, 60), show_menu)
	else:
		_button(root, "В меню", Vector2(420, 444), Vector2(240, 60), show_menu)
