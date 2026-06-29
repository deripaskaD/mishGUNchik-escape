extends Node
## GameData — чистые данные игры (главы, задачи, тюнинг).
## Не знает о нодах отрисовки (ADR-0001). Только чтение.

# Общий тюнинг погони по умолчанию (переопределяется per-chapter pursuer_speed).
var TUNING := {
	"player_speed": 320.0,
	"pursuer_speed": 240.0,
	"dash_speed": 520.0,
	"telegraph_time": 0.55,
	"dash_time": 0.35,
	"lunge_interval": 3.6,
	"lunge_range": 540.0,
	"slow_factor": 0.38,
	"stun_time": 0.7,
	"player_r": 26.0,
	"pursuer_r": 30.0,
	"hotspot_r": 92.0,
	"exit_r": 64.0,
	"margin": 40.0,
	"knockback": 140.0,
}

# Главы. Каждая: id, name, pursuer_speed, player_start, tasks[], exit.
# task: {id, type(pies|tea|wood), label, pos:Vector2, cfg:Dictionary}
var CHAPTERS := [
	{
		"id": "kitchen",
		"name": "Глава 1 — Кухня",
		"pursuer_speed": 228.0,
		"bg_color": Color(0.90, 0.83, 0.66),
		"floor_color": Color(0.80, 0.72, 0.55),
		"player_start": Vector2(180, 360),
		"exit": Vector2(1180, 120),
		"tasks": [
			{"id": "pies1", "type": "pies", "label": "Слепи пирожки", "pos": Vector2(520, 300),
				"cfg": {"target_taps": 13, "par_time": 6.0}},
			{"id": "tea1", "type": "tea", "label": "Завари чай (отпусти в зелёной зоне)", "pos": Vector2(840, 480),
				"cfg": {"target": 0.80, "band": 0.11, "fill_speed": 0.55, "par_time": 5.5}},
		],
	},
	{
		"id": "yard",
		"name": "Глава 2 — Двор",
		"pursuer_speed": 250.0,
		"bg_color": Color(0.74, 0.83, 0.55),
		"floor_color": Color(0.60, 0.73, 0.44),
		"player_start": Vector2(170, 400),
		"exit": Vector2(1180, 620),
		"tasks": [
			{"id": "wood1", "type": "wood", "label": "Наколи дров (чередуй ← →)", "pos": Vector2(470, 250),
				"cfg": {"target_chops": 10, "par_time": 7.0}},
			{"id": "pies2", "type": "pies", "label": "Ещё пирожков!", "pos": Vector2(900, 430),
				"cfg": {"target_taps": 15, "par_time": 6.0}},
		],
	},
	{
		"id": "pier",
		"name": "Глава 3 — Причал",
		"pursuer_speed": 272.0,
		"bg_color": Color(0.62, 0.80, 0.86),
		"floor_color": Color(0.50, 0.70, 0.80),
		"player_start": Vector2(180, 360),
		"exit": Vector2(1185, 360),
		"tasks": [
			{"id": "tea2", "type": "tea", "label": "Чай деду (отпусти в зоне)", "pos": Vector2(430, 520),
				"cfg": {"target": 0.78, "band": 0.10, "fill_speed": 0.62, "par_time": 5.5}},
			{"id": "wood2", "type": "wood", "label": "Наколи дров (← →)", "pos": Vector2(770, 220),
				"cfg": {"target_chops": 12, "par_time": 7.5}},
			{"id": "pies3", "type": "pies", "label": "Пирожки в дорогу", "pos": Vector2(1000, 480),
				"cfg": {"target_taps": 16, "par_time": 6.5}},
		],
	},
	{
		"id": "bigrun",
		"name": "Глава 4 — Большой побег",
		"pursuer_speed": 286.0,
		"bg_color": Color(0.85, 0.72, 0.60),
		"floor_color": Color(0.74, 0.60, 0.48),
		"player_start": Vector2(160, 560),
		"exit": Vector2(1180, 90),
		"tasks": [
			{"id": "feed1", "type": "feed", "label": "Накорми шалуна огурцом", "pos": Vector2(610, 360),
				"cfg": {"target": 0.5, "band": 0.14, "marker_speed": 0.85, "target_hits": 4, "par_time": 7.5}},
			{"id": "wood3", "type": "wood", "label": "Руби канаты (← →)", "pos": Vector2(380, 250),
				"cfg": {"target_chops": 12, "par_time": 7.0}},
			{"id": "tea3", "type": "tea", "label": "Плесни деду чаю (отпусти в зоне)", "pos": Vector2(720, 540),
				"cfg": {"target": 0.82, "band": 0.09, "fill_speed": 0.66, "par_time": 5.0}},
			{"id": "pies4", "type": "pies", "label": "Последние пирожки!", "pos": Vector2(1010, 250),
				"cfg": {"target_taps": 18, "par_time": 6.5}},
		],
	},
]

func chapter_count() -> int:
	return CHAPTERS.size()

func get_chapter(i: int) -> Dictionary:
	if i < 0 or i >= CHAPTERS.size():
		return {}
	return CHAPTERS[i]

func tuning_for(chapter: Dictionary) -> Dictionary:
	# копия общего тюнинга с подстановкой pursuer_speed главы
	var t := TUNING.duplicate()
	if chapter.has("pursuer_speed"):
		t["pursuer_speed"] = chapter["pursuer_speed"]
	return t
