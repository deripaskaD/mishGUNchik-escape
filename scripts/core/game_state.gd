extends Node
## GS — состояние игры, прогрессия, сохранение. Чистая логика (ADR-0001).
## Не знает о нодах отрисовки. Сигналы — для визуала/аудио.

signal stars_changed
signal task_completed(task_id: String, stars: int)
signal chapter_completed(idx: int, stars: int)
signal caught
signal audio_settings_changed

var save_path := "user://save.json"   # переопределяется в тестах для изоляции
const SAVE_VERSION := 1

var unlocked: int = 1                 # сколько глав открыто (>=1)
var best_stars: Dictionary = {}       # chapter_id(String) -> int(0..3)
var current_chapter: int = 0          # активная глава (для UI)
var music_on: bool = true             # настройка: фоновая музыка
var sfx_on: bool = true               # настройка: звуковые эффекты

func _ready() -> void:
	load_game()

func is_unlocked(i: int) -> bool:
	return i >= 0 and i < unlocked

func best_for(chapter_id: String) -> int:
	return int(best_stars.get(chapter_id, 0))

func total_stars() -> int:
	var s := 0
	for v in best_stars.values():
		s += int(v)
	return s

## Зафиксировать результат прохождения главы idx (звёзды 1..3).
func record_chapter(idx: int, stars: int) -> void:
	var chapter: Dictionary = GameData.get_chapter(idx)
	if chapter.is_empty():
		return
	var cid: String = chapter["id"]
	if stars > best_for(cid):
		best_stars[cid] = stars
		stars_changed.emit()
	# открыть следующую главу
	var next_unlocked: int = clampi(idx + 2, unlocked, GameData.chapter_count())
	if next_unlocked > unlocked:
		unlocked = next_unlocked
	chapter_completed.emit(idx, stars)
	save_game()

func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"unlocked": unlocked,
		"best_stars": best_stars,
		"music_on": music_on,
		"sfx_on": sfx_on,
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_warning("GS: не удалось открыть сейв на запись")
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("GS: битый сейв — игнорирую")
		return
	var data: Dictionary = parsed
	unlocked = maxi(1, int(data.get("unlocked", 1)))
	music_on = bool(data.get("music_on", true))
	sfx_on = bool(data.get("sfx_on", true))
	var bs: Variant = data.get("best_stars", {})
	if typeof(bs) == TYPE_DICTIONARY:
		best_stars = {}
		for k in bs.keys():
			best_stars[str(k)] = int(bs[k])

func set_music(on: bool) -> void:
	music_on = on
	save_game()
	audio_settings_changed.emit()

func set_sfx(on: bool) -> void:
	sfx_on = on
	save_game()
	audio_settings_changed.emit()

## Полный сброс прогресса (для отладки/настроек).
func reset_progress() -> void:
	unlocked = 1
	best_stars = {}
	save_game()
	stars_changed.emit()
