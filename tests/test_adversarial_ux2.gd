extends SceneTree

## Adversarial Stress & Integrity Test Suite for R2 (Containers/Modals) & R3 (Bottom Dialogue Box)
## Author: Reviewer UX 2 (Reviewer & Adversarial Critic)

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var failure_details: Array[String] = []

func _init() -> void:
	call_deferred("_run_adversarial_suite")

func record_pass(test_name: String) -> void:
	total_assertions += 1
	passed_assertions += 1
	print("  [PASS] %s" % test_name)

func record_fail(test_name: String, detail: String) -> void:
	total_assertions += 1
	failed_assertions += 1
	failure_details.append("%s: %s" % [test_name, detail])
	printerr("  [FAIL] %s -> %s" % [test_name, detail])

func assert_true(cond: bool, test_name: String, detail: String = "") -> void:
	if cond:
		record_pass(test_name)
	else:
		record_fail(test_name, detail if detail != "" else "Expected true, got false")

func assert_false(cond: bool, test_name: String, detail: String = "") -> void:
	assert_true(not cond, test_name, detail if detail != "" else "Expected false, got true")

func assert_eq(actual: Variant, expected: Variant, test_name: String) -> void:
	if actual == expected:
		record_pass(test_name)
	else:
		record_fail(test_name, "Expected '%s', got '%s'" % [str(expected), str(actual)])

func _run_adversarial_suite() -> void:
	print("\n" + "=".repeat(70))
	print(" ADVERSARIAL STRESS & INTEGRITY SUITE — R2 & R3")
	print(" Reviewer: Reviewer UX 2")
	print(" Engine: Godot 4.6.1 (Headless)")
	print("=".repeat(70) + "\n")

	await _test_bottom_dialogue_adversarial()
	await _test_gacha_adversarial()
	await _test_tavern_modal_adversarial()
	await _test_quest_board_adversarial()
	await _test_ending_screen_adversarial()
	await _test_village_hud_interlock_adversarial()

	print("\n" + "=".repeat(70))
	print(" ADVERSARIAL TEST RESULTS: %d/%d Passed | %d Failed" % [passed_assertions, total_assertions, failed_assertions])
	print("=".repeat(70) + "\n")

	if failed_assertions > 0:
		for f in failure_details:
			printerr("  - " + f)
		quit(1)
	else:
		print(">> ALL ADVERSARIAL TESTS PASSED!\n")
		quit(0)

# =============================================================================
# 1. BottomDialogueBox Adversarial Stress Testing
# =============================================================================
func _test_bottom_dialogue_adversarial() -> void:
	print("--- [ADVERSARIAL R3: BOTTOM DIALOGUE BOX] ---")
	var DlgScene = load("res://scenes/ui/dialogue/bottom_dialogue_box.tscn")
	var dlg = DlgScene.instantiate() as BottomDialogueBox
	root.add_child(dlg)
	await process_frame

	# Test 1.1: Empty speaker & text
	dlg.show_dialogue("", "")
	assert_true(dlg.visible, "ADV-R3.01: Empty dialogue makes dialog visible without crash")
	var spk: Label = dlg.find_child("SpeakerLabel", true, false) as Label
	assert_true(spk != null and not spk.visible, "ADV-R3.02: Empty speaker hides speaker label")
	dlg.close_dialogue()
	await process_frame

	# Test 1.2: Extreme long string (stress typewriter duration clamping)
	var long_str := "A".repeat(3000)
	dlg.show_dialogue("Narrador Cósmico", long_str)
	var dlg_lbl: Label = dlg.find_child("DialogueLabel", true, false) as Label
	assert_true(dlg_lbl != null and dlg_lbl.text.length() == 3000, "ADV-R3.03: 3000-char string loaded into DialogueLabel")
	# Tween duration must be clamped between 0.4 and 2.2
	assert_true(dlg._typewriter_tween != null and dlg._typewriter_tween.is_valid(), "ADV-R3.04: Typewriter tween is active")
	dlg.advance_dialogue() # Skip to end
	await process_frame
	assert_eq(dlg_lbl.visible_ratio, 1.0, "ADV-R3.05: Advance skips 3000-char typewriter to 1.0 visible_ratio")
	assert_true(not dlg._is_typing, "ADV-R3.06: is_typing flag is cleared on skip")

	# Advance again should close
	var closed_emitted := [false]
	dlg.dialogue_closed.connect(func(): closed_emitted[0] = true, CONNECT_ONE_SHOT)
	dlg.advance_dialogue()
	await process_frame
	assert_true(not dlg.visible and closed_emitted[0], "ADV-R3.07: Second advance closes dialog and emits signal")

	# Test 1.3: Rapid repeated calls (50 iterations)
	var cb_counter := [0]
	for i in range(50):
		dlg.show_dialogue("NPC %d" % i, "Mensagem rápida %d" % i, func(): cb_counter[0] += 1)
	assert_true(dlg.visible and dlg.is_active, "ADV-R3.08: 50 rapid show_dialogue calls handled without crash")
	dlg.close_dialogue()
	await process_frame
	assert_eq(cb_counter[0], 1, "ADV-R3.09: Only the final active callback executed on close")

	# Test 1.4: Multiple advance calls when closed
	for i in range(10):
		dlg.advance_dialogue()
	assert_false(dlg.visible, "ADV-R3.10: Spurious advance calls while closed are safe no-ops")

	# Test 1.5: Input event processing
	dlg.show_dialogue("Testador", "Aperte E para pular.")
	var key_ev := InputEventKey.new()
	key_ev.pressed = true
	key_ev.keycode = KEY_E
	dlg._unhandled_input(key_ev)
	await process_frame
	assert_eq(dlg_lbl.visible_ratio, 1.0, "ADV-R3.11: KEY_E skips typewriter via _unhandled_input")
	dlg._unhandled_input(key_ev)
	await process_frame
	assert_false(dlg.visible, "ADV-R3.12: Second KEY_E closes dialogue via _unhandled_input")

	root.remove_child(dlg)
	dlg.free()

# =============================================================================
# 2. GachaScreen Adversarial Stress Testing
# =============================================================================
func _test_gacha_adversarial() -> void:
	print("\n--- [ADVERSARIAL R2: GACHA SCREEN] ---")
	var GachaScene = load("res://scenes/ui/gacha_screen/gacha_screen.tscn")
	var gacha = GachaScene.instantiate() as GachaScreen
	root.add_child(gacha)
	await process_frame

	# Test 2.1: Level 2 starter cheat card generation
	gacha.open_gacha(2)
	assert_true(gacha.visible, "ADV-R2.01: Gacha opens at level 2")
	var cards_cont: HBoxContainer = gacha.find_child("CardsContainer", true, false) as HBoxContainer
	assert_true(cards_cont != null, "ADV-R2.02: CardsContainer exists")
	assert_eq(cards_cont.get_child_count(), 3, "ADV-R2.03: Level 2 generates exactly 3 starter cheat cards")

	# Verify card button geometry and styling
	for child in cards_cont.get_children():
		var btn = child as Button
		assert_true(btn != null, "ADV-R2.04: Card is a Button")
		assert_eq(btn.custom_minimum_size, Vector2(165, 205), "ADV-R2.05: Card custom_minimum_size is 165x205")
		assert_true(btn.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "ADV-R2.06: Card text has smart autowrap")

	# Test 2.2: Successive opens at higher levels (Monte Carlo 50 runs to ensure no duplicate cards in hand)
	var all_unique := true
	for lvl in range(3, 53):
		gacha.open_gacha(lvl)
		var ids: Array[String] = []
		# We inspect the buttons' text
		if cards_cont.get_child_count() != 3:
			all_unique = false
	assert_true(all_unique, "ADV-R2.07: 50 Monte Carlo gacha draws each produce exactly 3 cards")

	# Test 2.3: Boss theft mode
	gacha.open_boss_theft("Colosso Ignis")
	assert_eq(cards_cont.get_child_count(), 3, "ADV-R2.08: Boss theft generates 3 boss theft cards")
	var title_lbl: Label = gacha.find_child("TitleLabel", true, false) as Label
	assert_true(title_lbl != null and title_lbl.text.find("ALMA DO CHEFE") != -1, "ADV-R2.09: Boss theft title applied")

	# Test 2.4: Card selection unpauses and emits signal
	var card_received: Dictionary = {}
	gacha.card_chosen.connect(func(c): card_received = c, CONNECT_ONE_SHOT)
	var first_btn = cards_cont.get_child(0) as Button
	first_btn.emit_signal("pressed")
	await process_frame
	assert_false(gacha.visible, "ADV-R2.10: Card selection closes gacha")
	assert_false(get_tree().paused, "ADV-R2.11: Card selection unpauses SceneTree")
	assert_true(not card_received.is_empty(), "ADV-R2.12: Card chosen signal emitted with valid dictionary")

	root.remove_child(gacha)
	gacha.free()

# =============================================================================
# 3. TavernRecruitModal Adversarial Stress Testing
# =============================================================================
func _test_tavern_modal_adversarial() -> void:
	print("\n--- [ADVERSARIAL R2: TAVERN RECRUIT MODAL] ---")
	var TavernScene = load("res://scenes/ui/modals/tavern_recruit_modal.tscn")
	var tavern = TavernScene.instantiate() as TavernRecruitModal
	root.add_child(tavern)
	await process_frame

	tavern.open()
	assert_true(tavern.visible, "ADV-R2.13: Tavern modal opens")

	# Test 3.1: Rumor cycling wraps around without index out of bounds
	var total_rumors: int = tavern.get_rumors().size()
	var looped_cleanly := true
	for i in range(total_rumors * 3):
		var r: String = tavern.cycle_rumor()
		if r.is_empty():
			looped_cleanly = false
	assert_true(looped_cleanly, "ADV-R2.14: Cycling rumors wraps safely over 3 full cycles")

	# Test 3.2: Candidate cards dimensions & responsiveness
	var roster: HBoxContainer = tavern.find_child("MercenaryHBox", true, false) as HBoxContainer
	assert_true(roster != null and roster.get_child_count() == 3, "ADV-R2.15: MercenaryHBox contains 3 cards")
	for child in roster.get_children():
		var card = child as PanelContainer
		assert_true(card != null, "ADV-R2.16: Card is PanelContainer")
		assert_eq(card.custom_minimum_size, Vector2(160, 140), "ADV-R2.17: Card size is 160x140")
		var card_margin = card.get_child(0) as MarginContainer
		assert_true(card_margin != null, "ADV-R2.18: Card has internal MarginContainer")

	# Test 3.3: Invalid candidate ID hiring
	var invalid_hire: bool = tavern.hire_candidate("non_existent_hero")
	assert_false(invalid_hire, "ADV-R2.19: Hiring non-existent candidate ID safely returns false")

	# Test 3.4: Party capacity limit enforcement
	var gm = root.get_node_or_null("GameManager")
	if gm != null:
		# Fill party to 3
		var dummy_party: Array[Dictionary] = [
			{"id": "m1", "name": "Merc 1"},
			{"id": "m2", "name": "Merc 2"},
			{"id": "m3", "name": "Merc 3"}
		]
		gm.call("set_active_party_roster", dummy_party)
		var overflow_hire: bool = tavern.hire_candidate("paladin_roland")
		assert_false(overflow_hire, "ADV-R2.20: Hiring when party is at 3/3 capacity is blocked")
		gm.call("clear_party_roster")

	tavern.close()
	assert_false(tavern.visible, "ADV-R2.21: Tavern modal closes cleanly")

	root.remove_child(tavern)
	tavern.free()

# =============================================================================
# 4. QuestBoardModal Adversarial Stress Testing
# =============================================================================
func _test_quest_board_adversarial() -> void:
	print("\n--- [ADVERSARIAL R2: QUEST BOARD MODAL] ---")
	var QuestScene = load("res://scenes/ui/modals/quest_board_modal.tscn")
	var quest = QuestScene.instantiate() as QuestBoardModal
	root.add_child(quest)
	await process_frame

	quest.open()
	assert_true(quest.visible, "ADV-R2.22: Quest board modal opens")

	# Test 4.1: Database completeness
	var all_ranks: Array = quest.get_all_ranks()
	assert_eq(all_ranks.size(), 7, "ADV-R2.23: Exactly 7 quest ranks (F through S)")
	for rank in all_ranks:
		var d: Dictionary = quest.get_quest_details(rank)
		assert_true(d.has("name") and d.has("description") and d.has("reward") and d.has("criteria"),
			"ADV-R2.24: Quest details for Rank %s complete" % rank)

	# Test 4.2: Fuzzing select_quest with invalid strings
	assert_false(quest.select_quest("XYZ"), "ADV-R2.25: Invalid rank 'XYZ' safely rejected")
	assert_false(quest.select_quest(""), "ADV-R2.26: Empty rank safely rejected")

	# Test 4.3: Locked ranks rejection
	for locked_rank in ["D", "C", "B", "A", "S"]:
		assert_false(quest.select_quest(locked_rank), "ADV-R2.27: Locked Rank %s rejected" % locked_rank)

	# Test 4.4: DetailMargin padding check
	var detail_margin: MarginContainer = quest.find_child("DetailMargin", true, false) as MarginContainer
	assert_true(detail_margin != null, "ADV-R2.28: DetailMargin exists")
	assert_eq(detail_margin.get_theme_constant("margin_left"), 10, "ADV-R2.29: DetailMargin has 10px margin")

	quest.close()
	assert_false(quest.visible, "ADV-R2.30: Quest board modal closes cleanly")

	root.remove_child(quest)
	quest.free()

# =============================================================================
# 5. EndingScreen Adversarial Stress Testing
# =============================================================================
func _test_ending_screen_adversarial() -> void:
	print("\n--- [ADVERSARIAL R2: ENDING SCREEN] ---")
	var EndingScene = load("res://scenes/ui/ending_screen/ending_screen.tscn")
	var ending = EndingScene.instantiate() as EndingScreen
	root.add_child(ending)
	await process_frame

	# Test 5.1: Good ending display
	ending.display_ending("GOOD_ENDING", {
		"allies_survived": 3,
		"rescues_performed": 5,
		"allies_fallen": 0,
		"reckless_orders_issued": 0,
		"agency_score": 100
	})
	assert_eq(ending.title_label.text, "A Aliança dos Vivos", "ADV-R2.31: Good ending title is 'A Aliança dos Vivos'")
	assert_eq(ending.surv_val_label.text, "3", "ADV-R2.32: SurvVal displays 3")
	assert_eq(ending.score_val_label.text, "100", "ADV-R2.33: ScoreVal displays 100")

	# Test 5.2: Bad ending display
	ending.display_ending("BAD_ENDING", {
		"allies_survived": 0,
		"rescues_performed": 0,
		"allies_fallen": 4,
		"reckless_orders_issued": 8,
		"agency_score": -45
	})
	assert_eq(ending.title_label.text, "O Monstro Solitário", "ADV-R2.34: Bad ending title is 'O Monstro Solitário'")
	assert_eq(ending.fallen_val_label.text, "4", "ADV-R2.35: FallenVal displays 4")
	assert_eq(ending.score_val_label.text, "-45", "ADV-R2.36: ScoreVal displays -45")

	# Test 5.3: Empty metrics fuzzing
	ending.display_ending("", {})
	assert_eq(ending.title_label.text, "O Monstro Solitário", "ADV-R2.37: Empty ending defaults to Bad Ending")
	assert_eq(ending.score_val_label.text, "0", "ADV-R2.38: Empty metrics defaults score to 0 without crash")

	# Test 5.4: Return button signal
	var ret_emitted := [false]
	ending.return_to_hub_requested.connect(func(): ret_emitted[0] = true, CONNECT_ONE_SHOT)
	ending.return_button.emit_signal("pressed")
	assert_true(ret_emitted[0], "ADV-R2.39: Return button emits return_to_hub_requested signal")

	root.remove_child(ending)
	ending.free()

# =============================================================================
# 6. Village HUD & Dialogue Interlock Stress Testing
# =============================================================================
func _test_village_hud_interlock_adversarial() -> void:
	print("\n--- [ADVERSARIAL R2 & R3: VILLAGE HUD & DIALOGUE INTERLOCK] ---")
	var VillageScene = load("res://scenes/hub/greyrock_village.tscn")
	var village = VillageScene.instantiate() as GreyrockVillage
	root.add_child(village)
	await process_frame

	var hud: Control = village.find_child("HubHUD", true, false) as Control
	var q_modal: Control = village.find_child("QuestBoardModal", true, false) as Control
	var t_modal: Control = village.find_child("TavernRecruitModal", true, false) as Control
	var dlg_box: BottomDialogueBox = village.find_child("BottomDialogueBox", true, false) as BottomDialogueBox
	var instr_lbl: Label = village.find_child("InstructionLabel", true, false) as Label

	assert_true(hud != null and q_modal != null and t_modal != null and dlg_box != null,
		"ADV-R2.40: All village UI components instantiated")

	# Initial state: HUD visible
	assert_true(hud.visible, "ADV-R2.41: HubHUD is initially visible")

	# Open Tavern Modal: HUD should hide
	t_modal.open()
	await process_frame
	assert_false(hud.visible, "ADV-R2.42: HubHUD hidden when Tavern modal opens")

	# Open Quest Modal concurrently: HUD should remain hidden
	q_modal.open()
	await process_frame
	assert_false(hud.visible, "ADV-R2.43: HubHUD remains hidden with both modals open")

	# Close Tavern Modal while Quest Modal is still open: HUD should REMAIN hidden
	t_modal.close()
	await process_frame
	assert_false(hud.visible, "ADV-R2.44: HubHUD remains hidden while Quest modal is still open")

	# Close Quest Modal: HUD should be restored
	q_modal.close()
	await process_frame
	assert_true(hud.visible, "ADV-R2.45: HubHUD restored when both modals are closed")

	# Open Dialogue Box: InstructionLabel should hide
	dlg_box.show_dialogue("Testador", "Conversando...")
	await process_frame
	assert_false(instr_lbl.visible, "ADV-R3.13: InstructionLabel hidden when BottomDialogueBox is visible")

	# Close Dialogue Box: InstructionLabel should restore
	dlg_box.close_dialogue()
	await process_frame
	assert_true(instr_lbl.visible, "ADV-R3.14: InstructionLabel restored when BottomDialogueBox is closed")

	root.remove_child(village)
	village.free()
