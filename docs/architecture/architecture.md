# Architecture — Timokha Escape

*Status: Approved (solo) · 2026-06-24 · Godot 4.7 / GDScript / Mobile 2D*

## 1. Принципы
- **Логика отделена от визуала.** Автозагрузки `GameData` (данные) и `GS` (состояние/прогрессия)
  не знают о нодах отрисовки. Визуал (`World`, `Main`/UI) читает состояние и рисует.
- **Immediate-mode плейсхолдеры.** Геймплей рисуется через `_draw()` цветными фигурами;
  финальный арт — drop-in (`art/<key>.png`) позже, без переписывания логики.
- **Расширяемость мини-игр** через базовый класс `MinigameBase`.
- **Данные-первичны.** Главы/задачи/тюнинг — в `GameData.CHAPTERS`, не в коде сцен.

## 2. Слои и узлы
```
Autoloads:  GameData (data) · GS (state+save+signals) · Sfx · Music
Main (Node2D)  — экран-менеджер: MENU / CHAPTER_SELECT / GAME / RESULTS
  ├─ ui (CanvasLayer) — кнопки меню/результатов (Control/Button)
  └─ World (Node2D)   — геймплей одной главы (_draw + input + симуляция)
       ├─ Pursuer (RefCounted)        — логика преследователя
       ├─ QuestManager (RefCounted)   — state-machine задач
       └─ active Minigame : MinigameBase (RefCounted)
```

## 3. Контракты (API)

### GameData (autoload, чистые данные)
- `CHAPTERS: Array[Dictionary]` — `{id, name, pursuer_speed, tasks:[{id,type,label,pos:Vector2,cfg:Dictionary}], exit:Vector2, player_start:Vector2}`
- `chapter_count() -> int`, `get_chapter(i) -> Dictionary`
- `TUNING` — общий тюнинг погони по умолчанию.

### GS (autoload, состояние)
- Сигналы: `stars_changed`, `task_completed(task_id, stars)`, `chapter_completed(idx, stars)`, `caught`, `hud_dirty`.
- Состояние: `unlocked: int`, `best_stars: Dictionary` (chapter_id -> int), `current_chapter: int`.
- Методы: `load_game()`, `save_game()`, `record_chapter(idx, stars)`, `is_unlocked(i) -> bool`, `total_stars() -> int`.
- Сейв: `user://save.json`.

### MinigameBase (RefCounted) — `scripts/core/minigame_base.gd`
- `setup(cfg: Dictionary)`, `update(delta)`, `input_tap()`, `input_press(down: bool)`, `input_dir(dir: int)`
- `progress() -> float`, `is_done() -> bool`, `stars() -> int`, `prompt() -> String`, `controls() -> Array`
- Звёзды считает базовый `_score_stars()` по `cfg.par_time`, `_time`, `_mistakes`.

### Pursuer (RefCounted) — `scripts/core/pursuer.gd`
- `pos: Vector2`, тюнинг-поля; `update(delta, target: Vector2, slowed: bool, frozen: bool)`, `on_catch()`, `phase: String`.

### QuestManager (RefCounted) — `scripts/core/quest_manager.gd`
- `setup(tasks: Array)`, `current() -> Dictionary`, `complete_current(stars: int)`, `all_done() -> bool`, `chapter_stars() -> int`.

### World (Node2D) — `scripts/core/world.gd`
- `setup(chapter: Dictionary)`; сигналы `finished(stars: int)`, `quit_to_menu`.
- Владеет симуляцией, вводом и отрисовкой одной главы.

## 4. Поток управления
`Main` → выбор главы → `World.setup(chapter)` → игрок выполняет задачи под погоней →
`all_done` → выход → `World.finished(stars)` → `GS.record_chapter` + `save_game` → `RESULTS`.

## 5. Производительность
60 FPS; `_draw` + `queue_redraw` раз в кадр; партиклы-«джус» лёгкие. Мобильный бюджет.

## 6. Тестирование
Чистая логика (Minigame scoring, QuestManager, Pursuer.step, GS save) — headless-харнесс
`tests/run_tests.gd` (`godot --headless --script res://tests/run_tests.gd`). Без внешних аддонов.

См. ADR-лог: `docs/architecture/adr-log.md`. Правила реализации: `docs/control-manifest.md`.
