# Technical Preferences — Timokha Escape

## Engine & Language

- **Engine**: Godot 4.7 (stable, released 2026-06-18)
- **Language**: GDScript
- **Rendering**: Mobile (Forward Mobile), 2D
- **Build System**: Godot Export Templates (iOS/Android)
- **Asset Pipeline**: Godot Import System + drop-in плейсхолдер-спрайты в `art/`

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Source Layout (важно — НЕ стандартный src/)

- **GDScript**: `scripts/` (`core/`, `data/`, `ui/`, `audio/`, корень)
- **Сцены**: `scenes/` (`res://`)
- **Арт / drop-in спрайты**: `art/`
- **Инструменты**: `tools/`
- Точка входа (план): `scenes/main.tscn`.

## Input & Platform

- **Target Platforms**: iOS + Android (мобайл), ландшафт
- **Input Methods**: Touch (основной); мышь/клавиатура — только для теста на десктопе
- **Primary Input**: Touch (тап по «горячим точкам», свайпы/удержания в мини-играх)
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: ландшафт; тач-зоны и UI адаптируются под размер экрана; крупные читаемые цели под палец

## Naming Conventions (GDScript)

- **Classes**: PascalCase (`MinigameBase`, `QuestManager`)
- **Variables/functions**: snake_case; приватные — с префиксом `_`
- **Signals**: snake_case в прош. времени (`minigame_finished`, `task_unlocked`, `escape_started`)
- **Files**: snake_case (`minigame_base.gd`, `quest_manager.gd`)
- **Scenes**: snake_case или PascalCase по корневому узлу
- **Constants**: UPPER_SNAKE_CASE (таблицы данных)

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: ~16.6 ms
- **Draw Calls**: 2D-спрайты; следить за «джус»-частицами на слабых Android
- **Memory Ceiling**: консервативный мобильный бюджет

## Testing

- **Framework**: GUT (Godot Unit Test) для логики (движок мини-игр, квест-цепочка, оценка звёзд)
- **Required Tests**: формулы оценки мини-игр (звёзды), state-machine квест-цепочки, условие триггера побега

## Forbidden Patterns

- [TO BE CONFIGURED по мере роста проекта]
- Базово: не смешивать логику игры (state/данные) с визуалом/нодами отрисовки.

## Allowed Libraries / Addons

- Только ваниль Godot 4.7; внешних аддонов нет (добавлять по факту интеграции, не впрок).

## Architecture Decisions Log

- Логика отделена от визуала (data/state ↔ сцены/UI).
- Единый расширяемый «движок мини-игр» (`MinigameBase`) — добавление новой мини-игры дёшево.
- Весь визуал плейсхолдерный/заменяемый: drop-in текстуры из `art/<key>.png`.
- [Формальные ADR — через /architecture-decision]

## Engine Specialists

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (все .gd)
- **Shader Specialist**: godot-shader-specialist (.gdshader, если понадобится «джус»)
- **UI Specialist**: godot-specialist (UI на Control, без отдельного спеца)
- **Additional Specialists**: godot-gdextension-specialist (только если потребуется нативный код)
- **Routing Notes**: primary — архитектура и кросс-ревью; gdscript-специалист — качество кода, сигналы, типизация.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd) | godot-gdscript-specialist |
| Shader / material (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen (Control, CanvasLayer) | godot-specialist |
| Scene / prefab / level (.tscn, .tres) | godot-specialist |
| Native extension / plugin (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
