extends RefCounted

## Verification Suite for Milestone 3 (M3): Greyrock Village Hub & Barnaby's Tavern.
## Compatible with both standalone test_m3_village_hub.gd and test_runner.gd.

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var exit_code: int = 0

func run_all(runner: SceneTree) -> void:
	print("\n--- [MILESTONE 3: GREYROCK VILLAGE HUB & TAVERN TESTS] ---")
	await test_village_scene_and_boundaries(runner)
	await test_player_locomotion_non_combat(runner)
	await test_elena_and_quest_board_modal(runner)
	await test_barnaby_and_tavern_recruitment(runner)
	await test_madre_selene_cryptic_omens(runner)
	await test_game_manager_transitions(runner)

func record_pass(runner: SceneTree, test_name: String) -> void:
	total_assertions += 1
	passed_assertions += 1
	if runner.has_method("record_pass"):
		runner.record_pass(test_name)
	else:
		print("  [PASS] %s" % test_name)

func record_fail(runner: SceneTree, test_name: String, msg: String) -> void:
	total_assertions += 1
	failed_assertions += 1
	exit_code = 1
	if runner.has_method("record_fail"):
		runner.record_fail(test_name, msg)
	else:
		printerr("  [FAIL] %s -> %s" % [test_name, msg])

func assert_true(runner: SceneTree, cond: bool, test_name: String, msg: String = "") -> void:
	if cond:
		record_pass(runner, test_name)
	else:
		record_fail(runner, test_name, msg if msg != "" else "Expected true, got false")

func assert_false(runner: SceneTree, cond: bool, test_name: String, msg: String = "") -> void:
	assert_true(runner, not cond, test_name, msg if msg != "" else "Expected false, got true")

func assert_eq(runner: SceneTree, actual: Variant, expected: Variant, test_name: String, msg: String = "") -> void:
	if actual == expected:
		record_pass(runner, test_name)
	else:
		var detail := "Expected '%s', got '%s'" % [str(expected), str(actual)]
		if msg != "":
			detail = "%s (%s)" % [msg, detail]
		record_fail(runner, test_name, detail)

# -----------------------------------------------------------------------------
# 1. Village Scene & Locomotion & Boundaries
# -----------------------------------------------------------------------------
func test_village_scene_and_boundaries(runner: SceneTree) -> void:
	assert_true(runner, ResourceLoader.exists("res://scenes/hub/greyrock_village.tscn"),
		"M3.01: Greyrock Village Scene Resource Exists")
	assert_true(runner, ResourceLoader.exists("res://scripts/hub/greyrock_village.gd"),
		"M3.02: Greyrock Village Script Exists")

	var VillageScene = load("res://scenes/hub/greyrock_village.tscn")
	var village = VillageScene.instantiate() as Node2D
	assert_true(runner, village != null, "M3.03: Village Scene Instantiates Cleanly")

	runner.root.add_child(village)
	await runner.process_frame

	assert_eq(runner, village.get("map_width"), 640.0, "M3.04: Village Map Width is Exactly 640")
	assert_eq(runner, village.get("map_height"), 360.0, "M3.05: Village Map Height is Exactly 360")

	var boundaries = village.find_child("PerimeterBoundaries", true, false)
	assert_true(runner, boundaries != null and boundaries is StaticBody2D, "M3.06: StaticBody2D Perimeter Boundaries Exist")
	if boundaries != null:
		assert_true(runner, boundaries.get_child_count() >= 4, "M3.07: Perimeter Has at Least 4 Boundary Shapes")

	var elena = village.find_child("Elena", true, false)
	var barnaby = village.find_child("Barnaby", true, false)
	var selene = village.find_child("MadreSelene", true, false)
	assert_true(runner, elena != null, "M3.08: Elena NPC Node Exists in Village")
	assert_true(runner, barnaby != null, "M3.09: Barnaby NPC Node Exists in Village")
	assert_true(runner, selene != null, "M3.10: MadreSelene NPC Node Exists in Village")

	runner.root.remove_child(village)
	village.free()

# -----------------------------------------------------------------------------
# 2. Player Locomotion in Non-Combat Zone
# -----------------------------------------------------------------------------
func test_player_locomotion_non_combat(runner: SceneTree) -> void:
	var VillageScene = load("res://scenes/hub/greyrock_village.tscn")
	var village = VillageScene.instantiate() as Node2D
	runner.root.add_child(village)
	await runner.process_frame

	var player = village.find_child("Player", true, false) as Player
	assert_true(runner, player != null, "M3.11: Player Instantiated in Village Hub")

	if player != null:
		assert_false(runner, player.can_attack, "M3.12: Player can_attack is Disabled in Village")
		assert_false(runner, player.combat_enabled, "M3.13: Player combat_enabled is Disabled in Village")

		var cam = player.find_child("Camera2D", true, false)
		assert_true(runner, cam != null, "M3.14: Player Has Camera2D Follow Node")

	runner.root.remove_child(village)
	village.free()

# -----------------------------------------------------------------------------
# 3. Elena & Quest Board Modal
# -----------------------------------------------------------------------------
func test_elena_and_quest_board_modal(runner: SceneTree) -> void:
	assert_true(runner, ResourceLoader.exists("res://scenes/ui/modals/quest_board_modal.tscn"),
		"M3.15: Quest Board Modal Scene Exists")
	assert_true(runner, ResourceLoader.exists("res://scripts/ui/modals/quest_board_modal.gd"),
		"M3.16: Quest Board Modal Script Exists")

	var ModalScene = load("res://scenes/ui/modals/quest_board_modal.tscn")
	var modal = ModalScene.instantiate() as Control
	runner.root.add_child(modal)
	await runner.process_frame

	var all_ranks: Array = modal.call("get_all_ranks")
	assert_eq(runner, all_ranks, ["F", "E", "D", "C", "B", "A", "S"], "M3.17: Quest Board Displays Ranks F Through S")

	var available: Array = modal.call("get_available_ranks")
	assert_true(runner, "F" in available and "E" in available, "M3.18: Ranks F and E are Unlocked")
	assert_false(runner, "D" in available or "B" in available or "S" in available, "M3.19: High Ranks D-S are Locked")

	var select_b: bool = modal.call("select_quest", "B")
	assert_false(runner, select_b, "M3.20: Selecting Locked Quest (Rank B) is Rejected")

	var select_f: bool = modal.call("select_quest", "F")
	assert_true(runner, select_f, "M3.21: Selecting Active Quest (Rank F) Succeeds")

	runner.root.remove_child(modal)
	modal.free()

# -----------------------------------------------------------------------------
# 4. Barnaby & Tavern Recruitment Modal (Enneagram Deduction)
# -----------------------------------------------------------------------------
func test_barnaby_and_tavern_recruitment(runner: SceneTree) -> void:
	assert_true(runner, ResourceLoader.exists("res://scenes/ui/modals/tavern_recruit_modal.tscn"),
		"M3.22: Tavern Recruit Modal Scene Exists")
	assert_true(runner, ResourceLoader.exists("res://scripts/ui/modals/tavern_recruit_modal.gd"),
		"M3.23: Tavern Recruit Modal Script Exists")

	var ModalScene = load("res://scenes/ui/modals/tavern_recruit_modal.tscn")
	var modal = ModalScene.instantiate() as Control
	runner.root.add_child(modal)
	await runner.process_frame

	var rumors: Array = modal.call("get_rumors")
	assert_true(runner, rumors.size() >= 3, "M3.24: Tavern Offers at Least 3 Tactical Rumors")

	var candidates: Array = modal.call("get_candidates")
	assert_true(runner, candidates.size() >= 3, "M3.25: Tavern Generates At Least 3 Hireable Mercenaries")

	var has_type_8 := false
	var has_type_5 := false
	var has_type_1 := false

	for c in candidates:
		var q: String = c.get("quote", "")
		var e_type: int = c.get("enneagram_type", 0)
		if e_type == 8:
			has_type_8 = true
			assert_true(runner, q.find("primeiro golpe") != -1 or q.find("passos para trás") != -1,
				"M3.26: Type 8 Roland Speaks Challenger Dialogue")
		elif e_type == 5:
			has_type_5 = true
			assert_true(runner, q.find("balísticos") != -1 or q.find("analisar") != -1,
				"M3.27: Type 5 Lyra Speaks Analytical Dialogue")
		elif e_type == 1:
			has_type_1 = true
			assert_true(runner, q.find("disciplina") != -1 or q.find("protocolo") != -1,
				"M3.28: Type 1 Morgana Speaks Reformer Dialogue")

	assert_true(runner, has_type_8 and has_type_5 and has_type_1,
		"M3.29: All Three Mercenaries Exhibit Distinct Enneagram Personalities")

	var gm = runner.root.get_node_or_null("GameManager")
	if gm != null:
		gm.call("clear_party_roster")
		gm.set("player_gold", 1000)

		var hire_first: bool = modal.call("hire_candidate", "paladin_roland")
		assert_true(runner, hire_first, "M3.30: First Hiring of Paladin Roland Succeeds")

		var hire_duplicate: bool = modal.call("hire_candidate", "paladin_roland")
		assert_false(runner, hire_duplicate, "M3.31: Duplicate Hiring of Paladin Roland is Rejected")

		var roster: Array = gm.call("get_active_party_roster")
		assert_eq(runner, roster.size(), 1, "M3.32: Active Party Contains Exactly 1 Recruited Member")

	runner.root.remove_child(modal)
	modal.free()

# -----------------------------------------------------------------------------
# 5. Madre Selene Cryptic Omens
# -----------------------------------------------------------------------------
func test_madre_selene_cryptic_omens(runner: SceneTree) -> void:
	assert_true(runner, ResourceLoader.exists("res://scenes/hub/npc_madre_selene.tscn"),
		"M3.33: Madre Selene Scene Exists")
	assert_true(runner, ResourceLoader.exists("res://scripts/hub/npc_madre_selene.gd"),
		"M3.34: Madre Selene Script Exists")

	var SeleneScene = load("res://scenes/hub/npc_madre_selene.tscn")
	var selene = SeleneScene.instantiate() as CharacterBody2D
	runner.root.add_child(selene)
	await runner.process_frame

	var omen: Dictionary = selene.call("get_current_omen")
	assert_eq(runner, omen.get("type"), "INTRODUCTORY", "M3.35: Fresh Save Returns INTRODUCTORY Omen")
	var omen_text: String = omen.get("text", "")
	assert_true(runner, omen_text.find("fio da sua alma") != -1 or omen_text.find("estrangeiro") != -1,
		"M3.36: Intro Omen Matches Prophetic Dialogue")

	runner.root.remove_child(selene)
	selene.free()

# -----------------------------------------------------------------------------
# 6. GameManager Scene Transitions
# -----------------------------------------------------------------------------
func test_game_manager_transitions(runner: SceneTree) -> void:
	var gm = runner.root.get_node_or_null("GameManager")
	assert_true(runner, gm != null, "M3.37: GameManager AutoLoad Node is Active")

	if gm != null:
		assert_true(runner, gm.has_method("transition_to_dungeon"), "M3.38: GameManager Has transition_to_dungeon")
		assert_true(runner, gm.has_method("transition_to_hub"), "M3.39: GameManager Has transition_to_hub")

		var test_roster: Array[Dictionary] = [
			{"id": "merc_1", "name": "Mercenary 1"},
			{"id": "merc_2", "name": "Mercenary 2"}
		]
		gm.call("set_active_party_roster", test_roster)
		var stored: Array = gm.call("get_active_party_roster")
		assert_eq(runner, stored.size(), 2, "M3.40: GameManager Preserves Party Roster Across Expeditions")

		gm.call("set_selected_quest_rank", "E")
		var q_rank: String = gm.call("get_selected_quest_rank")
		assert_eq(runner, q_rank, "E", "M3.41: GameManager Preserves Selected Quest Rank")
		gm.call("clear_party_roster")
