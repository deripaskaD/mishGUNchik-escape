extends SceneTree
## Интеграционный headless-прогон World: ВСЕ главы от старта до побега.
## Покрывает все типы мини-игр (pies/tea/wood) и контент через реальный World.
## Запуск: godot --headless --script res://tests/integration_world.gd

var _pass := 0
var _fail := 0

func ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		printerr("  FAIL: ", msg)

func _initialize() -> void:
	print("== Integration: World play-through (все главы) ==")
	var gd = load("res://scripts/data/game_data.gd").new()
	var n: int = gd.chapter_count()
	ok(n >= 1, "глав в игре: %d" % n)
	for ci in n:
		_play_chapter(gd, ci, ci == 0)
	print("== Result: %d passed, %d failed ==" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _play_chapter(gd, ci: int, test_catch: bool) -> void:
	var w = load("res://scripts/core/world.gd").new()
	get_root().add_child(w)
	var result := {"stars": -1}
	w.finished.connect(func(s: int): result["stars"] = s)
	w.setup(gd.get_chapter(ci))

	if test_catch:
		w.pursuer.pos = w.player
		w._process(0.05)
		ok(w.catches >= 1, "ch%d: поимка без краша" % ci)

	var guard := 0
	while result["stars"] == -1 and guard < 8000:
		guard += 1
		w.pursuer.pos = Vector2(40, 40)
		w.stun = 0.0
		if int(w.state) == 0:
			if w.quest.has_current():
				w.player = w._current_hotspot()
			w._process(0.03)
			if w.active_mg != null:
				_feed(w.active_mg)
				w._process(0.03)
		elif int(w.state) == 1:
			w.player = w.chapter_exit
			w._process(0.03)
		else:
			break

	ok(int(w.state) == 2, "ch%d: победа (WON)" % ci)
	ok(result["stars"] >= 1 and result["stars"] <= 3, "ch%d: звёзды 1..3 (%s)" % [ci, str(result["stars"])])
	ok(guard < 8000, "ch%d: без зацикливания (iter=%d)" % [ci, guard])

	get_root().remove_child(w)
	w.free()

func _feed(mg) -> void:
	var c: Array = mg.controls()
	if c.has("L"):
		var ex: int = int(mg.meta().get("expect", -1))
		mg.input_dir(ex)
	elif c.has("hold"):
		mg.input_press(true)
		var tgt: float = float(mg.cfg.get("target", 0.8))
		var fs: float = float(mg.cfg.get("fill_speed", 0.55))
		mg.update(tgt / fs)
		mg.input_press(false)
	else:
		mg.input_tap()
