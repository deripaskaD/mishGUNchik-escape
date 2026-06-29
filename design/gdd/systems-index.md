# Systems Index: Timokha Escape

> **Status**: Draft
> **Created**: 2026-06-24
> **Last Updated**: 2026-06-24
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Timokha Escape — казуальный квест-комедия **с постоянной погоней**: шалун всё время
гонится за игроком по локации, а тот свободно перемещается, добегает до «горячих
точек» и проходит короткие мини-игры (у точки погоня паузится/замедляется), выполняя
цепочку поручений к финальному рывку-побегу. Механический костяк: **свободное движение
под тач** + **Pursuer AI** (преследователь) + **движок мини-игр** (общий, расширяемый)
+ **квест-цепочка** + **«джус»-обратная связь**. Всё подчинено пилларам *Юмор превыше
всего*, *Понятно с первого касания*, *Цепочка поручений*, *Карманные сессии* и
анти-пилларам *НЕ хоррор* / *НЕ хардкорные тайминги*.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | App & Game State (autoloads GameData/GS) | Core | MVP | Not Started | — | — |
| 2 | Input & Touch Controls (inferred) | Core | MVP | Not Started | — | App & Game State |
| 3 | Location & Bounds (сцена + clamp_move) | Core | MVP | Not Started | — | App & Game State |
| 4 | Player Movement & Camera | Gameplay | MVP | Not Started | — | Input, Location & Bounds |
| 5 | Hotspot / Interaction System | Gameplay | MVP | Not Started | — | Player Movement, Location & Bounds |
| 6 | Minigame Engine (MinigameBase + звёзды) | Gameplay | MVP | Not Started | — | Input, App & Game State |
| 7 | **Pursuer AI** (постоянная погоня) | Gameplay | MVP | Not Started | — | Player Movement, Location & Bounds |
| 8 | Quest Chain / Task Manager | Gameplay | MVP | Not Started | — | Minigame Engine, Hotspot |
| 9 | Escape Sequence (финальный рывок) | Gameplay | MVP | Not Started | — | Player Movement, Pursuer AI, Quest Chain |
| 10 | Juice / Feedback (inferred) | UI | MVP | Not Started | — | большинство gameplay-систем |
| 11 | HUD / UI (задача, звёзды, телеграф погони, пауза) (inferred) | UI | MVP (min) → VS | Not Started | — | Quest Chain, Minigame Engine, Pursuer AI |
| 12 | Audio (SFX/Music autoloads) (inferred) | Audio | MVP (min) → VS | Not Started | — | App & Game State |
| 13 | Meme-line / Dialogue popups (inferred) | Narrative | Vertical Slice | Not Started | — | HUD / UI |
| 14 | Save / Progression & Chapter Flow (inferred) | Persistence | Vertical Slice | Not Started | — | App & Game State, Quest Chain |
| 15 | Results / Star Screen (inferred) | UI | Vertical Slice | Not Started | — | Minigame Engine, HUD / UI |
| 16 | Tutorial / Onboarding (inferred) | Meta | Alpha | Not Started | — | большинство MVP-систем |
| 17 | Settings / Options (inferred) | Meta | Alpha | Not Started | — | App & Game State, Audio |
| 18 | Localization (RU-first, хуки) (inferred) | Meta | Full Vision | Not Started | — | HUD / UI, Dialogue |

---

## Priority Tiers

| Tier | Definition | Target Milestone |
|------|------------|------------------|
| **MVP** | Кор-луп «бегай от шалуна + мини-игры + побег» работает и его можно тестировать на «весело ли» | Первый играбельный прототип |
| **Vertical Slice** | Одна полная отполированная глава с прогрессией и сохранением | Демо/слайс |
| **Alpha** | Все системы вчерне, плейсхолдер-контент | Альфа |
| **Full Vision** | Полировка, локализация, мета | Бета/релиз |

---

## Dependency Map

### Foundation Layer (no dependencies)
1. **App & Game State** — синглтоны данных/состояния (GameData/GS); от него зависит всё.

### Core Layer (depends on foundation)
1. **Input & Touch Controls** — depends on: App & Game State.
2. **Location & Bounds** — depends on: App & Game State. (границы сцены, clamp движения)
3. **Audio** — depends on: App & Game State.

### Feature Layer (depends on core)
1. **Player Movement & Camera** — depends on: Input, Location & Bounds.
2. **Hotspot / Interaction System** — depends on: Player Movement, Location & Bounds.
3. **Minigame Engine** — depends on: Input, App & Game State.
4. **Pursuer AI** — depends on: Player Movement, Location & Bounds.
5. **Quest Chain / Task Manager** — depends on: Minigame Engine, Hotspot.
6. **Escape Sequence** — depends on: Player Movement, Pursuer AI, Quest Chain.
7. **Save / Progression & Chapter Flow** — depends on: App & Game State, Quest Chain.
8. **Meme-line / Dialogue** — depends on: HUD / UI.

### Presentation Layer (wraps gameplay)
1. **Juice / Feedback** — depends on: Player Movement, Minigame Engine, Pursuer AI.
2. **HUD / UI** — depends on: Quest Chain, Minigame Engine, Pursuer AI.
3. **Results / Star Screen** — depends on: Minigame Engine, HUD / UI.

### Polish Layer (depends on everything)
1. **Tutorial / Onboarding** — depends on: MVP-системы.
2. **Settings / Options** — depends on: App & Game State, Audio.
3. **Localization** — depends on: HUD / UI, Dialogue.

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | App & Game State | MVP | Foundation | game-designer / godot-specialist | S |
| 2 | Input & Touch Controls | MVP | Core | game-designer | S |
| 3 | Location & Bounds | MVP | Core | game-designer | S |
| 4 | Player Movement & Camera | MVP | Feature | game-designer | S |
| 5 | Hotspot / Interaction System | MVP | Feature | game-designer | S |
| 6 | **Minigame Engine** | MVP | Feature | systems-designer | M (bottleneck) |
| 7 | **Pursuer AI** | MVP | Feature | ai-programmer / systems-designer | M (high-risk) |
| 8 | Quest Chain / Task Manager | MVP | Feature | systems-designer | M |
| 9 | Escape Sequence | MVP | Feature | game-designer | S |
| 10 | Juice / Feedback | MVP | Presentation | technical-artist | M |
| 11 | HUD / UI | MVP→VS | Presentation | ux-designer / ui | M |
| 12 | Audio | MVP→VS | Core | audio-director | S |
| 13 | Save / Progression & Chapter Flow | VS | Feature | systems-designer | M |
| 14 | Results / Star Screen | VS | Presentation | ux-designer | S |
| 15 | Meme-line / Dialogue | VS | Feature | writer | S |
| 16 | Tutorial / Onboarding | Alpha | Polish | ux-designer | S |
| 17 | Settings / Options | Alpha | Polish | ux-designer | S |
| 18 | Localization | Full Vision | Polish | localization-lead | M |

*Effort: S = 1 сессия, M = 2-3 сессии, L = 4+.*

---

## Circular Dependencies

- **Quest Chain ↔ Minigame Engine** — выглядит цикличным (квест запускает мини-игру; мини-игра рапортует результат квесту), но **разрешено через сигналы**: Minigame Engine эмитит `minigame_finished(result)`, Quest Chain подписан; прямых вызовов в обе стороны нет. Контракт: Quest вызывает `start(minigame_id)`, слушает сигнал.
- **Pursuer AI ↔ Hotspot/Minigame** — Pursuer «паузится/замедляется» у активной точки. Разрешено через сигнал состояния (`hotspot_engaged` / `minigame_active`) — Pursuer лишь читает флаг, не зависит от внутренностей мини-игры.
- Иных циклов не найдено.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|------------------|------------|
| **Pursuer AI** | Design / Feel | Главная новая механика. Слишком «липкий» → фрустрация и конфликт с анти-пилларом *НЕ хардкорные тайминги*; слишком вялый → угроза не ощущается | Прототипировать рано; прощающая скорость, телеграф рывков, tuning knobs; плейтест |
| **Minigame Engine** | Scope / Technical | Абстракция слишком жёсткая (дорого добавлять) или слишком рыхлая | Прототип с 2-3 непохожими мини-играми до фиксации интерфейса `MinigameBase` |
| **Movement + chase feel (touch)** | Feel | Уворачиваться пальцем в ландшафте должно быть отзывчиво | Прототип управления; калибровка зоны джойстика; плейтест на устройстве |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 18 |
| Design docs started | 0 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 0 / 11 |
| Vertical Slice systems designed | 0 / 4 |

*(MVP-системы: #1-10 + #11/#12 в минимальном виде. VS добавляет #13-15 и полный HUD/Audio.)*

---

## Next Steps

- [ ] Утвердить эту декомпозицию
- [ ] Проектировать MVP-системы по порядку (`/design-system [system]`), начиная с #1
- [ ] **Рано** прототипировать high-risk: Pursuer AI + Minigame Engine (`/prototype`)
- [ ] `/design-review` на каждый готовый GDD
- [ ] `/gate-check pre-production` когда MVP-системы спроектированы
