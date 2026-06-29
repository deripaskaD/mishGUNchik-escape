---
name: project-emerald-islands
description: Core context about the Emerald Islands game project for UX decisions
metadata:
  type: project
---

Мобильная аниме-RPG «Изумрудные Острова» (Godot 4.7 / GDScript). Платформа: iOS + Android, ландшафтная ориентация.

**Why:** Двойной геймплей суша+море (референс Florensia) — ключевой дифференциатор. Это brownfield-проект в стадии polish.

**How to apply:** Все UX-решения должны учитывать тач как основной ввод, 10–30-минутные мобильные сессии и поддерживать двойной режим (суша HUD / море HUD). 4 класса (Наёмник, Дворянин, Святая, Следопыт). Аудитория: casual/mid-core, 16–35 лет. Тон — светлое аниме-приключение, не мрачный.

Существующий UI: HUD с полосками ЗД/Маны, строка квеста, миникарта, скиллбар, кнопки Сумка/Таланты/Умения/Дела/Крафт. Тач-геймпад (джойстик + кнопки, touch_controls.gd). Диалоги NPC. Всё собрано кодом на Godot Control/CanvasLayer.

Созданные UX-спеки: [[ux-files-index]]
