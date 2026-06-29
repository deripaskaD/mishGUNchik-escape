# PROTOTYPE - NOT FOR PRODUCTION
# Question: ощущается ли ПОСТОЯННАЯ погоня шалуна как веселье, а не фрустрация?
# Date: 2026-06-24
#
# Управление:
#   - Движение: СТРЕЛКИ/WASD на клавиатуре ИЛИ перетаскивание пальцем/мышью по экрану (плавающий джойстик).
#   - Мини-игра ("лепи пирожки"): ПРОБЕЛ, либо тап по кнопке "ТАП" справа-внизу — но только стоя в жёлтой зоне.
#   - Рестарт: R.
#
# Идея: красный шалун ВСЁ ВРЕМЯ гонится. Встань в жёлтую зону (там он замедляется),
# натапай прогресс мини-игры до конца -> появится синий ВЫХОД -> добеги до него,
# уворачиваясь (теперь он на полной скорости). Если шалун касается тебя — "осалил":
# сброс прогресса задачи + отскок + короткое оглушение (но никакого Game Over).

extends Node2D

# ── Тюнинг (то, что и проверяем плейтестом) ─────────────────────────────
const PLAYER_SPEED := 320.0
const PURSUER_SPEED := 240.0          # прощающе: медленнее игрока
const PURSUER_SLOW_FACTOR := 0.38     # замедление у жёлтой зоны
const DASH_SPEED := 520.0             # рывок
const DASH_TIME := 0.35
const TELEGRAPH_TIME := 0.55          # «замах» перед рывком (видимый телеграф)
const LUNGE_INTERVAL := 3.6           # как часто шалун пытается рвануть
const LUNGE_RANGE := 540.0            # дистанция, на которой он решается рвануть
const STUN_TIME := 0.7                # оглушение игрока после поимки
const TARGET_TAPS := 12               # сколько тапов = задача выполнена
const PLAYER_R := 26.0
const PURSUER_R := 30.0
const HOTSPOT_R := 90.0
const EXIT_R := 60.0
const MARGIN := 40.0

# ── Состояние ───────────────────────────────────────────────────────────
enum { STATE_TASK, STATE_ESCAPE, STATE_WIN }
var state := STATE_TASK

var player := Vector2(220, 360)
var pursuer := Vector2(1050, 360)
var hotspot := Vector2(640, 360)
var exit_pos := Vector2(1180, 80)

var taps := 0
var catches := 0
var elapsed := 0.0
var attempts := 1

var stun := 0.0
var flash := 0.0                       # красная вспышка на «осаливании»
var win_msg_t := 0.0

# Погоня-рывок
var lunge_cd := LUNGE_INTERVAL
var telegraphing := false
var telegraph_t := 0.0
var dashing := false
var dash_t := 0.0

# Плавающий джойстик
var stick_active := false
var stick_origin := Vector2.ZERO
var stick_cur := Vector2.ZERO

var _font: Font

func _ready() -> void:
	_font = ThemeDB.fallback_font
	set_process(true)

func _tap_button_rect() -> Rect2:
	var s := get_viewport_rect().size
	return Rect2(s.x - 230, s.y - 200, 180, 150)

# ── Ввод ────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			_on_press(event.position)
		else:
			if not _tap_button_rect().has_point(event.position):
				stick_active = false
	elif event is InputEventMouseMotion:
		if stick_active:
			stick_cur = event.position
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_do_tap()
		elif event.keycode == KEY_R:
			_restart_all()

func _on_press(pos: Vector2) -> void:
	if _tap_button_rect().has_point(pos):
		_do_tap()
		return
	stick_active = true
	stick_origin = pos
	stick_cur = pos

func _do_tap() -> void:
	if state == STATE_WIN:
		_restart_all()
		return
	if state != STATE_TASK:
		return
	# тапы засчитываются только стоя в жёлтой зоне
	if player.distance_to(hotspot) <= HOTSPOT_R:
		taps += 1
		if taps >= TARGET_TAPS:
			taps = TARGET_TAPS
			state = STATE_ESCAPE

# ── Логика ──────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if state != STATE_WIN:
		elapsed += delta
	if flash > 0.0:
		flash = max(0.0, flash - delta * 2.5)
	if stun > 0.0:
		stun = max(0.0, stun - delta)

	_update_player(delta)
	_update_pursuer(delta)
	_check_catch()
	_check_goals(delta)
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
	if stun > 0.0:
		return
	var mv := _move_vector()
	player += mv * PLAYER_SPEED * delta
	player = _clamp_pos(player, PLAYER_R)

func _update_pursuer(delta: float) -> void:
	var in_slow := state == STATE_TASK and player.distance_to(hotspot) <= HOTSPOT_R

	# машина рывка (подавлена у замедляющей зоны — там «погоня паузится»)
	if not telegraphing and not dashing:
		lunge_cd -= delta
		if lunge_cd <= 0.0 and not in_slow and pursuer.distance_to(player) < LUNGE_RANGE and state != STATE_WIN:
			telegraphing = true
			telegraph_t = TELEGRAPH_TIME
	elif telegraphing:
		telegraph_t -= delta
		if telegraph_t <= 0.0:
			telegraphing = false
			dashing = true
			dash_t = DASH_TIME
	elif dashing:
		dash_t -= delta
		if dash_t <= 0.0:
			dashing = false
			lunge_cd = LUNGE_INTERVAL

	var spd := PURSUER_SPEED
	if dashing:
		spd = DASH_SPEED
	if telegraphing:
		spd *= 0.15            # почти замер на замахе — это и есть телеграф
	if in_slow:
		spd *= PURSUER_SLOW_FACTOR
	if state == STATE_WIN:
		spd = 0.0

	var dir := (player - pursuer)
	if dir.length() > 1.0:
		pursuer += dir.normalized() * spd * delta
	pursuer = _clamp_pos(pursuer, PURSUER_R)

func _check_catch() -> void:
	if stun > 0.0 or state == STATE_WIN:
		return
	if pursuer.distance_to(player) <= PLAYER_R + PURSUER_R:
		# «осалил» — комичный сетбэк, без Game Over
		catches += 1
		stun = STUN_TIME
		flash = 1.0
		var away := (player - pursuer)
		if away.length() < 1.0:
			away = Vector2.RIGHT
		away = away.normalized()
		player += away * 140.0
		pursuer -= away * 90.0
		player = _clamp_pos(player, PLAYER_R)
		pursuer = _clamp_pos(pursuer, PURSUER_R)
		if state == STATE_TASK:
			taps = 0          # сброс прогресса текущей задачи (как в дизайне)
		# отменяем активный рывок
		telegraphing = false
		dashing = false
		lunge_cd = LUNGE_INTERVAL

func _check_goals(delta: float) -> void:
	if state == STATE_ESCAPE:
		if player.distance_to(exit_pos) <= EXIT_R + PLAYER_R:
			state = STATE_WIN
			win_msg_t = 0.0
	elif state == STATE_WIN:
		win_msg_t += delta

func _clamp_pos(p: Vector2, r: float) -> Vector2:
	var s := get_viewport_rect().size
	return Vector2(clamp(p.x, MARGIN + r, s.x - MARGIN - r), clamp(p.y, MARGIN + r, s.y - MARGIN - r))

func _restart_all() -> void:
	state = STATE_TASK
	player = Vector2(220, 360)
	pursuer = Vector2(1050, 360)
	taps = 0
	catches = 0
	elapsed = 0.0
	attempts += 1
	stun = 0.0
	flash = 0.0
	telegraphing = false
	dashing = false
	lunge_cd = LUNGE_INTERVAL
	stick_active = false

# ── Отрисовка (плейсхолдеры) ────────────────────────────────────────────
func _draw() -> void:
	var s := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.86, 0.80, 0.66))                 # тёплый «двор»
	draw_rect(Rect2(MARGIN, MARGIN, s.x - MARGIN * 2, s.y - MARGIN * 2), Color(0.78, 0.72, 0.56), false, 4.0)

	# жёлтая зона (горячая точка / замедление)
	var hot_col := Color(0.96, 0.64, 0.23, 0.35)
	if state == STATE_TASK and player.distance_to(hotspot) <= HOTSPOT_R:
		hot_col = Color(0.99, 0.78, 0.30, 0.55)
	draw_circle(hotspot, HOTSPOT_R, hot_col)
	draw_arc(hotspot, HOTSPOT_R, 0, TAU, 48, Color(0.85, 0.55, 0.15), 4.0)
	if state == STATE_TASK:
		_text(hotspot + Vector2(-70, -HOTSPOT_R - 14), "ЛЕПИ ПИРОЖКИ", 22, Color(0.4, 0.25, 0.1))

	# выход
	if state == STATE_ESCAPE or state == STATE_WIN:
		draw_circle(exit_pos, EXIT_R, Color(0.30, 0.62, 0.86, 0.5))
		draw_arc(exit_pos, EXIT_R, 0, TAU, 40, Color(0.15, 0.45, 0.75), 4.0)
		_text(exit_pos + Vector2(-36, -EXIT_R - 12), "ВЫХОД", 22, Color(0.1, 0.3, 0.55))

	# игрок
	draw_circle(player, PLAYER_R, Color(0.30, 0.66, 0.35))
	if stun > 0.0:
		draw_arc(player, PLAYER_R + 6, 0, TAU, 24, Color(1, 1, 1, 0.7), 3.0)

	# шалун-преследователь
	var pcol := Color(0.86, 0.27, 0.22)
	if telegraphing:
		pcol = Color(1.0, 0.55, 0.1)   # «замах» — оранжевый
	elif dashing:
		pcol = Color(1.0, 0.15, 0.1)   # рывок — ярко-красный
	draw_circle(pursuer, PURSUER_R, pcol)
	# «вихор» — опознавательный признак
	draw_line(pursuer + Vector2(0, -PURSUER_R), pursuer + Vector2(8, -PURSUER_R - 16), Color(0.2, 0.12, 0.08), 5.0)
	if telegraphing:
		_text(pursuer + Vector2(-6, -PURSUER_R - 26), "!", 40, Color(0.9, 0.1, 0.1))

	# джойстик
	if stick_active:
		draw_arc(stick_origin, 70, 0, TAU, 32, Color(1, 1, 1, 0.35), 3.0)
		draw_circle(stick_cur, 26, Color(1, 1, 1, 0.4))

	# кнопка ТАП
	var br := _tap_button_rect()
	draw_rect(br, Color(0.96, 0.64, 0.23, 0.85))
	draw_rect(br, Color(0.6, 0.35, 0.1), false, 3.0)
	_text(br.position + Vector2(46, 92), "ТАП", 40, Color(0.3, 0.18, 0.05))

	# HUD
	_text(Vector2(54, 70), "Поймали тебя: %d   Время: %.1f с   Попытка: %d" % [catches, elapsed, attempts], 24, Color(0.2, 0.15, 0.1))
	if state == STATE_TASK:
		_text(Vector2(54, 104), "Задача: встань в жёлтую зону и тапай (%d/%d)" % [taps, TARGET_TAPS], 24, Color(0.2, 0.15, 0.1))
		_progress(Vector2(54, 120), 360, 22, float(taps) / float(TARGET_TAPS))
	elif state == STATE_ESCAPE:
		_text(Vector2(54, 104), "Пирожки готовы! БЕГИ К ВЫХОДУ — шалун на полной скорости!", 24, Color(0.55, 0.2, 0.1))
	elif state == STATE_WIN:
		_text(s * 0.5 + Vector2(-150, -20), "СБЕЖАЛ! :)", 56, Color(0.15, 0.45, 0.2))
		_text(s * 0.5 + Vector2(-200, 36), "Тап / R — сыграть снова", 26, Color(0.2, 0.2, 0.2))

	# вспышка на «осаливании»
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, s), Color(1, 0.1, 0.1, 0.35 * flash))

func _text(pos: Vector2, t: String, size: int, col: Color) -> void:
	if _font:
		draw_string(_font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _progress(pos: Vector2, w: float, h: float, frac: float) -> void:
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(pos, Vector2(w * clamp(frac, 0.0, 1.0), h)), Color(0.96, 0.78, 0.25))
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.4, 0.3, 0.1), false, 2.0)
