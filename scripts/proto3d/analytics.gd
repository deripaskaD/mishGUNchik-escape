extends Node
## КАРКАС ТЕЛЕМЕТРИИ/АНАЛИТИКИ (ЗАГЛУШКА).
## Цель: воронка удержания и рекламных показов для дата-ориентированного релиза
## (органический ASO живёт на retention; доход = показы рекламы). Реальный провайдер
## (Firebase / GameAnalytics / AppsFlyer) подключает пользователь: заменить тело log()
## на вызов SDK, сохранив сигнатуру. КОМПЛАЕНС: для детей — анонимно, без PII, без рекламных ID
## (COPPA / Google Families). Здесь только имя события + числовые/строковые параметры.
##
## Ключевые события (уже расставлены в game3d.gd):
##   session_start {gentle, lowgfx, streak}   — старт сессии
##   game_start                               — нажатие «Играть» (конверсия тайтла)
##   quest_done {id, done_count, night}       — прогресс (главный retention-сигнал)
##   night_reached {night}                    — дожил до ночи (глубина сессии)
##   caught {night, lives_left}               — поимка (сложность/фрустрация)
##   game_win {nights, caught, seconds}       — победа (завершаемость)
##   ad_rewarded {tag, granted}               — воронка rewarded-рекламы (доход)
##   ad_interstitial {reason}                 — показ interstitial

var _t0 := 0.0

func _ready() -> void:
	_t0 = Time.get_ticks_msec() / 1000.0

func log_event(name: String, params: Dictionary = {}) -> void:
	# ← ТОЧКА ИНТЕГРАЦИИ SDK. Заглушка печатает в консоль (видно в dev/веб-консоли).
	print("[analytics] %s %s" % [name, JSON.stringify(params)])

func session_seconds() -> int:
	return int(Time.get_ticks_msec() / 1000.0 - _t0)
