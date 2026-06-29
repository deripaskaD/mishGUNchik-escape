extends SceneTree
## Headless-харнесс логики (ADR-0007).
## Запуск: godot --headless --script res://tests/run_tests.gd

var _pass := 0
var _fail := 0

func ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		printerr("  FAIL: ", msg)

func _initialize() -> void:
	print("== Timokha Escape — logic tests ==")
	_test_pies()
	_test_tea()
	_test_wood()
	_test_feed()
	_test_quest()
	_test_pursuer()
	_test_save()
	print("== Result: %d passed, %d failed ==" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _test_pies() -> void:
	var mg = load("res://scripts/core/minigames/mg_pies.gd").new()
	mg.setup({"target_taps": 3, "par_time": 100.0})
	ok(not mg.is_done(), "pies: не выполнена в начале")
	mg.input_tap()
	mg.input_tap()
	ok(not mg.is_done(), "pies: не выполнена после 2/3")
	mg.input_tap()
	ok(mg.is_done(), "pies: выполнена после 3/3")
	ok(mg.progress() >= 0.999, "pies: прогресс = 1")
	ok(mg.stars() == 3, "pies: 3 звезды без ошибок и в срок")

func _test_tea() -> void:
	var mg = load("res://scripts/core/minigames/mg_tea.gd").new()
	mg.setup({"target": 0.8, "band": 0.1, "fill_speed": 1.0, "par_time": 100.0})
	mg.input_press(true)
	mg.update(0.8)            # fill -> 0.8
	mg.input_press(false)     # отпуск в зоне
	ok(mg.is_done(), "tea: выполнена при отпуске в зоне")
	ok(mg.stars() == 3, "tea: 3 звезды")

	var mg2 = load("res://scripts/core/minigames/mg_tea.gd").new()
	mg2.setup({"target": 0.8, "band": 0.1, "fill_speed": 1.0, "par_time": 100.0})
	mg2.input_press(true)
	mg2.update(1.3)           # перелив > 1.2 -> промах + сброс
	ok(not mg2.is_done(), "tea: перелив не завершает")
	ok(mg2.mistakes() == 1, "tea: перелив = 1 промах")

func _test_wood() -> void:
	var mg = load("res://scripts/core/minigames/mg_wood.gd").new()
	mg.setup({"target_chops": 4, "par_time": 100.0})
	mg.input_dir(1)           # ждали -1 -> промах
	ok(mg.mistakes() == 1, "wood: неверная сторона = промах")
	mg.input_dir(-1)
	mg.input_dir(1)
	mg.input_dir(-1)
	mg.input_dir(1)
	ok(mg.is_done(), "wood: 4 корректных чередования = выполнено")

func _test_feed() -> void:
	# метка стоит на 0 (marker_speed=0). target=0.5 -> промах; target=0 -> попадание.
	var mg = load("res://scripts/core/minigames/mg_feed.gd").new()
	mg.setup({"target": 0.5, "band": 0.2, "marker_speed": 0.0, "target_hits": 2, "par_time": 100.0})
	mg.input_tap()
	ok(mg.mistakes() == 1, "feed: тап мимо зелёной зоны = промах")
	var mg2 = load("res://scripts/core/minigames/mg_feed.gd").new()
	mg2.setup({"target": 0.0, "band": 0.2, "marker_speed": 0.0, "target_hits": 2, "par_time": 100.0})
	mg2.input_tap()
	mg2.input_tap()
	ok(mg2.is_done(), "feed: 2 точных тапа = выполнено")
	ok(mg2.stars() == 3, "feed: 3 звезды без промахов")

func _test_quest() -> void:
	var q = load("res://scripts/core/quest_manager.gd").new()
	q.setup([{"id": "a"}, {"id": "b"}])
	ok(q.current().get("id", "") == "a", "quest: первая задача 'a'")
	q.complete_current(3)
	ok(q.current().get("id", "") == "b", "quest: вторая задача 'b'")
	ok(not q.all_done(), "quest: ещё не всё")
	q.complete_current(1)
	ok(q.all_done(), "quest: всё выполнено")
	ok(q.chapter_stars() == 2, "quest: средние звёзды round((3+1)/2)=2")

func _test_pursuer() -> void:
	var p = load("res://scripts/core/pursuer.gd").new()
	p.configure({"pursuer_speed": 240.0, "lunge_interval": 3.6})
	p.pos = Vector2(0, 0)
	var target := Vector2(500, 0)
	var d0: float = p.pos.distance_to(target)
	p.update(0.1, target, false, false)
	ok(p.pos.distance_to(target) < d0, "pursuer: приближается к цели")
	ok(p.phase == "walk", "pursuer: без рывка на старте (walk)")
	# frozen — не двигается
	var before: Vector2 = p.pos
	p.update(0.1, target, false, true)
	ok(p.pos == before, "pursuer: frozen не двигается")

func _test_save() -> void:
	var script := load("res://scripts/core/game_state.gd")
	var test_path := "user://test_save.json"
	var gs = script.new()
	gs.save_path = test_path
	gs.unlocked = 3
	gs.best_stars = {"kitchen": 2, "yard": 3}
	gs.music_on = false
	gs.sfx_on = false
	gs.save_game()
	var gs2 = script.new()
	gs2.save_path = test_path
	gs2.load_game()
	ok(gs2.unlocked == 3, "save: unlocked сохранился")
	ok(gs2.best_for("yard") == 3, "save: best_stars сохранились")
	ok(gs2.music_on == false, "save: music_on сохранён")
	ok(gs2.sfx_on == false, "save: sfx_on сохранён")
	# чистим тестовый сейв, чтобы не оставлять следов
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	gs.free()
	gs2.free()
