# Test Infrastructure Specification: Shadow Cheat: Solo Guild Ascendance

## 1. Overview & Architectural Principles

This document defines the End-to-End (E2E) automated testing infrastructure for *Shadow Cheat: Solo Guild Ascendance* (Godot 4.6.1 Action Roguelike / Twin-Stick Survivors 2D).

### Core Principles:
1. **Opaque-Box Requirement Derivation**:
   Every test case is derived strictly from authoritative requirements in `ORIGINAL_REQUEST.md` (R1–R5, Acceptance Criteria) and architectural contracts in `PROJECT.md` (§ Feature Inventory, § Interface Contracts). Tests verify observable outputs and behaviors rather than internal implementation quirks.
2. **Progressive Testability**:
   The test suite supports incremental milestone delivery (M1 through M5). Tests dynamically inspect whether required target scenes and scripts exist. If a milestone dependency is pending, the test logs a clear `[SKIP]` with the missing milestone dependency rather than crashing the harness. As milestone workers deliver code, corresponding tests automatically transition from `SKIP` to active execution.
3. **No Facade / Zero Cheating Integrity**:
   No test is allowed to pass unconditionally. All active tests perform genuine assertions against actual Godot nodes, physics bodies, resources, math curves, and state machines. If an implementation is flawed or missing expected behavior, the test fails deterministically.
4. **Deterministic Headless Execution**:
   The suite runs via the Godot console executable in `--headless` mode. The harness (`tests/test_runner.gd`) extends `SceneTree`, executes asynchronous test tiers, and terminates with a clean exit code: `0` on all tests passed/skipped, `1` if any test assertion fails.

---

## 2. Test Execution Command

The test suite can be run from PowerShell or any command-line interface using:

```powershell
& "C:\Users\Rodrigo Brasil\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe" --headless --path . -s res://tests/test_runner.gd
```

### Exit Codes:
- `0`: All executed tests passed, zero failures.
- `1`: One or more test assertions failed.

---

## 3. Test Tier Hierarchy & Coverage Matrix

The suite is structured into four progressive tiers across four dedicated test files:

```
tests/
├── test_runner.gd                 # Main SceneTree harness & CLI runner
├── tier1_feature_tests.gd         # Tier 1: Feature Coverage (100 tests, 5 per feature)
├── tier2_boundary_tests.gd        # Tier 2: Boundary & Corner Cases (100 tests, 5 per feature)
├── tier3_cross_feature_tests.gd   # Tier 3: Cross-Feature Interactions (12 tests)
└── tier4_gameplay_scenarios.gd    # Tier 4: Real-World Gameplay Scenarios (5 tests)
```

### Feature Inventory Mapping (20 Features × 5 Tests/Tier = 200 Tests for Tiers 1 & 2):

| # | Feature Name | Milestone | Tier 1 (Coverage) | Tier 2 (Boundaries) | Authoritative Source |
|---|--------------|-----------|-------------------|---------------------|----------------------|
| 1 | Pixel Art Project Config | M1 | Viewport, stretch, filter, inputs (5) | Zero scale, aspect extremes, input cancellation (5) | R1 / PROJECT.md F1 |
| 2 | Collision Layer Matrix | M1 | 7 designated layers & bitmasks (5) | Layer masks, friendly fire filter, drop mask (5) | R1 / PROJECT.md F2 |
| 3 | Core Combat Data & Components | M1 | DamageData types, HealthComponent HP & signals (5) | Zero damage, overkill, negative damage, i-frames (5) | R1 / PROJECT.md F3 |
| 4 | Batch-Safe Hit Flash Shader | M1 | Shader exists, uniform names, canvas_item type (5) | Flash modifier clamp, alpha preservation, tweens (5) | R1/R4 / PROJECT.md F4 |
| 5 | Protagonist 8-Way Movement | M2 | Locomotion, diagonal normalization, floating mode (5) | Subpixel move, delta spikes, wall slide, speed buffs (5) | R2 / PROJECT.md F5 |
| 6 | Tactical Dash with i-frames | M2 | Dash speed, duration, cooldown, invulnerability (5) | Zero-vector dash, double-dash, cooldown gate, walls (5) | R2 / PROJECT.md F6 |
| 7 | Mouse-Aimed Shadow Blades | M2 | Projectile speed, DamageData, cooldown, pierce (5) | Zero-distance aim, spam clicks, pierce count, walls (5) | R2 / PROJECT.md F7 |
| 8 | Companion AI Follow & Leash | M3 | Follow distance, speed, sprint leash, separation (5) | Zero-dist overlap, extreme distance, null player (5) | R3 / PROJECT.md F8 |
| 9 | Spatial Cluster Targeting | M3 | Sensing radius, cluster focal point, closest fallback (5) | Zero enemies, dead enemies, tied clusters, 80 mobs (5) | R3 / PROJECT.md F9 |
| 10 | Companion Fireball Spell | M3 | Damage, AoE radius, speed, cooldown, impact (5) | Zero radius, max clustered hits, recast gate, bounds (5) | R3 / PROJECT.md F10 |
| 11 | Companion Ice Spikes Spell | M3 | Damage, AoE radius, slow factor, duration, cd (5) | Slow stacking, duration expiry, instant ground place (5) | R3 / PROJECT.md F11 |
| 12 | Enemy Variety & Behaviors | M4 | Slime, Bat, Skeleton stat blocks & wobbles (5) | Knockback resistance, 0 HP spawn block, dead target (5) | R4 / PROJECT.md F12 |
| 13 | Escalating Horde Waves | M4 | 3.0s interval, 80-mob cap, wave compositions (5) | Cap block, partial headroom, spawn outside camera (5) | R4 / PROJECT.md F13 |
| 14 | Enemy Hit Feedback & Death Flow | M4 | Hit flash, knockback impulse, death collider, drop (5) | Dual lethal hits, wall knockback, death hit cleanup (5) | R4 / PROJECT.md F14 |
| 15 | Magnetic XP Orbs | M4 | 60px magnet, 600 px/s² accel, 450 px/s cap, pickup (5) | Outside radius, player dash lead, 100 orbs stress (5) | R4 / PROJECT.md F15 |
| 16 | XP Level-Up Curve | M5 | Level 1-5 costs ($50 \times 1.35^{L-1}$), overflow math (5) | Multi-level burst, exact threshold, negative XP (5) | R5 / PROJECT.md F16 |
| 17 | Tree Pause & Gacha Modal | M5 | SceneTree pause, process_mode ALWAYS, unpause (5) | World input swallowing, queued levels, unpause safety (5) | R5 / PROJECT.md F17 |
| 18 | Weighted Card Draw | M5 | 3 cards, distinct selection, R/SR/SSR/EX weights (5) | Draw > pool, 1 card draw, empty pool, seed stability (5) | R5 / PROJECT.md F18 |
| 19 | 10-Card Upgrade Catalog | M5 | Catalog size, 10 distinct card buff applications (5) | EX Dimension Cleaver, EX Cataclysm, Blade Flurry (5) | R5 / PROJECT.md F19 |
| 20 | Main Arena & HUD Integration | M5 | Scene loading, node graph, camera, HUD bars, main scene (5) | Boundary walls, HUD updates on damage/XP, cleanup (5) | R1/R5 / PROJECT.md F20 |

---

## 4. Tier 3: Cross-Feature Interaction Tests

Tier 3 verifies emergent behaviors and cross-system integration contracts:
1. `T3.01: Shadow Blade Hitbox -> Slime Hurtbox Delivery & Hit Flash` (F7 + F12 + F2 + F4)
2. `T3.02: Shadow Blade Pierce -> Skeleton Damage & Despawn` (F7 + F12 + F3)
3. `T3.03: Lethal Enemy Damage -> Collider Disable & XP Orb Drop` (F7 + F12 + F14 + F15)
4. `T3.04: Player Proximity -> XP Orb Magnet Acceleration & Collection` (F5 + F15 + F16)
5. `T3.05: XP Threshold Reached -> Level Up Event -> SceneTree Pause & Gacha Modal` (F16 + F17 + F18)
6. `T3.06: Gacha Modal Card Selection -> Stat Buff Applied & SceneTree Unpause` (F17 + F18 + F19)
7. `T3.07: Tactical Dash -> Invulnerability Window -> Enemy Contact Damage Immunity` (F6 + F12 + F3)
8. `T3.08: Enemy Cluster Formation -> Companion Cluster Targeting -> Fireball AoE Splash` (F8 + F9 + F10 + F12)
9. `T3.09: Bat High-Speed Chase -> Ice Spikes Ground Cast -> 50% Speed Slow Applied` (F11 + F12 + F8)
10. `T3.10: Active Enemy Saturation (75 Mobs) -> WaveManager Burst Respects 80 Cap` (F13 + F12)
11. `T3.11: Protagonist Dash Evade -> Companion Sprint-Leash Reposition Trigger` (F5 + F6 + F8)
12. `T3.12: Keen Obsidian Edge Card Buff -> Shadow Blade Damage Scaling in Combat` (F19 + F7 + F3)

---

## 5. Tier 4: Real-World Gameplay Scenarios

Tier 4 tests execute multi-tick simulations of the full game environment:
1. `T4.01: Arena Scene Initialization & Subsystem Mounting`: Loads `arena.tscn`, verifies all nodes (Player, CompanionMage, WaveManager, HUD, TileMap) mount and link correctly.
2. `T4.02: Multi-Tick Combat & Spawner Loop (180 Physics Ticks)`: Simulates 3.0s of real-time top-down combat with active inputs, enemy tracking, and blade casting.
3. `T4.03: Complete Progression Loop (Kill -> Drop -> Magnet -> Level Up -> Gacha Pick -> Resume)`: Executes an end-to-end user journey through a complete progression cycle.
4. `T4.04: Escalating Wave Survival Run (300 Physics Ticks)`: Runs extended survival across wave boundaries, verifying mob escalation and bat spawning.
5. `T4.05: High-Density Horde Stress & Clean Scene Tree Teardown`: Simulates 40 concurrent active entities, validates frame time and memory stability, and ensures zero orphaned nodes on free.

---

## 6. Progressive Testability Implementation Specification

To maintain continuous verification across project milestones without parse errors:
- Test files dynamically query `ResourceLoader.exists()` or `load()` before accessing uninstantiated classes.
- If a target script or scene is missing, `runner.record_skip(test_name, reason)` is called.
- When target scripts exist, full behavioral assertions execute immediately.
- A run with skipped milestone tests and zero assertion failures exits with code `0`. Any assertion failure immediately sets the exit code to `1`.
