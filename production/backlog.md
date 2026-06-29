# Backlog — Timokha Escape

*Solo · 2026-06-24. Эпики → истории. Статусы обновляются по ходу реализации.*

## EPIC-MVP — Играбельный кор-луп «погоня + мини-игры + побег»
Governing ADRs: 0001–0007. GDD: pursuer-ai, minigame-engine, quest-chain, game-concept.

| ID | История | Система | Тип | Статус | Тест-эвиденс |
|----|---------|---------|-----|--------|--------------|
| S01 | Автозагрузки: GameData (данные глав/тюнинг) | App & State | Logic | Done | run_tests |
| S02 | Автозагрузка GS: состояние, прогрессия, save/load | App & State / Persistence | Logic | Done | run_tests (save) |
| S03 | Аудио-заглушки Sfx/Music (no-op толерантные) | Audio | Config | Done | smoke |
| S04 | MinigameBase + звёзды | Minigame Engine | Logic | Done | run_tests (scoring) |
| S05 | Мини-игры: pies / tea / wood | Minigame Engine | Logic | Done | run_tests |
| S06 | QuestManager: цепочка задач + итоговые звёзды | Quest Chain | Logic | Done | run_tests |
| S07 | Pursuer: преследование, телеграф, рывок, поимка | Pursuer AI | Logic | Done | run_tests (step/catch) |
| S08 | World: движение, ввод, симуляция, _draw, побег | Movement/Hotspot/Escape/Juice | Integration | Done | smoke/playtest |
| S09 | HUD в World: задача, прогресс, звёзды, метрики | HUD | UI | Done | smoke |
| S10 | Main: меню / выбор глав / результаты, переходы | UI/Flow | UI | Done | smoke |
| S11 | Контент: 3 главы (Кухня/Двор/Причал) | Content | Config | Done | smoke |
| S12 | Тест-харнесс tests/run_tests.gd | Testing | Logic | Done | self |

## EPIC-VS (Vertical Slice) — полировка одной главы
- Результаты-экран со звёздами, разблокировка следующей главы, сохранение — включено в MVP (S02/S10).
- Доп. «джус» (вспышки/тряска/частицы), мем-реплики — частично (S08).

## Дальнейшее (Alpha/Full Vision)
- Туториал/онбординг, настройки, локализация-хуки, больше мини-игр и глав, реальный арт/звук.
