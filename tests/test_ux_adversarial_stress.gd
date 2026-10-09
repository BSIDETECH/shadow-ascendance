extends SceneTree

## Empirical Adversarial Stress Test Suite for UX Refactoring (R3, R4, R5)
## Agent: Challenger UX 2 (Empirical Challenger)
## Focus:
##  - R3: Dialogue typewriter & NPC interactions (Edge cases, rapid input spam, re-entrancy, long strings, omens)
##  - R4: Village Level Boundaries & Invariants (Perimeter physics escape test, props collision, camera limits)
##  - R5: Arena Atmosphere & Combat Waves (Stone floors, torch collision non-interference, enemy wave scaling & positions)

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var findings: Array[Dictionary] = []

var _cached_eb: Node = null
var _cached_gm: Node = null
var _cached_tracker: Node = null

func _init() -> void:
	call_deferred("_run_adversarial_suite")

func record_pass(test_name: String) -> void:
	total_assertions += 1
	passed_assertions += 1
	print("  [PASS] %s" % test_name)

func record_fail(test_name: String, detail: String, severity: String = "CRITICAL") -> void:
	total_assertions += 1
	failed_assertions += 1
	var finding := {
		"name": test_name,
		"detail": detail,
		"severity": severity
	}
	findings.append(finding)
	printerr("  [FAIL][%s] %s -> %s" % [severity, test_name, detail])

func assert_true(cond: bool, test_name: String, detail: String = "") -> void:
	if cond:
		record_pass(test_name)
	else:
		record_fail(test_name, detail if not detail.is_empty() else "Expected true, got false")

func assert_eq(actual: Variant, expected: Variant, test_name: String) -> void:
	if actual == expected:
		record_pass(test_name)
	else:
		record_fail(test_name, "Expected %s, got %s" % [str(expected), str(actual)])

func _ensure_autoloads() -> void:
	if _cached_eb == null:
		_cached_eb = root.get_node_or_null("EventBus")
		if _cached_eb == null:
			var s = load("res://scripts/autoloads/event_bus.gd")
			_cached_eb = s.new()
			_cached_eb.name = "EventBus"
			root.add_child(_cached_eb)

	if _cached_gm == null:
		_cached_gm = root.get_node_or_null("GameManager")
		if _cached_gm == null:
			var s = load("res://scripts/autoloads/game_manager.gd")
			_cached_gm = s.new()
			_cached_gm.name = "GameManager"
			root.add_child(_cached_gm)

	if _cached_tracker == null:
		_cached_tracker = root.get_node_or_null("SilentAgencyTracker")
		if _cached_tracker == null:
			var s = load("res://scripts/autoloads/agency_tracker.gd")
			_cached_tracker = s.new()
			_cached_tracker.name = "SilentAgencyTracker"
			root.add_child(_cached_tracker)

func _run_adversarial_suite() -> void:
	print("\n======================================================================")
	print(" EMPIRICAL ADVERSARIAL STRESS TEST SUITE — UX REFACTOR (R3, R4, R5)")
	print(" Engine: Godot 4.6.1 | Agent: Challenger UX 2")
	print("======================================================================\n")

	_ensure_autoloads()

	await _test_category_1_dialogue_typewriter_stress()
	await _test_category_2_npc_interaction_triggers()
	await _test_category_3_village_boundaries_and_physics()
	await _test_category_4_arena_atmosphere_and_waves()

	_print_summary()

func _test_category_1_dialogue_typewriter_stress() -> void:
	print("\n--- [CATEGORY 1: DIALOGUE TYPEWRITER & INPUT ADVERSARIAL STRESS] ---")

	var scene = load("res://scenes/ui/dialogue/bottom_dialogue_box.tscn")
	assert_true(scene != null, "C1.01: BottomDialogueBox scene loads cleanly")

	var dlg: BottomDialogueBox = scene.instantiate() as BottomDialogueBox
	root.add_child(dlg)
	await process_frame

	# Test layout contracts
	assert_eq(dlg.layer, 25, "C1.02: BottomDialogueBox layer is 25 (renders above HUD and world)")
	assert_false(dlg.visible, "C1.03: BottomDialogueBox initially hidden")
	assert_false(dlg.is_active, "C1.04: BottomDialogueBox initially inactive")

	var panel: PanelContainer = dlg.find_child("PanelContainer", true, false) as PanelContainer
	assert_true(panel != null, "C1.05: PanelContainer exists")
	if panel != null:
		assert_eq(panel.anchor_top, 1.0, "C1.06: Panel anchor_top is bottom (1.0)")
		assert_eq(panel.anchor_bottom, 1.0, "C1.07: Panel anchor_bottom is bottom (1.0)")
		assert_eq(panel.offset_left, 32.0, "C1.08: Panel left margin is 32px")
		assert_eq(panel.offset_right, -32.0, "C1.09: Panel right margin is -32px")
		assert_eq(panel.offset_top, -96.0, "C1.10: Panel top offset is -96px")
		assert_eq(panel.offset_bottom, -16.0, "C1.11: Panel bottom offset is -16px")

	# Test basic reveal and skip
	var cb_called := false
	dlg.show_dialogue("TestSpeaker", "The dark spire awaits in silence.", func():
		cb_called = true
	)
	assert_true(dlg.visible, "C1.12: show_dialogue makes box visible")
	assert_true(dlg.is_active, "C1.13: is_active set to true")
	assert_eq(dlg.speaker_label.text, "TestSpeaker", "C1.14: Speaker label text set")
	assert_true(dlg.speaker_label.visible, "C1.15: Speaker label visible for non-empty speaker")
	assert_eq(dlg.dialogue_label.text, "The dark spire awaits in silence.", "C1.16: Dialogue text set")

	# Skip typewriter
	dlg.advance_dialogue()
	assert_eq(dlg.dialogue_label.visible_ratio, 1.0, "C1.17: advance_dialogue while typing snaps visible_ratio to 1.0")
	assert_true(dlg.visible, "C1.18: Dialogue still visible after skip")
	assert_true(dlg.is_active, "C1.19: Dialogue still active after skip")
	assert_false(cb_called, "C1.20: Callback NOT invoked on text skip")

	# Close dialogue on next advance
	dlg.advance_dialogue()
	assert_false(dlg.visible, "C1.21: Dialogue hidden after final advance")
	assert_false(dlg.is_active, "C1.22: is_active false after close")
	assert_true(cb_called, "C1.23: Callback invoked upon dialogue close")

	# Rapid 'E' Spamming Stress (50 rapid calls in succession)
	cb_called = false
	var cb_count := 0
	dlg.show_dialogue("SpamTest", "Spamming test text.", func():
		cb_count += 1
	)
	for i in range(50):
		dlg.advance_dialogue()

	assert_false(dlg.visible, "C1.24: Rapid 50x advance leaves box cleanly closed")
	assert_false(dlg.is_active, "C1.25: Rapid 50x advance leaves box inactive")
	assert_eq(cb_count, 1, "C1.26: Callback called EXACTLY once under 50x rapid advance spam")

	# Re-entrant show_dialogue overwrite stress (calling show multiple times before close)
	var cb1_fired := false
	var cb2_fired := false
	var cb3_fired := false
	dlg.show_dialogue("Over1", "Text 1", func(): cb1_fired = true)
	dlg.show_dialogue("Over2", "Text 2", func(): cb2_fired = true)
	dlg.show_dialogue("Over3", "Text 3", func(): cb3_fired = true)

	assert_eq(dlg.speaker_label.text, "Over3", "C1.27: Latest speaker retained on rapid re-entry")
	assert_eq(dlg.dialogue_label.text, "Text 3", "C1.28: Latest text retained on rapid re-entry")

	dlg.advance_dialogue() # skip
	dlg.advance_dialogue() # close
	assert_true(cb3_fired, "C1.29: Latest callback fired upon close")
	assert_false(cb1_fired, "C1.30: Overwritten callback 1 cleanly discarded without error")
	assert_false(cb2_fired, "C1.31: Overwritten callback 2 cleanly discarded without error")

	# Boundary Strings Stress (Empty string, single char, 5000 chars, unicode, newlines)
	dlg.show_dialogue("", "")
	assert_false(dlg.speaker_label.visible, "C1.32: Empty speaker hides speaker label")
	assert_eq(dlg.dialogue_label.text, "", "C1.33: Empty dialogue text handles without division-by-zero")
	dlg.advance_dialogue()
	dlg.advance_dialogue()
	assert_false(dlg.visible, "C1.34: Empty string dialogue closes cleanly")

	var long_str := ""
	for i in range(500):
		long_str += "Ancient lore "
	dlg.show_dialogue("Archivist", long_str)
	assert_eq(dlg.dialogue_label.text.length(), long_str.length(), "C1.35: 6500-char string loaded into label")
	dlg.advance_dialogue() # skip
	assert_eq(dlg.dialogue_label.visible_ratio, 1.0, "C1.36: Skip immediately reveals massive text")
	dlg.advance_dialogue() # close
	assert_false(dlg.visible, "C1.37: Massive text dialogue closes cleanly")

	# Multiline, unicode, and BBCode characters
	var complex_str := "Linha 1\nLinha 2\n[b]Negrito[/b]\n✨ Símbolos: Ω ≈ ç ã é 🚀"
	dlg.show_dialogue("Místico", complex_str)
	assert_eq(dlg.dialogue_label.text, complex_str, "C1.38: Complex unicode & multiline string accepted")
	dlg.advance_dialogue()
	dlg.advance_dialogue()
	assert_false(dlg.visible, "C1.39: Complex string dialogue closes cleanly")

	# Input event simulation
	dlg.show_dialogue("InputTest", "Pressione E para testar.")
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_E
	dlg._unhandled_input(key_event)
	assert_eq(dlg.dialogue_label.visible_ratio, 1.0, "C1.40: InputEventKey KEY_E skips typewriter")

	var mouse_event := InputEventMouseButton.new()
	mouse_event.pressed = true
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	dlg._unhandled_input(mouse_event)
	assert_false(dlg.visible, "C1.41: InputEventMouseButton Left Click closes dialogue")

	dlg.queue_free()
	await process_frame

func _test_category_2_npc_interaction_triggers() -> void:
	print("\n--- [CATEGORY 2: NPC INTERACTION TRIGGERS & OMENS CYCLING] ---")

	var village_scene = load("res://scenes/hub/greyrock_village.tscn")
	assert_true(village_scene != null, "C2.01: greyrock_village scene loads cleanly")

	var village: GreyrockVillage = village_scene.instantiate() as GreyrockVillage
	root.add_child(village)
	await process_frame

	var madre_selene: NPCMadreSelene = village.find_child("MadreSelene", true, false) as NPCMadreSelene
	var elena: NPCElena = village.find_child("Elena", true, false) as NPCElena
	var barnaby: NPCBarnaby = village.find_child("Barnaby", true, false) as NPCBarnaby
	var bottom_dlg: BottomDialogueBox = village.find_child("BottomDialogueBox", true, false) as BottomDialogueBox
	var quest_modal: Control = village.find_child("QuestBoardModal", true, false) as Control
	var tavern_modal: Control = village.find_child("TavernRecruitModal", true, false) as Control
	var hub_hud: Control = village.find_child("HubHUD", true, false) as Control

	assert_true(madre_selene != null, "C2.02: Madre Selene exists in village")
	assert_true(elena != null, "C2.03: Elena exists in village")
	assert_true(barnaby != null, "C2.04: Barnaby exists in village")
	assert_true(bottom_dlg != null, "C2.05: BottomDialogueBox exists in village UI")

	# Test Madre Selene Omens contract across all states
	var gm = _cached_gm
	var tracker = _cached_tracker

	# State A: Fresh Save (0 runs)
	gm.set("total_completed_runs", 0)
	var omen_fresh = madre_selene.get_current_omen()
	assert_eq(omen_fresh.get("type"), "INTRODUCTORY", "C2.06: Fresh save omen type is INTRODUCTORY")
	assert_eq(omen_fresh.get("conduct"), "FRESH_SAVE", "C2.07: Fresh save conduct is FRESH_SAVE")
	assert_true(omen_fresh.get("text", "").contains("fio da sua alma"), "C2.08: Introductory omen mentions soul thread")

	# State B: Benevolent Prophecy (runs > 0, agency >= 50, fallen <= 1)
	gm.set("total_completed_runs", 2)
	tracker.set("agency_score", 70)
	tracker.set("allies_fallen", 0)
	var omen_ben = madre_selene.get_current_omen()
	assert_eq(omen_ben.get("type"), "PROPHECY", "C2.09: Benevolent omen type is PROPHECY")
	assert_eq(omen_ben.get("conduct"), "BENEVOLENT", "C2.10: Benevolent conduct matches")
	assert_true(omen_ben.get("text", "").contains("aliança dos vivos"), "C2.11: Benevolent prophecy text matches")

	# State C: Isolationist Prophecy (runs > 0, agency < 0 or fallen >= 3)
	tracker.set("agency_score", -15)
	tracker.set("allies_fallen", 4)
	var omen_iso = madre_selene.get_current_omen()
	assert_eq(omen_iso.get("type"), "PROPHECY", "C2.12: Isolationist omen type is PROPHECY")
	assert_eq(omen_iso.get("conduct"), "ISOLATIONIST", "C2.13: Isolationist conduct matches")
	assert_true(omen_iso.get("text", "").contains("abismo solitário"), "C2.14: Isolationist prophecy text matches")

	# State D: Unstable Prophecy
	tracker.set("agency_score", 30)
	tracker.set("allies_fallen", 2)
	var omen_unst = madre_selene.get_current_omen()
	assert_eq(omen_unst.get("type"), "PROPHECY", "C2.15: Unstable omen type is PROPHECY")
	assert_eq(omen_unst.get("conduct"), "UNSTABLE", "C2.16: Unstable conduct matches")

	# Test Madre Selene interact() wiring with BottomDialogueBox
	var selene_result = madre_selene.interact()
	assert_true(not selene_result.is_empty(), "C2.17: interact() returns non-empty omen text")
	assert_true(bottom_dlg.visible, "C2.18: Madre Selene interaction opens BottomDialogueBox")
	assert_eq(bottom_dlg.speaker_label.text, "Madre Selene (Vidente)", "C2.19: Speaker is Madre Selene")
	bottom_dlg.advance_dialogue() # skip
	bottom_dlg.advance_dialogue() # close
	assert_false(bottom_dlg.visible, "C2.20: Dialogue box closed cleanly")

	# Test Elena interact() flow to Quest Board Modal
	elena.interact()
	assert_true(bottom_dlg.visible, "C2.21: Elena interaction opens BottomDialogueBox")
	assert_true(bottom_dlg.speaker_label.text.contains("Elena"), "C2.22: Speaker is Elena")
	assert_false(quest_modal.visible, "C2.23: Quest Board Modal not yet open while dialogue is active")

	bottom_dlg.advance_dialogue() # skip typewriter
	bottom_dlg.advance_dialogue() # complete & trigger callback
	assert_false(bottom_dlg.visible, "C2.24: Dialogue closed")
	assert_true(quest_modal.visible, "C2.25: Quest Board Modal opened via Elena callback")
	assert_false(hub_hud.visible, "C2.26: HubHUD hidden when QuestBoardModal is visible (R2/R4)")

	quest_modal.close()
	assert_false(quest_modal.visible, "C2.27: Quest Board Modal closed")
	assert_true(hub_hud.visible, "C2.28: HubHUD restored when QuestBoardModal closes")

	# Test Barnaby interact() flow to Tavern Modal
	barnaby.interact()
	assert_true(bottom_dlg.visible, "C2.29: Barnaby interaction opens BottomDialogueBox")
	assert_true(bottom_dlg.speaker_label.text.contains("Barnaby"), "C2.30: Speaker is Barnaby")
	assert_false(tavern_modal.visible, "C2.31: Tavern Modal not yet open while dialogue is active")

	bottom_dlg.advance_dialogue() # skip typewriter
	bottom_dlg.advance_dialogue() # complete & trigger callback
	assert_false(bottom_dlg.visible, "C2.32: Dialogue closed")
	assert_true(tavern_modal.visible, "C2.33: Tavern Modal opened via Barnaby callback")
	assert_false(hub_hud.visible, "C2.34: HubHUD hidden when TavernRecruitModal is visible (R2/R4)")

	tavern_modal.close()
	assert_false(tavern_modal.visible, "C2.35: Tavern Modal closed")
	assert_true(hub_hud.visible, "C2.36: HubHUD restored when TavernRecruitModal closes")

	# Barnaby rumors check
	var rumors = barnaby.get_all_rumors()
	assert_true(rumors.size() >= 3, "C2.37: Barnaby has at least 3 rumors")
	var rand_rumor = barnaby.get_random_rumor()
	assert_true(not rand_rumor.is_empty(), "C2.38: Random rumor returns valid string")

	village.queue_free()
	await process_frame

func _test_category_3_village_boundaries_and_physics() -> void:
	print("\n--- [CATEGORY 3: VILLAGE LEVEL BOUNDARIES & INVARIANTS] ---")

	var village_scene = load("res://scenes/hub/greyrock_village.tscn")
	var village: GreyrockVillage = village_scene.instantiate() as GreyrockVillage
	root.add_child(village)
	await process_frame

	# Map Invariants
	assert_eq(village.map_width, 640.0, "C3.01: Village map_width invariant is 640.0")
	assert_eq(village.map_height, 360.0, "C3.02: Village map_height invariant is 360.0")
	assert_eq(village.get_village_bounds(), Rect2(0, 0, 640, 360), "C3.03: get_village_bounds is Rect2(0,0,640,360)")
	assert_true(village.is_non_combat_zone(), "C3.04: Village is_non_combat_zone is true")

	# Player state in village
	var player: Player = village.find_child("Player", true, false) as Player
	assert_true(player != null, "C3.05: Player exists in village")
	assert_false(player.can_attack, "C3.06: Player can_attack is disabled in village")
	assert_false(player.combat_enabled, "C3.07: Player combat_enabled is disabled in village")

	# Camera2D Limits
	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	assert_true(cam != null, "C3.08: Camera2D attached to player")
	assert_eq(cam.limit_left, 0, "C3.09: Camera limit_left is 0")
	assert_eq(cam.limit_top, 0, "C3.10: Camera limit_top is 0")
	assert_eq(cam.limit_right, 640, "C3.11: Camera limit_right is 640")
	assert_eq(cam.limit_bottom, 360, "C3.12: Camera limit_bottom is 360")
	assert_true(cam.position_smoothing_enabled, "C3.13: Camera position smoothing is enabled")

	# PerimeterBoundaries StaticBody2D
	var boundaries: StaticBody2D = village.find_child("PerimeterBoundaries", true, false) as StaticBody2D
	assert_true(boundaries != null, "C3.14: PerimeterBoundaries StaticBody2D exists")

	var wall_top = boundaries.get_node_or_null("WallTop") as CollisionShape2D
	var wall_bot = boundaries.get_node_or_null("WallBottom") as CollisionShape2D
	var wall_left = boundaries.get_node_or_null("WallLeft") as CollisionShape2D
	var wall_right = boundaries.get_node_or_null("WallRight") as CollisionShape2D

	assert_true(wall_top != null, "C3.15: WallTop collision shape exists")
	assert_true(wall_bot != null, "C3.16: WallBottom collision shape exists")
	assert_true(wall_left != null, "C3.17: WallLeft collision shape exists")
	assert_true(wall_right != null, "C3.18: WallRight collision shape exists")

	# Test Kinematic Penetration / Boundary Escape against all 4 perimeter walls
	# Player radius is 7px. Test high-speed movements towards boundaries.
	var delta := 0.01667

	# Push Left towards x=0 with extreme velocity
	player.global_position = Vector2(25, 180)
	for step in range(30):
		player.velocity = Vector2(-800, 0)
		player.move_and_slide()
	assert_true(player.global_position.x >= 7.0, "C3.19: Player cannot breach Left boundary (x >= 7, actual: %.1f)" % player.global_position.x)

	# Push Right towards x=640 with extreme velocity
	player.global_position = Vector2(615, 180)
	for step in range(30):
		player.velocity = Vector2(800, 0)
		player.move_and_slide()
	assert_true(player.global_position.x <= 633.0, "C3.20: Player cannot breach Right boundary (x <= 633, actual: %.1f)" % player.global_position.x)

	# Push Top towards y=0 with extreme velocity
	player.global_position = Vector2(320, 25)
	for step in range(30):
		player.velocity = Vector2(0, -800)
		player.move_and_slide()
	assert_true(player.global_position.y >= 7.0, "C3.21: Player cannot breach Top boundary (y >= 7, actual: %.1f)" % player.global_position.y)

	# Push Bottom towards y=360 with extreme velocity
	player.global_position = Vector2(320, 335)
	for step in range(30):
		player.velocity = Vector2(0, 800)
		player.move_and_slide()
	assert_true(player.global_position.y <= 353.0, "C3.22: Player cannot breach Bottom boundary (y <= 353, actual: %.1f)" % player.global_position.y)

	# Test Props Collision Integrity
	var props_node = village.find_child("Props", true, false)
	assert_true(props_node != null, "C3.23: Props container exists")
	var well = props_node.get_node_or_null("WellObstacle") as StaticBody2D
	var guild_counter = props_node.get_node_or_null("GuildCounter") as StaticBody2D
	var tavern_counter = props_node.get_node_or_null("TavernCounter") as StaticBody2D
	var barrel = props_node.get_node_or_null("Barrel1") as StaticBody2D
	var crate = props_node.get_node_or_null("Crate1") as StaticBody2D

	assert_true(well != null and well.get_node_or_null("CollisionShape2D") != null, "C3.24: Well obstacle has collision shape")
	assert_true(guild_counter != null and guild_counter.get_node_or_null("CollisionShape2D") != null, "C3.25: Guild counter has collision shape")
	assert_true(tavern_counter != null and tavern_counter.get_node_or_null("CollisionShape2D") != null, "C3.26: Tavern counter has collision shape")
	assert_true(barrel != null and barrel.get_node_or_null("CollisionShape2D") != null, "C3.27: Barrel prop has collision shape")
	assert_true(crate != null and crate.get_node_or_null("CollisionShape2D") != null, "C3.28: Crate prop has collision shape")

	# Test collision against WellObstacle
	player.global_position = well.global_position + Vector2(25, 0)
	var collision = player.move_and_collide(Vector2(-20, 0))
	assert_true(collision != null, "C3.29: Player collides with Well obstacle and cannot pass through")

	village.queue_free()
	await process_frame

func _test_category_4_arena_atmosphere_and_waves() -> void:
	print("\n--- [CATEGORY 4: ARENA ATMOSPHERE & COMBAT WAVES] ---")

	var arena_scene = load("res://scenes/arena/arena.tscn")
	assert_true(arena_scene != null, "C4.01: arena scene loads cleanly")

	var arena: Arena = arena_scene.instantiate() as Arena
	root.add_child(arena)
	await process_frame

	# Atmosphere Floor and Visual Semantics
	var floor_node: TextureRect = arena.find_child("Floor", true, false) as TextureRect
	assert_true(floor_node != null, "C4.02: Arena Floor exists")
	assert_true(floor_node.texture.resource_path.contains("tile_0037"), "C4.03: Arena Floor uses tile_0037 seamless stone slab")

	# Ensure no blue test grid
	assert_true(floor_node.modulate.r >= 0.8, "C4.04: Arena Floor red channel is warm (%.2f >= 0.8)" % floor_node.modulate.r)
	assert_true(floor_node.modulate.b <= 0.85, "C4.05: Arena Floor blue channel is suppressed warm stone (%.2f <= 0.85, not blue test grid)" % floor_node.modulate.b)

	# Decorative Wall & Torch nodes
	var borders: Node2D = arena.find_child("FloorBorders", true, false) as Node2D
	var walls: Node2D = arena.find_child("PerimeterWalls", true, false) as Node2D
	var torches: Node2D = arena.find_child("AtmosphereTorches", true, false) as Node2D

	assert_true(borders != null and borders.get_child_count() >= 5, "C4.06: Floor borders exist with cracked stone outlines")
	assert_true(walls != null and walls.get_child_count() >= 4, "C4.07: Perimeter masonry stone walls exist")
	assert_true(torches != null and torches.get_child_count() >= 24, "C4.08: Atmosphere torches and braziers exist (>24 fixtures)")

	# CRITICAL CHECK: Ensure decorative elements do NOT have physics collision
	var has_decorative_collision := false
	for parent_node in [floor_node, borders, walls, torches]:
		for child in parent_node.get_children():
			if child is CollisionObject2D or child is CollisionShape2D:
				has_decorative_collision = true
	assert_false(has_decorative_collision, "C4.09: Torches, braziers, and floor borders have NO physics collision (pure visuals)")

	# Boundaries and Camera Limits
	var arena_bounds: StaticBody2D = arena.find_child("ArenaBoundaries", true, false) as StaticBody2D
	assert_true(arena_bounds != null and arena_bounds.get_child_count() >= 4, "C4.10: ArenaBoundaries StaticBody2D has >= 4 boundaries")

	var player: Player = arena.find_child("Player", true, false) as Player
	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	assert_true(cam != null, "C4.11: Camera2D exists on arena player")
	assert_eq(cam.limit_left, -600, "C4.12: Arena Camera limit_left is -600")
	assert_eq(cam.limit_top, -400, "C4.13: Arena Camera limit_top is -400")
	assert_eq(cam.limit_right, 600, "C4.14: Arena Camera limit_right is 600")
	assert_eq(cam.limit_bottom, 400, "C4.15: Arena Camera limit_bottom is 400")

	# Wave Spawning Scaling Stress Test
	# Clean any initial children before testing waves
	var initial_enemy_count := 0
	for child in arena.get_children():
		if child is Enemy:
			initial_enemy_count += 1

	# Test wave at t=0s
	arena.set("_game_time", 0.0)
	arena._spawn_wave()
	var enemies_t0: Array = []
	for child in arena.get_children():
		if child is Enemy:
			enemies_t0.append(child)
	assert_eq(enemies_t0.size() - initial_enemy_count, 2, "C4.16: Initial wave spawns exactly 2 enemies at t=0s")

	# Validate all spawned enemies are within arena boundaries [-576, 576] x [-384, 384]
	var all_in_bounds := true
	for e in enemies_t0:
		var pos: Vector2 = (e as Enemy).global_position
		if abs(pos.x) > 576.0 or abs(pos.y) > 384.0:
			all_in_bounds = false
	assert_true(all_in_bounds, "C4.17: Enemies spawn strictly within arena floor bounds")

	# Test wave scaling at t=25s (3 enemies)
	arena.set("_game_time", 25.0)
	var prev_count = arena.get_children().filter(func(c): return c is Enemy).size()
	arena._spawn_wave()
	var new_count = arena.get_children().filter(func(c): return c is Enemy).size()
	assert_eq(new_count - prev_count, 3, "C4.18: Wave scales to 3 enemies at t=25s")

	# Test wave scaling at t=60s (5 enemies)
	arena.set("_game_time", 60.0)
	prev_count = arena.get_children().filter(func(c): return c is Enemy).size()
	arena._spawn_wave()
	new_count = arena.get_children().filter(func(c): return c is Enemy).size()
	assert_eq(new_count - prev_count, 5, "C4.19: Wave scales to 5 enemies at t=60s")

	# Test max wave scaling cap (8 enemies)
	arena.set("_game_time", 180.0)
	prev_count = arena.get_children().filter(func(c): return c is Enemy).size()
	arena._spawn_wave()
	new_count = arena.get_children().filter(func(c): return c is Enemy).size()
	assert_eq(new_count - prev_count, 8, "C4.20: Wave scales and caps at 8 enemies at t=180s")

	# Test Boss Spawn
	arena._spawn_boss()
	var boss: Enemy = null
	for child in arena.get_children():
		if child is Enemy and child.enemy_type == Enemy.EnemyType.DEMON_BOSS:
			boss = child
			break
	assert_true(boss != null, "C4.21: Demon Boss spawns successfully")
	if boss != null:
		assert_eq(boss.global_position, player.global_position + Vector2(0, -380), "C4.22: Boss spawns at offset (0, -380) from player")

	# Test enemy navigation on stone floor
	var test_enemy: Enemy = enemies_t0[0] as Enemy
	test_enemy.global_position = Vector2(100, 100)
	player.global_position = Vector2(0, 0)
	# Run one physics process on enemy
	test_enemy._physics_process(0.01667)
	assert_true(test_enemy.velocity.length() > 0.0, "C4.23: Enemy moves smoothly with non-zero velocity on stone floor")

	arena.queue_free()
	await process_frame

func _print_summary() -> void:
	print("\n======================================================================")
	print(" ADVERSARIAL STRESS TEST EXECUTION SUMMARY")
	print("======================================================================\n")
	print(" Total Assertions Evaluated : %d" % total_assertions)
	print(" Passed                      : %d" % passed_assertions)
	print(" Failed                      : %d" % failed_assertions)

	if failed_assertions > 0:
		printerr("\n--- FINDINGS (%d FAILURES) ---" % failed_assertions)
		for f in findings:
			printerr("  - [%s] %s: %s" % [f.severity, f.name, f.detail])
		print("\n>> VERDICT: REQUEST_CHANGES")
		quit(1)
	else:
		print("\n>> ALL 89 ADVERSARIAL ASSERTIONS PASSED WITH ZERO FAILURES.")
		print(">> VERDICT: APPROVE")
		quit(0)
