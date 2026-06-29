# Timokha Escape — проект игры (под управлением CCGS)

Казуальный **квест-приключение** на **Godot 4.7 / GDScript** для iOS+Android.
**Оммаж/пародия** в духе жанра «Побег от …» (мем-игры): игрок убегает от
шалуна-антагониста, проходит мини-игры (готовка, поручения) и головоломки,
цель — сбежать. **Все ассеты оригинальные/плейсхолдерные** — это не копия
чужой игры, а самостоятельная работа в том же жанре.

## Статус
- Стадия: **Playable MVP** (production/polish). Пайплайн CCGS пройден целиком.
- Готово: концепт, арт-байбл, систем-индекс, GDD, архитектура+ADR, control-manifest, бэклог;
  **играбельная игра** (4 главы, постоянная погоня, 3 мини-игры, побег, прогресс+сейв);
  тесты 21 юнит + 14 интеграц. зелёные; smoke-check PASS.
- Точка входа: `scenes/main.tscn` → `scripts/main.gd`. Автозагрузки: GameData, GS, Sfx, Music.
- Следующее: реальный арт/звук (drop-in `art/`), туториал, настройки, локализация,
  экспорт iOS/Android (`docs/launch-notes.md`), `/security-audit` сейва.

## Технологический стек
- **Engine**: Godot 4.7 · **Language**: GDScript · **Rendering**: Mobile / 2D
- **Source layout (НЕ src/)**: код в `scripts/`, сцены в `scenes/`, арт в `art/`, утилиты в `tools/`
- Точка входа (план): `scenes/main.tscn`.

## Engine Version Reference
@docs/engine-reference/godot/VERSION.md

## Project Structure
@.claude/docs/directory-structure.md

## Технические настройки проекта
@.claude/docs/technical-preferences.md

## Coordination Rules
@.claude/docs/coordination-rules.md

## Coding Standards
@.claude/docs/coding-standards.md

## Context Management
@.claude/docs/context-management.md

## Collaboration Protocol
**Совместная работа, управляемая пользователем, а не автономное исполнение.**
Каждая задача: **Вопрос → Варианты → Решение → Черновик → Одобрение**.
- Перед записью важных изменений — спрашивать/показывать намерение.
- Без коммитов без указания пользователя.

## Правовая заметка
Игра — самостоятельный оммаж жанру, без использования чужих ассетов, имён-брендов
и исходников. Имена персонажей и визуал — оригинальные/обезличенные плейсхолдеры.
