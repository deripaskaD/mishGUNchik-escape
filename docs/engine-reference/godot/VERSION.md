# Godot — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | 4.7 (stable) |
| **Released** | 2026-06-18 |
| **Project Pinned** | 2026-06-24 |
| **Language** | GDScript |
| **LLM Knowledge Cutoff** | ~January 2026 |
| **Risk Level** | MEDIUM-HIGH — 4.7 released after the LLM training cutoff |
| **Last Docs Verified** | 2026-06-24 |

## Why this matters

Godot 4.7 stable shipped on 2026-06-18, after the assistant's training cutoff.
Agents must verify uncertain 4.7 APIs via WebSearch / the official docs rather
than relying on memory, especially for new 4.7-only features.

Official references:
- Release notes: https://godotengine.org/releases/4.7/
- Interactive changelog: https://godotengine.github.io/godot-interactive-changelog/
- Migration checklist: https://godotlearning.com/blog/godot-4-7-upgrade-checklist

## Breaking changes (4.6 → 4.7) relevant to this project

This project is **2D, mobile (iOS+Android), GDScript**. Of the called-out 4.7
compatibility breaks:

| Breaking change | Affects us? | Note |
|-----------------|-------------|------|
| Android legacy **OBB** export format changed | **YES (at export)** | Re-check Android export preset before first store build; use current APK/AAB packaging, not legacy OBB. |
| **BlendSpace** points handling (AnimationTree) | Maybe (later) | Only if we use AnimationTree blend spaces. Our 2D mini-game animations likely use AnimationPlayer/sprite frames — low impact at MVP. |
| 3D custom shader preprocessor macros | **NO** | Project is 2D; no 3D shaders. |

## Stance

- 2D / mobile core APIs in 4.7 remain compatible with 4.x — safe to build on.
- Verify any **new 4.7-specific** feature against official docs before relying on it.
- Re-run `/setup-engine refresh` if upgrading past 4.7 or if a 4.7.x patch lands.
