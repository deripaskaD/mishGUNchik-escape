extends SceneTree
## Flow-тест экран-менеджера Main: меню → выбор глав → игра → пауза → resume → результаты.
## Запуск: godot --headless --script res://tests/integration_flow.gd

var _pass := 0
var _fail := 0

func ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		printerr("  FAIL: ", msg)

func _initialize() -> void:
	print("== Integration: Main screen flow ==")
	var m = load("res://scripts/main.gd").new()
	m._ready()                                  # строит ui + меню (без --autostart)
	ok(m.ui != null, "ui создан")
	ok(m.screen_root != null, "меню построено")

	m.show_chapter_select()
	ok(m.screen_root != null, "экран выбора глав построен")

	m.start_game(0)
	ok(m.world != null, "world создан при старте игры")
	ok(m.screen_root == null, "меню очищено при старте игры")

	# пауза
	m.world.set_paused(true)
	m._show_pause()
	ok(m.pause_root != null, "оверлей паузы показан")
	ok(m.world._paused == true, "world на паузе")
	m._resume()
	ok(m.pause_root == null, "пауза снята (overlay убран)")
	ok(m.world._paused == false, "world снят с паузы")

	# результаты
	m.show_results(0, 2)
	ok(m.screen_root != null, "экран результатов построен")
	ok(m.world == null, "world очищен на результатах")

	# настройки
	m.show_settings()
	ok(m.screen_root != null, "экран настроек построен")

	# назад в меню
	m.show_menu()
	ok(m.screen_root != null, "меню перестроено")

	print("== Result: %d passed, %d failed ==" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
