# TEST_READY — E2E Test Suite Readiness Report

**Project**: Shadow Cheat: Solo Guild Ascendance  
**Engine**: Godot 4.6.1 Stable Console (Windows x64)  
**Test Harness**: `tests/test_runner.gd` (SceneTree CLI runner)  
**Status**: READY FOR TESTING  

---

## 1. Execution Command

Run the complete headless E2E test suite via PowerShell:

```powershell
& "C:\Users\Rodrigo Brasil\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe" --headless --path . -s res://tests/test_runner.gd
```

### Exit Code Protocol:
- **`0`**: Success — all active assertions passed, zero failures.
- **`1`**: Failure — one or more assertions failed.

---

## 2. Test Files & Architecture

All test files are strictly isolated under `tests/` and do not modify production game logic:

1. **`tests/test_runner.gd`**:
   - Custom `SceneTree` driver with asynchronous tier sequencing.
   - Comprehensive assertion framework (`assert_true`, `assert_false`, `assert_eq`, `assert_ne`, `assert_almost_eq`, `assert_gt`, `assert_lt`).
   - Automated result tallying and detailed failure diagnostics.
   - Deterministic process termination via `quit(0)` or `quit(1)`.
2. **`tests/tier1_feature_tests.gd`**:
   - Tier 1 Feature Coverage: 100 test cases (5 per feature across all 20 features).
   - Validates happy-path logic, type contracts, properties, signals, and math formulas.
3. **`tests/tier2_boundary_tests.gd`**:
   - Tier 2 Boundary & Corner Cases: 100 test cases (5 per feature across all 20 features).
   - Validates limits, zero/negative inputs, deadzones, extreme values, and edge conditions.
4. **`tests/tier3_cross_feature_tests.gd`**:
   - Tier 3 Cross-Feature Interactions: 12 interaction test cases.
   - Validates pairwise delivery, physics collision masks, level-up pause transitions, and combat buff stacking.
5. **`tests/tier4_gameplay_scenarios.gd`**:
   - Tier 4 Real-World Gameplay Scenarios: 5 multi-tick simulation scenarios.
   - Validates full arena mounting, 180-tick combat simulation, full progression cycles, and stress teardown.

---

## 3. Test Count Summary

| Tier | Focus | Test Cases | Active in M1 |
|------|-------|------------|--------------|
| **Tier 1** | Feature Coverage (Unit / Functional) | 100 | Active for M1; pending M2–M5 |
| **Tier 2** | Boundary & Corner Cases (Limits / Extremes) | 100 | Active for M1; pending M2–M5 |
| **Tier 3** | Cross-Feature Interactions (Pairwise / States) | 12 | Active for M1 components; pending M2–M5 |
| **Tier 4** | Real-World Gameplay Scenarios (Headless Simulation) | 5 | Pending M5 arena integration |
| **Total** | Full Comprehensive E2E Suite | **217** | Progressive execution enabled |

---

## 4. Feature Coverage Checklist (PROJECT.md Inventory)

- [x] **Feature 1**: Pixel Art Project Config (M1) — Viewport 640x360, canvas_items stretch, nearest filter, twin-stick inputs
- [x] **Feature 2**: Collision Layer Matrix (M1) — 7 designated physics layers & friendly fire masks
- [x] **Feature 3**: Core Combat Data & Components (M1) — DamageData bitflags & HealthComponent with i-frames
- [x] **Feature 4**: Batch-Safe Hit Flash Shader (M1) — instance uniform flash_modifier & canvas_item shader
- [x] **Feature 5**: Protagonist 8-Way Movement (M2) — Floating motion mode, 150 px/s normalized vector
- [x] **Feature 6**: Tactical Dash with i-frames (M2) — 400 px/s, 0.20s duration, 1.0s cooldown, invulnerability
- [x] **Feature 7**: Mouse-Aimed Shadow Blades (M2) — 380 px/s, 20 dmg, 0.35s cd, pierce logic
- [x] **Feature 8**: Companion AI Follow & Leash (M3) — 70 px follow, 130 px/s spd, 180 px sprint leash
- [x] **Feature 9**: Spatial Cluster Targeting (M3) — 240 px sensing, density focal point heuristic
- [x] **Feature 10**: Companion Fireball Spell (M3) — 35 dmg, 48 px AoE splash, 220 px/s, 2.2s cd
- [x] **Feature 11**: Companion Ice Spikes Spell (M3) — 16 dmg, 64 px ground AoE, 50% slow for 2.5s, 4.5s cd
- [x] **Feature 12**: Enemy Variety & Behaviors (M4) — Slime, Bat (wobble), Skeleton stat blocks & groups
- [x] **Feature 13**: Escalating Horde Waves (M4) — 3.0s bursts, 80-mob concurrency cap, wave schedule
- [x] **Feature 14**: Enemy Hit Feedback & Death Flow (M4) — Flash tween, knockback impulse, death collider disable, XP drop
- [x] **Feature 15**: Magnetic XP Orbs (M4) — 60 px magnet radius, 600 px/s² accel, 450 px/s max speed
- [x] **Feature 16**: XP Level-Up Curve (M5) — floor(50 * 1.35^(level-1)) curve & overflow preservation
- [x] **Feature 17**: Tree Pause & Gacha Modal (M5) — SceneTree pause, PROCESS_MODE_ALWAYS, unpause on pick
- [x] **Feature 18**: Weighted Card Draw (M5) — 3 distinct cards, R:60%, SR:25%, SSR:12%, EX:3%
- [x] **Feature 19**: 10-Card Upgrade Catalog (M5) — 10 distinct upgrade cards & stat modifiers
- [x] **Feature 20**: Main Arena & HUD Integration (M5) — arena.tscn, Camera2D, HUD bars, clean teardown

---

## 5. Progressive Testability Verification

The test suite implements progressive testability:
- Features belonging to completed milestones (currently M1) execute genuine assertions immediately against real engine nodes, settings, and components.
- Features belonging to upcoming milestones (M2 through M5) are detected via dynamic resource checks. Missing scripts/scenes are logged as `[SKIP] (Pending M#)` without crashing the harness.
- As upcoming milestones are implemented by milestone workers, the corresponding tests automatically activate and grade the implementations.
