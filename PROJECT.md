# Project: Shadow Cheat: Solo Guild Ascendance — UX, UI Containers, Dialogue System & Level Design Refactoring

## Architecture
- **Engine**: Godot 4.6.1 Stable (Forward Plus / 2D Pixel Art).
- **Display Resolution**: Base canvas 640x360 with window override 1280x720, pixel snapping enabled, Nearest texture filter, aspect locked to "keep" (`window/stretch/aspect="keep"`).
- **UI Architecture**: Component-driven responsive containers based on `godot-ui-containers` patterns (`MarginContainer` padding 16-24px, `HBoxContainer`, `VBoxContainer`, `PanelContainer`, full-screen `ColorRect` backdrop dimming with `mouse_filter = MOUSE_FILTER_STOP`, banner auto-hiding on modal open).
- **Dialogue Architecture**: Shared CanvasLayer bottom dialog box adhering to `godot-dialogue-system` (`Anchor Bottom Wide`, 32px lateral margins, 16px bottom margin, 80px height, typewriter effect, keyboard/action pagination).
- **Level Architecture**: Tile-based modular scenes using `assets/kenney_tiny_dungeon/` with strictly verified visual semantics (earthen soil, stepping stones, masonry walls, roofs, doors, furniture, props) respecting test invariants (`map_width = 640`, `map_height = 360`, `PerimeterBoundaries` StaticBody2D with >= 4 shapes).

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Viewport Aspect Keep | Add `window/stretch/aspect="keep"` in `project.godot` to eliminate asymmetric dead borders | M1 | Survey R1 |
| 2 | Camera2D Map Limits | Set limits on `Camera2D` in `greyrock_village.tscn` (0,0,640,360) and `arena.tscn` (-600,-400,600,400) | M1 | Survey R1 |
| 3 | Gacha Screen Container Refactor | Wrap in MarginContainer (16-24px), dark ColorRect overlay (0.65 alpha, mouse_filter=0), 10pt fonts, 165x205 cards | M2 | Survey R2 |
| 4 | Tavern Modal Responsive Cards | 3 mercenary cards in HBoxContainer (160x140), 10-11pt fonts, MarginContainer padding, eliminate horizontal overflow | M2 | Survey R2 |
| 5 | Quest Board Responsive Split | Missions list left (200px ScrollContainer), DetailPanel right with internal MarginContainer (10px), 10pt buttons | M2 | Survey R2 |
| 6 | Ending Screen Typography & Refs | Enforce mouse_filter=0, fix @onready lookups, standardize font sizes (10-12pt) | M2 | Survey R2 |
| 7 | Village Banner Collision Avoidance | Reorder HUD in tree and toggle HUD visibility when modals open/close | M2 | Survey R2 |
| 8 | Bottom Dialogue Box Component | Standalone `bottom_dialogue_box.tscn` with Anchor Bottom Wide (32px side, 16px bottom, ~80px height), dark panel, highlighted name | M3 | Survey R3 |
| 9 | NPC Dialogue Unification | Connect Madre Selene, Elena, and Barnaby to bottom dialogue box with pagination "[E] Continuar / Fechar" | M3 | Survey R3 |
| 10 | Greyrock Village Organic Layout | 4 distinct zones (Plaza, Guildhouse, Tavern, Shrine), houses with roofs/walls/doors, barrels, crates, tables, altars | M4 | Survey R4 |
| 11 | Arena Dungeon Flooring & Lighting | Replace blue grid with seamless stone floor (`tile_0037`), cracked stone border (`tile_0038`), perimeter walls, torches (`tile_0131`) | M5 | Survey R5 |
| 12 | Test Suite Pass & Zero Regressions | All 455 tests evaluated and passed (0 failures) via Godot 4.6.1 headless console runner + 43 dedicated UX tests | M6 | Survey Validation |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Viewport & Camera Limits | `project.godot`, `greyrock_village.tscn` Camera2D, `arena.tscn` Camera2D | none | DONE |
| M2 | Responsive UI Modals & Containers | `gacha_screen`, `tavern_recruit_modal`, `quest_board_modal`, `ending_screen`, banner collision | M1 | DONE |
| M3 | Classic RPG Bottom Dialogue Box | `bottom_dialogue_box` component, NPC integration (Madre Selene, Elena, Barnaby) | M1 | DONE |
| M4 | Greyrock Village Level Design | Full visual redesign of `greyrock_village.tscn` with 4 zones, houses, props, boundaries | M2, M3 | DONE |
| M5 | Arena Dungeon Stones & Atmosphere | Refactor `arena.tscn` with stone floors, perimeter masonry walls, torches, warm palette | M1 | DONE |
| M6 | Final Verification & E2E Validation | Run full 455-test suite, verify zero regressions, verify scene loading without errors | M1, M2, M3, M4, M5 | DONE |

## Interface Contracts
### `BottomDialogueBox` ↔ NPC / Village
- `show_dialogue(speaker_name: String, text_content: String, on_complete_callback: Callable = Callable()) -> void`
- `signal dialogue_finished()`
- Visual parameters: Anchor Bottom Wide, `offset_left = 32.0`, `offset_right = -32.0`, `offset_top = -96.0`, `offset_bottom = -16.0` (height 80px).
- Input: 'E' or UI click advances typewriter or triggers callback / dismisses.

### `ModalContainer` ↔ Village HUD
- Signal/event: `modal.visibility_changed` connected to `hub_hud.visible = not modal.visible`.

### Village Invariants (Test Suite M3 & Expansion)
- `village.map_width == 640.0`
- `village.map_height == 360.0`
- `village.find_child("PerimeterBoundaries") is StaticBody2D` with `>= 4` collision shapes.
- NPCs must retain node names `"Elena"`, `"Barnaby"`, `"MadreSelene"`.
- `selene.get_current_omen()` must return valid dictionary with `"type"` and `"text"`.

## Code Layout
- `project.godot` — Display settings and stretch configuration
- `scenes/ui/gacha_screen/gacha_screen.tscn` & `scripts/ui/gacha_screen.gd`
- `scenes/ui/modals/tavern_recruit_modal.tscn` & `scripts/ui/modals/tavern_recruit_modal.gd`
- `scenes/ui/modals/quest_board_modal.tscn` & `scripts/ui/modals/quest_board_modal.gd`
- `scenes/ui/ending_screen/ending_screen.tscn` & `scripts/ui/ending_screen.gd`
- `scenes/ui/dialogue/bottom_dialogue_box.tscn` & `scripts/ui/dialogue/bottom_dialogue_box.gd`
- `scenes/hub/greyrock_village.tscn` & `scripts/hub/greyrock_village.gd`
- `scenes/hub/npc_madre_selene.tscn` & `scripts/hub/npc_madre_selene.gd`
- `scenes/hub/npc_elena.tscn` & `scripts/hub/npc_elena.gd`
- `scenes/hub/npc_barnaby.tscn` & `scripts/hub/npc_barnaby.gd`
- `scenes/arena/arena.tscn` & `scripts/arena/arena.gd`
- `tests/test_ux_refactor_suite.gd`
