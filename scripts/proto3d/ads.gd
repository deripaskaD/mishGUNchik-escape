extends Node
## КАРКАС МОНЕТИЗАЦИИ (ЗАГЛУШКА, раздел E дев-брифа).
## Реальный SDK (AdMob / AppLovin MAX) подключает пользователь: заменить тела
## show_interstitial() и show_rewarded() на вызовы SDK, сохранив сигнатуры и сигнал.
## Вся логика частотных капов/грейса/комплаенса уже здесь — SDK-код будет тонким.
##
## Точки rewarded, уже размеченные в игре (тег → награда):
##   "revive"    — воскреснуть после поимки (подключено, кнопка на экране конца)
##   "hint"      — подсказка, где предмет (резерв — вызвать show_rewarded("hint"))
##   "flashlight"— фонарик/ускорение на ночь (резерв)
##   "skip"      — пропустить сложный момент (резерв)
## КОМПЛАЕНС: child_directed=true → в SDK включить неперсонализированную рекламу
## (COPPA / Google Families / Apple Kids): tagForChildDirectedTreatment и т.п.

signal rewarded_done(tag: String, ok: bool)

const INTER_COOLDOWN := 150.0        # interstitial не чаще раза в 2.5 минуты
const FIRST_SESSION_GRACE := 120.0   # первые 2 минуты сессии — БЕЗ рекламы (сначала зацепить)

var child_directed := true           # детская аудитория → неперсонализированная реклама
var ads_removed := false             # IAP «убрать рекламу»: interstitial выкл, rewarded остаётся
var _session_t := 0.0
var _last_inter := -INF

func _process(delta: float) -> void:
	_session_t += delta

func can_interstitial() -> bool:
	return (not ads_removed) and _session_t > FIRST_SESSION_GRACE \
		and (_session_t - _last_inter) > INTER_COOLDOWN

signal interstitial_shown(reason: String)   # для аналитики (game3d слушает и логирует)

func show_interstitial(reason: String) -> void:
	# ← ТОЧКА ИНТЕГРАЦИИ SDK. Заглушка ничего не показывает (без фейковых экранов у тестеров).
	if not can_interstitial():
		return
	_last_inter = _session_t
	print("[ads] interstitial (%s) — заглушка; здесь вызов SDK" % reason)
	interstitial_shown.emit(reason)

func show_rewarded(tag: String) -> void:
	# ← ТОЧКА ИНТЕГРАЦИИ SDK. Заглушка мгновенно «выдаёт награду» (dev-режим).
	# С реальным SDK: показать ролик → в колбэке успеха emit rewarded_done(tag, true).
	print("[ads] rewarded (%s) — заглушка; награда выдана сразу" % tag)
	rewarded_done.emit(tag, true)
