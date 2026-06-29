extends Node2D
## World — геймплей одной главы: движение под погоней, мини-игры у зон, побег.
## Читает данные/тюнинг, владеет симуляцией и отрисовкой (ADR-0001/0002).

signal finished(stars: int)
signal quit_to_menu
signal pause_requested

enum { STATE_TASK, STATE_ESCAPE, STATE_WON }

const MG_SCRIPTS := {
	"pies": preload("res://scripts/core/minigames/mg_pies.gd"),
	"tea": preload("res://scripts/core/minigames/mg_tea.gd"),
	"wood": preload("res://scripts/core/minigames/mg_wood.gd"),
	"feed": preload("res://scripts/core/minigames/mg_feed.gd"),
}

var _pursuer_script := preload("res://scripts/core/pursuer.gd")
var _quest_script := preload("res://scripts/core/quest_manager.gd")

const DONE_QUIPS := ["Готово!", "Вот это да!", "Ловко!", "Ещё одно дело!"]
const CAUGHT_QUIPS := ["Ой!", "Поймал, шкода!", "Куда?!", "Ах ты!"]

var _active := false
var _paused := false
var state := STATE_TASK
var _emitted := false

var chapter: Dictionary = {}
var player: Vector2 = Vector2(180, 360)
var chapter_exit: Vector2 = Vector2(1180, 120)
var pursuer                  # Pursuer (RefCounted)
var quest                    # QuestManager (RefCounted)
var active_mg                # MinigameBase or null

# тюнинг (кэш)
var player_speed := 320.0
var player_r := 26.0
var pursuer_r := 30.0
var hotspot_r := 92.0
var exit_r := 64.0
var margin := 40.0
var stun_time := 0.7
var knockback := 140.0
var bounds := Vector2(1280, 720)   # игровое поле; обновляется из вьюпорта, если в дереве

# рантайм-метрики/эффекты
var catches := 0
var elapsed := 0.0
var stun := 0.0
var flash_bad := 0.0
var flash_good := 0.0
var quip := ""
var quip_t := 0.0
var intro_t := 0.0
var _anim := 0.0
var _moving := 0.0

# ввод
var stick_active := false
var stick_origin := Vector2.ZERO
var stick_cur := Vector2.ZERO
var press_button := ""

var _font: Font

func _ready() -> void:
	_font = ThemeDB.fallback_font

func setup(ch: Dictionary) -> void:
	chapter = ch
	var t: Dictionary = GameData.tuning_for(ch)
	player_speed = float(t["player_speed"])
	player_r = float(t["player_r"])
	pursuer_r = float(t["pursuer_r"])
	hotspot_r = float(t["hotspot_r"])
	exit_r = float(t["exit_r"])
	margin = float(t["margin"])
	stun_time = float(t["stun_time"])
	knockback = float(t["knockback"])

	player = ch.get("player_start", Vector2(180, 360))
	chapter_exit = ch.get("exit", Vector2(1180, 120))

	pursuer = _pursuer_script.new()
	pursuer.configure(t)
	pursuer.pos = Vector2(1080, player.y)

	quest = _quest_script.new()
	quest.setup(ch.get("tasks", []))

	active_mg = null
	state = STATE_TASK
	_emitted = false
	catches = 0
	elapsed = 0.0
	stun = 0.0
	flash_bad = 0.0
	flash_good = 0.0
	intro_t = 4.0 if str(ch.get("id", "")) == "kitchen" else 0.0
	_anim = 0.0
	_moving = 0.0
	stick_active = false
	press_button = ""

	_refresh_bounds()
	Music.play("theme")
	_active = true
	queue_redraw()

func _refresh_bounds() -> void:
	if is_inside_tree():
		var vp := get_viewport_rect().size
		if vp.x > 1.0 and vp.y > 1.0:
			bounds = vp

# ───────────────────────── ввод ─────────────────────────
func set_paused(p: bool) -> void:
	_paused = p
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not _active or _paused:
		return
	if event is InputEventMouseButton:
		if event.pressed:
			_on_press(event.position)
		else:
			_on_release()
	elif event is InputEventMouseMotion:
		if stick_active:
			stick_cur = event.position
	elif event is InputEventKey and not event.echo:
		_on_key(event)

func _on_key(event: InputEventKey) -> void:
	var k := event.keycode
	if event.pressed and k == KEY_ESCAPE:
		set_paused(true)
		pause_requested.emit()
		return
	if active_mg == null:
		return
	var ctrls: Array = active_mg.controls()
	if k == KEY_SPACE:
		if ctrls.has("tap") and event.pressed:
			active_mg.input_tap()
			Sfx.play("tap")
		elif ctrls.has("hold"):
			active_mg.input_press(event.pressed)
	elif event.pressed and ctrls.has("L") and (k == KEY_Z or k == KEY_A):
		active_mg.input_dir(-1)
		Sfx.play("tap")
	elif event.pressed and ctrls.has("R") and (k == KEY_X or k == KEY_D):
		active_mg.input_dir(1)
		Sfx.play("tap")

func _on_press(pos: Vector2) -> void:
	if active_mg != null:
		for b in _buttons():
			if b["rect"].has_point(pos):
				press_button = b["action"]
				_route_button(b["action"], true)
				return
	stick_active = true
	stick_origin = pos
	stick_cur = pos

func _on_release() -> void:
	if press_button != "":
		_route_button(press_button, false)
		press_button = ""
		return
	stick_active = false

func _route_button(action: String, down: bool) -> void:
	if active_mg == null:
		return
	match action:
		"tap":
			if down:
				active_mg.input_tap()
				Sfx.play("tap")
		"hold":
			active_mg.input_press(down)
		"L":
			if down:
				active_mg.input_dir(-1)
				Sfx.play("tap")
		"R":
			if down:
				active_mg.input_dir(1)
				Sfx.play("tap")

func _buttons() -> Array:
	# контекстные экранные кнопки под текущую мини-игру
	if active_mg == null:
		return []
	var s := bounds
	var ctrls: Array = active_mg.controls()
	if ctrls.has("L") and ctrls.has("R"):
		return [
			{"action": "L", "rect": Rect2(s.x - 390, s.y - 190, 160, 140), "label": "←"},
			{"action": "R", "rect": Rect2(s.x - 200, s.y - 190, 160, 140), "label": "→"},
		]
	if ctrls.has("hold"):
		return [{"action": "hold", "rect": Rect2(s.x - 230, s.y - 200, 180, 150), "label": "ДЕРЖИ"}]
	return [{"action": "tap", "rect": Rect2(s.x - 230, s.y - 200, 180, 150), "label": "ТАП"}]

# ───────────────────────── симуляция ─────────────────────────
func _process(delta: float) -> void:
	if not _active or _paused:
		return
	_refresh_bounds()
	if state != STATE_WON:
		elapsed += delta
	stun = maxf(0.0, stun - delta)
	flash_bad = maxf(0.0, flash_bad - delta * 2.5)
	flash_good = maxf(0.0, flash_good - delta * 2.5)
	quip_t = maxf(0.0, quip_t - delta)
	intro_t = maxf(0.0, intro_t - delta)
	_anim += delta

	_update_player(delta)
	_update_minigame(delta)
	_update_pursuer(delta)
	_check_catch()
	_check_goal()
	queue_redraw()

func _move_vector() -> Vector2:
	var kb := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if kb.length() > 0.05:
		return kb.limit_length(1.0)
	if stick_active:
		var d := stick_cur - stick_origin
		if d.length() > 14.0:
			return (d / 90.0).limit_length(1.0)
	return Vector2.ZERO

func _update_player(delta: float) -> void:
	if stun > 0.0 or state == STATE_WON:
		_moving = 0.0
		return
	var mv := _move_vector()
	_moving = mv.length()
	player += mv * player_speed * delta
	player = _clamp(player, player_r)

func _current_hotspot() -> Vector2:
	var t: Dictionary = quest.current()
	if t.is_empty():
		return Vector2(-9999, -9999)
	return t.get("pos", Vector2(-9999, -9999))

func _engaged() -> bool:
	return active_mg != null and player.distance_to(_current_hotspot()) <= hotspot_r

func _update_minigame(delta: float) -> void:
	if state != STATE_TASK:
		return
	# авто-старт у зоны
	if active_mg == null and quest.has_current():
		if player.distance_to(_current_hotspot()) <= hotspot_r:
			var type: String = quest.current().get("type", "pies")
			var scr: Variant = MG_SCRIPTS.get(type, null)
			if scr != null:
				active_mg = scr.new()
				active_mg.setup(quest.current().get("cfg", {}))
				Sfx.play("task_start")
	# обновление и завершение
	if active_mg != null:
		active_mg.update(delta)
		if active_mg.is_done():
			var st: int = active_mg.stars()
			var tid: String = quest.current().get("id", "")
			quest.complete_current(st)
			GS.task_completed.emit(tid, st)
			Sfx.play("task_done")
			flash_good = 1.0
			_say(DONE_QUIPS)
			active_mg = null
			if quest.all_done():
				state = STATE_ESCAPE
				Sfx.play("exit_open")

func _update_pursuer(delta: float) -> void:
	pursuer.update(delta, player, _engaged(), state == STATE_WON)
	pursuer.pos = _clamp(pursuer.pos, pursuer_r)

func _check_catch() -> void:
	if state == STATE_WON or stun > 0.0:
		return
	if pursuer.pos.distance_to(player) <= player_r + pursuer_r:
		catches += 1
		stun = stun_time
		flash_bad = 1.0
		var away: Vector2 = player - pursuer.pos
		if away.length() < 1.0:
			away = Vector2.RIGHT
		away = away.normalized()
		player += away * knockback
		pursuer.pos -= away * (knockback * 0.6)
		player = _clamp(player, player_r)
		pursuer.pos = _clamp(pursuer.pos, pursuer_r)
		pursuer.on_catch()
		if active_mg != null:
			active_mg.reset()
		GS.caught.emit()
		Sfx.play("caught")
		_say(CAUGHT_QUIPS)

func _check_goal() -> void:
	if state == STATE_ESCAPE:
		if player.distance_to(chapter_exit) <= exit_r + player_r:
			state = STATE_WON
			Sfx.play("win")
			if not _emitted:
				_emitted = true
				finished.emit(quest.chapter_stars())

func _clamp(p: Vector2, r: float) -> Vector2:
	var s := bounds
	return Vector2(
		clampf(p.x, margin + r, s.x - margin - r),
		clampf(p.y, margin + r, s.y - margin - r))

func _say(list: Array) -> void:
	if list.is_empty():
		return
	quip = str(list[randi() % list.size()])
	quip_t = 1.6

# ───────────────────────── отрисовка ─────────────────────────
func _draw() -> void:
	if not _active:
		return
	var s := bounds
	var bg_col: Color = chapter.get("bg_color", Color(0.86, 0.80, 0.66))
	var floor_col: Color = chapter.get("floor_color", Color(0.78, 0.72, 0.56))
	var bgtex: Texture2D = Art.tex("bg_" + str(chapter.get("id", "")))
	if bgtex != null:
		draw_texture_rect(bgtex, Rect2(Vector2.ZERO, s), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, s), bg_col)
	draw_rect(Rect2(margin, margin, s.x - margin * 2.0, s.y - margin * 2.0), floor_col, false, 4.0)

	# текущая зона задачи
	if state == STATE_TASK and quest.has_current():
		var hp := _current_hotspot()
		var col := Color(0.96, 0.64, 0.23, 0.32)
		if _engaged():
			col = Color(0.99, 0.78, 0.30, 0.55)
		draw_circle(hp, hotspot_r, col)
		draw_arc(hp, hotspot_r, 0.0, TAU, 48, Color(0.85, 0.55, 0.15), 4.0)
		var itex: Texture2D = Art.tex("icon_" + str(quest.current().get("type", "")))
		if itex != null:
			var isz := 76.0
			draw_texture_rect(itex, Rect2(hp - Vector2(isz * 0.5, isz * 0.5), Vector2(isz, isz)), false)
		_text(hp + Vector2(-hotspot_r, -hotspot_r - 14.0), quest.current().get("label", ""), 22, Color(0.4, 0.25, 0.1))

	# выход
	if state == STATE_ESCAPE or state == STATE_WON:
		var etex: Texture2D = Art.tex("exit")
		if etex != null:
			var ed := exit_r * 2.0
			draw_texture_rect(etex, Rect2(chapter_exit - Vector2(exit_r, exit_r), Vector2(ed, ed)), false)
		else:
			draw_circle(chapter_exit, exit_r, Color(0.30, 0.62, 0.86, 0.5))
		draw_arc(chapter_exit, exit_r, 0.0, TAU, 40, Color(0.15, 0.45, 0.75), 4.0)
		_text(chapter_exit + Vector2(-40.0, -exit_r - 12.0), "ВЫХОД", 24, Color(0.1, 0.3, 0.55))

	# игрок (мультяшный пульс при движении)
	var pr := player_r
	if _moving > 0.1:
		pr = player_r * (1.0 + 0.07 * sin(_anim * 18.0))
	_blit(player, pr, "player", Color(0.30, 0.66, 0.35))
	if stun > 0.0:
		draw_arc(player, player_r + 6.0, 0.0, TAU, 24, Color(1, 1, 1, 0.7), 3.0)
	if quip_t > 0.0:
		_text(player + Vector2(-28.0, -player_r - 18.0), quip, 24, Color(0.2, 0.1, 0.05))

	# шалун
	var pcol := Color(0.86, 0.27, 0.22)
	var ptint := Color(1, 1, 1)
	if pursuer.phase == "telegraph":
		pcol = Color(1.0, 0.55, 0.1)
		ptint = Color(1.0, 0.82, 0.55)
	elif pursuer.phase == "dash":
		pcol = Color(1.0, 0.15, 0.1)
		ptint = Color(1.0, 0.65, 0.65)
	_blit(pursuer.pos, pursuer_r, "timokha", pcol, ptint)
	if Art.tex("timokha") == null:
		draw_line(pursuer.pos + Vector2(0, -pursuer_r), pursuer.pos + Vector2(8, -pursuer_r - 16.0), Color(0.2, 0.12, 0.08), 5.0)
	if pursuer.phase == "telegraph":
		_text(pursuer.pos + Vector2(-6.0, -pursuer_r - 26.0), "!", 40, Color(0.9, 0.1, 0.1))

	# джойстик
	if stick_active:
		draw_arc(stick_origin, 70.0, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 3.0)
		draw_circle(stick_cur, 26.0, Color(1, 1, 1, 0.4))

	# контекстные кнопки
	for b in _buttons():
		var r: Rect2 = b["rect"]
		draw_rect(r, Color(0.96, 0.64, 0.23, 0.85))
		draw_rect(r, Color(0.6, 0.35, 0.1), false, 3.0)
		_text(r.position + Vector2(r.size.x * 0.5 - 30.0, r.size.y * 0.5 + 14.0), str(b["label"]), 36, Color(0.3, 0.18, 0.05))

	_draw_hud(s)

	# интро-подсказка (только 1-я глава, первые секунды)
	if intro_t > 0.0:
		var a := clampf(intro_t / 4.0, 0.0, 1.0)
		draw_rect(Rect2(Vector2(s.x * 0.5 - 370.0, 196.0), Vector2(740.0, 124.0)), Color(0.1, 0.08, 0.05, 0.55 * a))
		_text(Vector2(s.x * 0.5 - 340.0, 240.0), "Беги от шалуна! Встань в жёлтую зону и делай дела.", 24, Color(1, 1, 1, a))
		_text(Vector2(s.x * 0.5 - 340.0, 282.0), "Движение: стрелки/перетаскивание. Кнопки задач — справа внизу.", 20, Color(1, 1, 1, a))

	if flash_bad > 0.0:
		draw_rect(Rect2(Vector2.ZERO, s), Color(1, 0.1, 0.1, 0.32 * flash_bad))
	if flash_good > 0.0:
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.2, 1, 0.3, 0.25 * flash_good))

	if _paused:
		draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.45))
		_text(s * 0.5 + Vector2(-95.0, -8.0), "ПАУЗА", 56, Color(1, 1, 1, 0.95))

func _draw_hud(s: Vector2) -> void:
	_text(Vector2(54, 66), "%s" % chapter.get("name", ""), 26, Color(0.2, 0.15, 0.1))
	_text(Vector2(54, 98), "Задачи: %d/%d   Поймали: %d   %.1f с" % [quest.done_count(), quest.task_count(), catches, elapsed], 22, Color(0.2, 0.15, 0.1))

	if state == STATE_TASK and active_mg != null:
		_text(Vector2(54, 132), active_mg.prompt(), 24, Color(0.45, 0.25, 0.05))
		var mg_meta: Dictionary = active_mg.meta()
		if mg_meta.has("marker"):
			_draw_timing(Vector2(54, 150), 380, 22, float(mg_meta["marker"]), float(mg_meta["target"]), float(mg_meta["band"]))
			_draw_progress(Vector2(54, 184), 380, 14, active_mg.progress(), {})
		else:
			_draw_progress(Vector2(54, 150), 380, 22, active_mg.progress(), mg_meta)
	elif state == STATE_TASK:
		_text(Vector2(54, 132), "Беги в жёлтую зону и выполни задачу!", 22, Color(0.3, 0.2, 0.1))
	elif state == STATE_ESCAPE:
		_text(Vector2(54, 132), "Все дела сделаны! БЕГИ К ВЫХОДУ — шалун на полной скорости!", 24, Color(0.55, 0.2, 0.1))
	elif state == STATE_WON:
		_text(s * 0.5 + Vector2(-150.0, -10.0), "СБЕЖАЛ!", 56, Color(0.15, 0.45, 0.2))

	_text(Vector2(54, s.y - 40.0), "Движение: стрелки/перетаскивание · Esc — меню", 18, Color(0.35, 0.3, 0.2))

func _draw_progress(pos: Vector2, w: float, h: float, frac: float, meta: Dictionary) -> void:
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0, 0, 0, 0.18))
	# целевая зона (tea)
	if meta.has("target"):
		var target: float = float(meta["target"])
		var band: float = float(meta.get("band", 0.1))
		var x0: float = pos.x + w * clampf(target - band, 0.0, 1.0)
		var x1: float = pos.x + w * clampf(target + band, 0.0, 1.0)
		draw_rect(Rect2(Vector2(x0, pos.y), Vector2(x1 - x0, h)), Color(0.3, 0.85, 0.35, 0.55))
	draw_rect(Rect2(pos, Vector2(w * clampf(frac, 0.0, 1.0), h)), Color(0.96, 0.78, 0.25))
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.4, 0.3, 0.1), false, 2.0)

func _draw_timing(pos: Vector2, w: float, h: float, marker: float, target: float, band: float) -> void:
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0, 0, 0, 0.18))
	var x0: float = pos.x + w * clampf(target - band, 0.0, 1.0)
	var x1: float = pos.x + w * clampf(target + band, 0.0, 1.0)
	draw_rect(Rect2(Vector2(x0, pos.y), Vector2(x1 - x0, h)), Color(0.3, 0.85, 0.35, 0.6))
	var mx: float = pos.x + w * clampf(marker, 0.0, 1.0)
	draw_rect(Rect2(Vector2(mx - 3.0, pos.y - 4.0), Vector2(6.0, h + 8.0)), Color(0.2, 0.1, 0.05))
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.4, 0.3, 0.1), false, 2.0)

func _blit(pos: Vector2, radius: float, key: String, fallback: Color, modulate: Color = Color.WHITE) -> void:
	var t: Texture2D = Art.tex(key)
	if t != null:
		var d := radius * 2.0
		draw_texture_rect(t, Rect2(pos - Vector2(radius, radius), Vector2(d, d)), false, modulate)
	else:
		draw_circle(pos, radius, fallback)

func _text(pos: Vector2, t: String, size: int, col: Color) -> void:
	if _font:
		draw_string(_font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
