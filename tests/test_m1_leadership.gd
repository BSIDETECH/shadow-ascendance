extends SceneTree

## Automated Headless Verification Suite for Milestone 1 (M1):
## Enneagram Personality System, Leadership Orders & Charges, and HUD Dialogue Feed.
## Exit code 0 if all tests pass; 1 if any test fails.

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var failure_details: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run_test_suite")

func _run_test_suite() -> void:
	print("\n" + "=".repeat(75))
	print(" SHADOW CHEAT: SOLO GUILD ASCENDANCE — M1 LEADERSHIP & ENNEAGRAM SUITE")
	print(" Engine: Godot 4.6.1 (Headless Mode)")
	print("=".repeat(75) + "\n")

	var start_ms := Time.get_ticks_msec()

	_test_part1_enneagram_profiles()
	_test_part2_psychological_state_and_stress()
	_test_part3_order_evaluation_outcomes()
	_test_part4_leadership_manager_charges()
	_test_part5_leadership_debounce()
	_test_part6_kill_recharge()
	_test_part7_companion_order_fsm()
	_test_part8_dialogue_feed_queue()
	_test_part9_hud_pips_integration()
	_test_part10_stress_rapid_input_spam()
	_test_part11_stress_zero_charge_spending()
	_test_part12_stress_charge_overflow_protection()
	_test_part13_stress_recharge_precision_and_oracle()
	_test_part14_regression_fixes_and_improvements()

	var elapsed_ms := Time.get_ticks_msec() - start_ms

	print("\n" + "=".repeat(75))
	print(" M1 TEST SUITE SUMMARY")
	print("=".repeat(75))
	print(" Total Tests Evaluated : %d" % total_tests)
	print(" Passed                 : %d" % passed_tests)
	print(" Failed                 : %d" % failed_tests)
	print(" Duration               : %.2f seconds" % (float(elapsed_ms) / 1000.0))
	print("-".repeat(75))

	if failure_details.size() > 0:
		print(" FAILURES DETAIL (%d):" % failure_details.size())
		for idx in range(failure_details.size()):
			var f: Dictionary = failure_details[idx]
			print("   %d. [%s] %s" % [idx + 1, f.get("name", "Unknown"), f.get("reason", "No details")])
		print("-".repeat(75))
		print(">> M1 RESULT: FAILED (Exit Code 1)\n")
		quit(1)
	else:
		print(">> M1 RESULT: ALL TESTS PASSED (Exit Code 0)\n")
		quit(0)

# ==============================================================================
# ASSERTION HELPERS
# ==============================================================================

func record_pass(test_name: String) -> void:
	total_tests += 1
	passed_tests += 1
	print("  [PASS] %s" % test_name)

func record_fail(test_name: String, reason: String) -> void:
	total_tests += 1
	failed_tests += 1
	failure_details.append({"name": test_name, "reason": reason})
	print("  [FAIL] %s -> %s" % [test_name, reason])

func assert_true(cond: bool, test_name: String, msg: String = "") -> bool:
	if cond:
		record_pass(test_name)
		return true
	record_fail(test_name, msg if msg != "" else "Expected true, got false")
	return false

func assert_false(cond: bool, test_name: String, msg: String = "") -> bool:
	if not cond:
		record_pass(test_name)
		return true
	record_fail(test_name, msg if msg != "" else "Expected false, got true")
	return false

func assert_eq(actual: Variant, expected: Variant, test_name: String) -> bool:
	if actual == expected:
		record_pass(test_name)
		return true
	record_fail(test_name, "Expected '%s', got '%s'" % [str(expected), str(actual)])
	return false

func assert_ne(actual: Variant, expected: Variant, test_name: String) -> bool:
	if actual != expected:
		record_pass(test_name)
		return true
	record_fail(test_name, "Expected '%s' != '%s', but both were equal" % [str(actual), str(expected)])
	return false

func assert_almost_eq(actual: float, expected: float, tol: float, test_name: String) -> bool:
	if absf(actual - expected) <= tol:
		record_pass(test_name)
		return true
	record_fail(test_name, "Expected %f +/- %f, got %f" % [expected, tol, actual])
	return false

# ==============================================================================
# PART 1: Enneagram Profiles (Types 1-9)
# ==============================================================================

func _test_part1_enneagram_profiles() -> void:
	print("\n--- [PART 1: ENNEAGRAM PROFILES TYPES 1-9] ---")

	# Verify all 9 types can be generated via create_preset and create_type
	for type_id in range(1, 10):
		var profile := EnneagramData.create_type(type_id)
		assert_true(profile != null, "M1.01.%d: Enneagram Profile Type %d Instantiated" % [type_id, type_id])
		assert_eq(profile.enneagram_type, type_id, "M1.01.%d: Profile Type ID Matches Enum" % type_id)
		assert_true(profile.type_name != "", "M1.01.%d: Profile %d Declares Type Name" % [type_id, type_id])
		assert_true(profile.title != "", "M1.01.%d: Profile %d Declares Title" % [type_id, type_id])
		assert_true(profile.description != "", "M1.01.%d: Profile %d Declares Description" % [type_id, type_id])
		assert_true(profile.dialogue_lines.size() >= 9, "M1.01.%d: Profile %d Has Full Dialogue Dict" % [type_id, type_id])

	# Check distinct trait values
	var t8 := EnneagramData.create_preset(EnneagramData.Type.CHALLENGER)
	assert_eq(t8.base_attack_obedience, 0.95, "M1.02: Type 8 Challenger Has Relentless Attack Tendency (0.95)")
	assert_eq(t8.base_retreat_obedience, 0.20, "M1.03: Type 8 Challenger Has Low Retreat Tendency (0.20)")

	var t2 := EnneagramData.create_preset(EnneagramData.Type.HELPER)
	assert_eq(t2.base_help_obedience, 0.95, "M1.04: Type 2 Helper Has Max Help Tendency (0.95)")
	assert_eq(t2.base_retreat_obedience, 0.50, "M1.05: Type 2 Helper Has Conditional Retreat Tendency (0.50)")

	var t5 := EnneagramData.create_preset(EnneagramData.Type.INVESTIGATOR)
	assert_eq(t5.base_retreat_obedience, 0.85, "M1.06: Type 5 Investigator Prefers Tactical Retreat to Keep Distance (0.85)")
	assert_eq(t5.swarm_panic_threshold, 5, "M1.07: Type 5 Investigator Swarm Threshold is 5 Mobs")

# ==============================================================================
# PART 2: Psychological State Machine & Stress Calculations
# ==============================================================================

func _test_part2_psychological_state_and_stress() -> void:
	print("\n--- [PART 2: PSYCHOLOGICAL STATE MACHINE & STRESS] ---")

	# State thresholds
	assert_eq(EnneagramEvaluator.get_mental_state(0.0), EnneagramEvaluator.MentalState.HEALTHY, "M1.08: Stress 0.0 is HEALTHY")
	assert_eq(EnneagramEvaluator.get_mental_state(49.9), EnneagramEvaluator.MentalState.HEALTHY, "M1.09: Stress 49.9 is HEALTHY")
	assert_eq(EnneagramEvaluator.get_mental_state(50.0), EnneagramEvaluator.MentalState.STRESSED, "M1.10: Stress 50.0 is STRESSED")
	assert_eq(EnneagramEvaluator.get_mental_state(79.9), EnneagramEvaluator.MentalState.STRESSED, "M1.11: Stress 79.9 is STRESSED")
	assert_eq(EnneagramEvaluator.get_mental_state(80.0), EnneagramEvaluator.MentalState.COLLAPSED, "M1.12: Stress 80.0 is COLLAPSED")
	assert_eq(EnneagramEvaluator.get_mental_state(100.0), EnneagramEvaluator.MentalState.COLLAPSED, "M1.13: Stress 100.0 is COLLAPSED")

	# Stress gain from health damage
	var t1 := EnneagramData.create_preset(EnneagramData.Type.REFORMER)
	var ctx := TacticalContext.new()
	ctx.companion_hp_ratio = 0.5 # 50% HP lost
	var stress := EnneagramEvaluator.update_stress(1.0, 0.0, ctx, t1)
	assert_true(stress > 0.0, "M1.14: Companion HP Loss Increases Stress")

	# Stress gain from swarm on Type 5
	var t5 := EnneagramData.create_preset(EnneagramData.Type.INVESTIGATOR)
	var ctx_swarm := TacticalContext.new()
	ctx_swarm.nearby_enemies_count = 10 # 5 above threshold of 5
	var stress_swarm := EnneagramEvaluator.update_stress(1.0, 0.0, ctx_swarm, t5)
	assert_true(stress_swarm > 20.0, "M1.15: Swarm Exceeding Threshold Drastically Raises Type 5 Stress")

	# Calm recovery
	var ctx_calm := TacticalContext.new()
	ctx_calm.nearby_enemies_count = 0
	ctx_calm.companion_hp_ratio = 1.0
	var recovered := EnneagramEvaluator.update_stress(1.0, 50.0, ctx_calm, t1)
	assert_true(recovered < 50.0, "M1.16: Calm Conditions Decay Stress Over Time")

	# Clamping bounds [0.0, 100.0]
	var clamped_high := EnneagramEvaluator.update_stress(100.0, 95.0, ctx_swarm, t5)
	assert_eq(clamped_high, 100.0, "M1.17: Stress Clamped at Exactly 100.0 Max")
	var clamped_low := EnneagramEvaluator.update_stress(100.0, 5.0, ctx_calm, t1)
	assert_eq(clamped_low, 0.0, "M1.18: Stress Clamped at Exactly 0.0 Min")

# ==============================================================================
# PART 3: Order Evaluation Outcomes (OBEY, HESITATE, REFUSE)
# ==============================================================================

func _test_part3_order_evaluation_outcomes() -> void:
	print("\n--- [PART 3: ORGANIC ORDER EVALUATION OUTCOMES] ---")

	# Scenario 1: Type 8 Challenger ordered to RETREAT in front of close enemies -> REFUSE
	var t8 := EnneagramData.create_preset(EnneagramData.Type.CHALLENGER)
	var ctx_t8 := TacticalContext.new()
	ctx_t8.closest_enemy_distance = 60.0
	var res_t8 := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.RETREAT,
		t8,
		EnneagramEvaluator.MentalState.HEALTHY,
		ctx_t8,
		0.0,
		"Valtor"
	)
	assert_eq(res_t8.status, int(EnneagramEvaluator.OrderStatus.REFUSE), "M1.19: Type 8 Refuses Retreat in Front of Enemies")
	assert_true(res_t8.voice_line.contains("costas para lixo"), "M1.20: Type 8 Refusal Emits Defiant Voice Line")
	assert_eq(res_t8.delay_sec, 0.0, "M1.21: Refusal Takes Effect Immediately (0.0s)")

	# Scenario 2: Type 2 Helper ordered to RETREAT while Player HP < 35% -> REFUSE (Martyr syndrome)
	var t2 := EnneagramData.create_preset(EnneagramData.Type.HELPER)
	var ctx_t2 := TacticalContext.new()
	ctx_t2.player_hp_ratio = 0.20
	var res_t2 := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.RETREAT,
		t2,
		EnneagramEvaluator.MentalState.HEALTHY,
		ctx_t2,
		0.0,
		"Lyra"
	)
	assert_eq(res_t2.status, int(EnneagramEvaluator.OrderStatus.REFUSE), "M1.22: Type 2 Refuses Retreat When Player is Low HP")
	assert_true(res_t2.voice_line.contains("Não posso recuar") or res_t2.voice_line.contains("recuar"), "M1.23: Type 2 Martyr Dialogue Triggered")
	var res_t2_s := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.RETREAT,
		t2,
		EnneagramEvaluator.MentalState.STRESSED,
		ctx_t2,
		60.0,
		"Lyra"
	)
	assert_true(res_t2_s.voice_line.contains("jamais vou recuar"), "M1.23b: Type 2 Stressed Martyr Dialogue Triggered")

	# Scenario 3: Type 2 Helper ordered to HELP -> Instant OBEY
	var res_t2_help := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.HELP,
		t2,
		EnneagramEvaluator.MentalState.HEALTHY,
		ctx_t2,
		0.0,
		"Lyra"
	)
	assert_eq(res_t2_help.status, int(EnneagramEvaluator.OrderStatus.OBEY), "M1.24: Type 2 Readily Obeys HELP Order")
	assert_eq(res_t2_help.delay_sec, 0.0, "M1.25: Healthy OBEY Has 0.0s Delay")

	# Scenario 4: Type 1 Reformer ordered to ATTACK under orderly conditions -> OBEY
	var t1 := EnneagramData.create_preset(EnneagramData.Type.REFORMER)
	var ctx_t1 := TacticalContext.new()
	ctx_t1.nearby_enemies_count = 3
	var res_t1 := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.ATTACK,
		t1,
		EnneagramEvaluator.MentalState.HEALTHY,
		ctx_t1,
		0.0,
		"Lyra"
	)
	assert_eq(res_t1.status, int(EnneagramEvaluator.OrderStatus.OBEY), "M1.26: Type 1 Obeys Attack in Good Formation")
	assert_true(res_t1.voice_line.contains("avanço tático com precisão"), "M1.27: Type 1 Precise Tactical Dialogue Triggered")

	# Scenario 5: Hesitation delay scaling across mental states
	var t9 := EnneagramData.create_preset(EnneagramData.Type.PEACEMAKER)
	var ctx_t9 := TacticalContext.new()
	# In Healthy state, score ~ 45 is HESITATE
	var score_h := EnneagramEvaluator.calculate_obedience_score(EnneagramEvaluator.LeadershipOrder.ATTACK, t9, EnneagramEvaluator.MentalState.HEALTHY, ctx_t9, 0.0)
	assert_true(score_h >= 30.0 and score_h < 60.0, "M1.28: Type 9 Attack Score Falls in Hesitation Band (30..60)")

	var res_h := EnneagramEvaluator.evaluate_order(EnneagramEvaluator.LeadershipOrder.ATTACK, t9, EnneagramEvaluator.MentalState.HEALTHY, ctx_t9, 0.0)
	assert_eq(res_h.status, int(EnneagramEvaluator.OrderStatus.HESITATE), "M1.29: Healthy Hesitation Classified Correctly")
	assert_almost_eq(res_h.delay_sec, 0.60, 0.01, "M1.30: Healthy Hesitation Delay is 0.60s")

	var res_s := EnneagramEvaluator.evaluate_order(EnneagramEvaluator.LeadershipOrder.ATTACK, t9, EnneagramEvaluator.MentalState.STRESSED, ctx_t9, 60.0)
	if res_s.status == int(EnneagramEvaluator.OrderStatus.HESITATE):
		assert_almost_eq(res_s.delay_sec, 1.10, 0.01, "M1.31: Stressed Hesitation Delay is 1.10s")
	else:
		assert_eq(res_s.status, int(EnneagramEvaluator.OrderStatus.REFUSE), "M1.31: Stressed Transitioned to Defiance")

var _cached_eb: Node = null
var _cached_lm: Node = null

func _get_event_bus() -> Node:
	if _cached_eb == null:
		_cached_eb = root.get_node_or_null("EventBus")
		if _cached_eb == null:
			var s = load("res://scripts/autoloads/event_bus.gd")
			_cached_eb = s.new()
			_cached_eb.name = "EventBus"
			root.add_child(_cached_eb)
	return _cached_eb

func _get_leadership_manager() -> Node:
	if _cached_lm == null:
		_cached_lm = root.get_node_or_null("LeadershipManager")
		if _cached_lm == null:
			var s = load("res://scripts/autoloads/leadership_manager.gd")
			_cached_lm = s.new()
			_cached_lm.name = "LeadershipManager"
			root.add_child(_cached_lm)
	return _cached_lm

# ==============================================================================
# PART 4: LeadershipManager Charges Pool (Keys 1, 2, 3)
# ==============================================================================

func _test_part4_leadership_manager_charges() -> void:
	print("\n--- [PART 4: LEADERSHIP CHARGES POOL] ---")

	var lm := _get_leadership_manager()
	var eb := _get_event_bus()
	assert_true(lm != null, "M1.32: LeadershipManager AutoLoad Exists")

	lm.reset_charges()
	assert_eq(lm.current_charges, 3, "M1.33: Initial Charges Count is 3")
	assert_eq(lm.max_charges, 3, "M1.34: Max Charges is 3")

	# Track signal emissions
	var charges_history: Array[int] = []
	var record_charge = func(curr: int, _max_c: int): charges_history.append(curr)
	eb.leadership_charges_changed.connect(record_charge)

	# Issue Order 1 (ATTACK)
	var ok1: bool = lm.issue_order(1, Vector2(100, 100))
	assert_true(ok1, "M1.35: First Order Accepted")
	assert_eq(lm.current_charges, 2, "M1.36: Charges Decremented to 2")

	# Advance debounce timer
	lm._debounce_timer = 0.0

	# Issue Order 2 (RETREAT)
	var ok2: bool = lm.issue_order(2, Vector2(50, 50))
	assert_true(ok2, "M1.37: Second Order Accepted")
	assert_eq(lm.current_charges, 1, "M1.38: Charges Decremented to 1")

	lm._debounce_timer = 0.0

	# Issue Order 3 (HELP)
	var ok3: bool = lm.issue_order(3, Vector2(0, 0))
	assert_true(ok3, "M1.39: Third Order Accepted")
	assert_eq(lm.current_charges, 0, "M1.40: Charges Decremented to 0")

	lm._debounce_timer = 0.0

	# Track failure signal
	var fail_box := {"reason": ""}
	var on_fail = func(r: String):
		fail_box["reason"] = r
	eb.leadership_order_failed.connect(on_fail)

	# Issue Order 4 (Empty charges)
	var ok4: bool = lm.issue_order(1, Vector2(100, 100))
	assert_false(ok4, "M1.41: Order with 0 Charges Rejected")
	assert_eq(lm.current_charges, 0, "M1.42: Charges Remain at 0")
	assert_true(fail_box["reason"] != "", "M1.43: leadership_order_failed Signal Emitted")

	eb.leadership_charges_changed.disconnect(record_charge)
	eb.leadership_order_failed.disconnect(on_fail)

# ==============================================================================
# PART 5: Input Debounce Mechanism
# ==============================================================================

func _test_part5_leadership_debounce() -> void:
	print("\n--- [PART 5: INPUT DEBOUNCE] ---")

	var lm := _get_leadership_manager()
	lm.reset_charges()

	# First order sets debounce timer to 0.15s
	var ok1: bool = lm.issue_order(1, Vector2.ZERO)
	assert_true(ok1, "M1.44: First Order Succeeds and Triggers Debounce")
	assert_true(lm._debounce_timer > 0.0, "M1.45: Debounce Timer Active (> 0.0s)")

	# Rapid spam order while debounce timer > 0
	var ok_spam: bool = lm.issue_order(1, Vector2.ZERO)
	assert_false(ok_spam, "M1.46: Rapid Spam Order Blocked by Debounce")
	assert_eq(lm.current_charges, 2, "M1.47: Charges Not Consumed by Blocked Spam")

	# Clear debounce timer and retry
	lm._debounce_timer = 0.0
	var ok2: bool = lm.issue_order(1, Vector2.ZERO)
	assert_true(ok2, "M1.48: Order Accepted After Debounce Expiration")

# ==============================================================================
# PART 6: Kill-based Recharge (10 Kills per Charge)
# ==============================================================================

func _test_part6_kill_recharge() -> void:
	print("\n--- [PART 6: 10-KILL CHARGE RECHARGE] ---")

	var lm := _get_leadership_manager()
	var eb := _get_event_bus()
	lm.reset_charges()
	lm.current_charges = 0
	lm.kills_towards_recharge = 0

	# 9 kills should not restore a charge yet
	for i in range(9):
		eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 0, "M1.49: 9 Kills Do Not Yet Restore Charge")
	assert_eq(lm.kills_towards_recharge, 9, "M1.50: 9 Kills Tracked Towards Recharge")

	# 10th kill must restore exactly 1 charge
	eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 1, "M1.51: 10th Kill Restores 1 Charge (0 -> 1)")
	assert_eq(lm.kills_towards_recharge, 0, "M1.52: Recharge Counter Resets to 0")

	# Another 10 kills (kills 11 through 20)
	for i in range(10):
		eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 2, "M1.53: 20 Kills Restore Second Charge (1 -> 2)")

	# Reach max charges (3)
	for i in range(10):
		eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 3, "M1.54: 30 Kills Restore Third Charge (2 -> 3)")

	# Overflow kills should not exceed max_charges
	for i in range(10):
		eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 3, "M1.55: Charges Clamped at Max (3)")

# ==============================================================================
# PART 7: Companion Tactical Order FSM
# ==============================================================================

func _test_part7_companion_order_fsm() -> void:
	print("\n--- [PART 7: COMPANION TACTICAL ORDER FSM] ---")

	var CompanionScene = load("res://scenes/entities/companion/companion.tscn")
	if CompanionScene == null:
		record_fail("M1.56: Companion Scene Load", "res://scenes/entities/companion/companion.tscn not found")
		return

	var companion = CompanionScene.instantiate()
	root.add_child(companion)

	# Verify default state
	assert_eq(companion.current_tactical_state, Companion.TacticalOrderState.IDLE_FOLLOW, "M1.56: Initial Tactical State is IDLE_FOLLOW")
	assert_eq(companion.sprint_speed, 190.0, "M1.57: Companion Sprint Speed is 190 px/s")

	# Set Type 1 Reformer (Disciplined)
	companion.enneagram_profile = EnneagramData.create_preset(EnneagramData.Type.REFORMER)

	var eb := _get_event_bus()

	# Issue ATTACK order
	var dialogue_box := {"emitted": false, "text": ""}
	var on_dialogue = func(_speaker: String, text: String, _color: Color):
		dialogue_box["emitted"] = true
		dialogue_box["text"] = text
	eb.companion_dialogue_emitted.connect(on_dialogue)

	eb.emit_leadership_order_issued(1, Vector2(200, 100))
	assert_true(dialogue_box["emitted"], "M1.58: Order Received Emits Companion Dialogue")
	assert_eq(companion.current_tactical_state, Companion.TacticalOrderState.ORDER_ATTACK, "M1.59: Companion Enters ORDER_ATTACK State")
	assert_true(companion.order_timer > 0.0, "M1.60: Order Duration Timer Set")

	eb.companion_dialogue_emitted.disconnect(on_dialogue)

	# Switch to Type 8 Challenger and issue RETREAT when enemy is close -> REFUSE
	companion.enneagram_profile = EnneagramData.create_preset(EnneagramData.Type.CHALLENGER)
	# Simulate dummy enemy close to companion
	var dummy_enemy := Node2D.new()
	dummy_enemy.add_to_group("enemies")
	dummy_enemy.global_position = companion.global_position + Vector2(20, 0)
	root.add_child(dummy_enemy)

	companion.current_tactical_state = Companion.TacticalOrderState.ORDER_ATTACK
	eb.emit_leadership_order_issued(2, Vector2.ZERO)

	assert_ne(companion.current_tactical_state, Companion.TacticalOrderState.ORDER_RETREAT, "M1.61: Defiant Companion Did NOT Enter ORDER_RETREAT")

	dummy_enemy.free()
	root.remove_child(companion)
	companion.free()

# ==============================================================================
# PART 8: Dialogue Feed Queue Management
# ==============================================================================

func _test_part8_dialogue_feed_queue() -> void:
	print("\n--- [PART 8: HUD DIALOGUE FEED QUEUE] ---")

	var FeedScene = load("res://scenes/ui/dialogue_feed/dialogue_feed.tscn")
	assert_true(FeedScene != null, "M1.62: DialogueFeed Scene Loads Cleanly")

	var feed = FeedScene.instantiate()
	root.add_child(feed)

	# Verify mouse filter non-blocking
	assert_eq(feed.mouse_filter, Control.MOUSE_FILTER_IGNORE, "M1.63: DialogueFeed Ignores Mouse Clicks (Twin-Stick Friendly)")

	# Post messages up to cap
	feed.post_message("Lyra", "Mensagem 1", DialogueCard.Status.OBEY)
	feed.post_message("Lyra", "Mensagem 2", DialogueCard.Status.HESITATE)
	feed.post_message("Lyra", "Mensagem 3", DialogueCard.Status.REFUSE)
	feed.post_message("Lyra", "Mensagem 4", DialogueCard.Status.INFO)

	assert_eq(feed._active_cards.size(), 4, "M1.64: Dialogue Feed Holds 4 Messages")

	# Post 5th message -> must evict oldest and maintain max 4
	feed.post_message("Lyra", "Mensagem 5 (Overflow)", DialogueCard.Status.OBEY)
	assert_true(feed._active_cards.size() <= 4, "M1.65: Queue Enforces Strict Max 4 Simultaneous Cards")

	root.remove_child(feed)
	feed.free()

# ==============================================================================
# PART 9: HUD 3-Pip Leadership Display
# ==============================================================================

func _test_part9_hud_pips_integration() -> void:
	print("\n--- [PART 9: HUD 3-PIP LEADERSHIP INTEGRATION] ---")

	var HUDScene = load("res://scenes/ui/hud/hud.tscn")
	assert_true(HUDScene != null, "M1.66: HUD Scene Loads Cleanly")

	var hud = HUDScene.instantiate()
	root.add_child(hud)

	# Verify pips existence
	assert_true(hud.pip1 != null and hud.pip2 != null and hud.pip3 != null, "M1.67: HUD Contains 3 Segmented Leadership Pips")
	assert_true(hud.charges_count_label != null, "M1.68: HUD Contains Charges Count Label")
	assert_true(hud.dialogue_feed != null, "M1.69: HUD Contains Integrated DialogueFeed Instance")

	# Test signal reaction
	var eb := _get_event_bus()
	eb.emit_leadership_charges_changed(2, 3)
	assert_eq(hud.charges_count_label.text, "[ 2/3 ]", "M1.70: HUD Updates Label to [ 2/3 ] on Signal")

	eb.emit_leadership_charges_changed(0, 3)
	assert_eq(hud.charges_count_label.text, "[ 0/3 ]", "M1.71: HUD Updates Label to [ 0/3 ] on Signal")

	# Test error shake triggering safely
	hud.play_leadership_error_shake()
	assert_true(hud._shake_tween != null and hud._shake_tween.is_valid(), "M1.72: Leadership Error Shake Tween Created Smoothly")

	root.remove_child(hud)
	hud.free()

# ==============================================================================
# PART 10: STRESS: RAPID INPUT SPAM & DEBOUNCE REJECTION (< 0.15s)
# ==============================================================================

func _test_part10_stress_rapid_input_spam() -> void:
	print("\n--- [PART 10: STRESS: RAPID INPUT SPAM & DEBOUNCE REJECTION] ---")

	var lm := _get_leadership_manager()
	var eb := _get_event_bus()
	lm.reset_charges()

	# 10.1 Boundary timing test
	var ok_initial: bool = lm.issue_order(1, Vector2.ZERO)
	assert_true(ok_initial, "STRESS.SPAM.01: Initial order at t=0.0s accepted")
	assert_eq(lm.current_charges, 2, "STRESS.SPAM.02: Charges decremented to 2")
	assert_almost_eq(lm._debounce_timer, 0.15, 0.001, "STRESS.SPAM.03: Debounce timer initialized to 0.15s")

	# Instant repeat
	assert_false(lm.issue_order(1, Vector2.ZERO), "STRESS.SPAM.04: Instant repeat at t=0.000s rejected")
	assert_eq(lm.current_charges, 2, "STRESS.SPAM.05: Charges untouched at t=0.000s")

	# Decay to t = 0.05s
	lm._process(0.05)
	assert_almost_eq(lm._debounce_timer, 0.10, 0.001, "STRESS.SPAM.06: Debounce timer decays to 0.10s")
	assert_false(lm.issue_order(2, Vector2.ZERO), "STRESS.SPAM.07: Order 2 rejected at t=0.05s (< 0.15s)")
	assert_eq(lm.current_charges, 2, "STRESS.SPAM.08: Charges untouched at t=0.05s")

	# Decay to t = 0.10s
	lm._process(0.05)
	assert_almost_eq(lm._debounce_timer, 0.05, 0.001, "STRESS.SPAM.09: Debounce timer decays to 0.05s")
	assert_false(lm.issue_order(3, Vector2.ZERO), "STRESS.SPAM.10: Order 3 rejected at t=0.10s (< 0.15s)")
	assert_eq(lm.current_charges, 2, "STRESS.SPAM.11: Charges untouched at t=0.10s")

	# Decay to t = 0.149s boundary
	lm._process(0.049)
	assert_true(lm._debounce_timer > 0.0, "STRESS.SPAM.12: Debounce timer strictly > 0 at t=0.149s")
	assert_false(lm.issue_order(1, Vector2.ZERO), "STRESS.SPAM.13: Order 1 rejected at t=0.149s boundary")
	assert_eq(lm.current_charges, 2, "STRESS.SPAM.14: Charges untouched at t=0.149s")

	# Expire debounce at t = 0.151s
	lm._process(0.002)
	assert_eq(lm._debounce_timer, 0.0, "STRESS.SPAM.15: Debounce timer reached 0.0s")
	assert_true(lm.issue_order(2, Vector2.ZERO), "STRESS.SPAM.16: Order 2 accepted after debounce expired")
	assert_eq(lm.current_charges, 1, "STRESS.SPAM.17: Charges decremented from 2 to 1")

	# 10.2 High-Throughput 1,000 Call Spam Burst
	var orders_issued_signals: Array[Dictionary] = []
	var on_order_issued = func(o: int, t: Vector2):
		orders_issued_signals.append({"type": o, "target": t})
	eb.leadership_order_issued.connect(on_order_issued)

	var spam_accepted_count: int = 0
	for i in range(1000):
		var order_candidate: int = (i % 3) + 1
		lm._process(0.00001)
		if lm.issue_order(order_candidate, Vector2(i, i)):
			spam_accepted_count += 1

	assert_eq(spam_accepted_count, 0, "STRESS.SPAM.18: 1,000 rapid spam calls strictly rejected (0 accepted)")
	assert_eq(orders_issued_signals.size(), 0, "STRESS.SPAM.19: Zero leadership_order_issued signals emitted during spam")
	assert_eq(lm.current_charges, 1, "STRESS.SPAM.20: Zero charges leaked during 1,000 spam burst")

	eb.leadership_order_issued.disconnect(on_order_issued)

	# 10.3 Rapid Alternating Command Key Spam via _unhandled_input
	lm.reset_charges()
	var attack_event := InputEventKey.new()
	attack_event.physical_keycode = KEY_1
	attack_event.pressed = true

	var retreat_event := InputEventKey.new()
	retreat_event.physical_keycode = KEY_2
	retreat_event.pressed = true

	var help_event := InputEventKey.new()
	help_event.physical_keycode = KEY_3
	help_event.pressed = true

	lm._unhandled_input(attack_event)
	assert_eq(lm.current_charges, 2, "STRESS.SPAM.21: InputEvent KEY_1 consumed 1 charge")

	lm._unhandled_input(retreat_event)
	lm._unhandled_input(help_event)
	lm._unhandled_input(attack_event)
	assert_eq(lm.current_charges, 2, "STRESS.SPAM.22: Alternating keys rejected by debounce via _unhandled_input")

	lm._process(0.16)
	lm._unhandled_input(retreat_event)
	assert_eq(lm.current_charges, 1, "STRESS.SPAM.23: KEY_2 accepted after debounce expiration")

	lm._process(0.16)
	lm._unhandled_input(help_event)
	assert_eq(lm.current_charges, 0, "STRESS.SPAM.24: KEY_3 accepted after debounce expiration")

# ==============================================================================
# PART 11: STRESS: ZERO CHARGE SPENDING & SIGNAL SUPPRESSION
# ==============================================================================

func _test_part11_stress_zero_charge_spending() -> void:
	print("\n--- [PART 11: STRESS: ZERO CHARGE SPENDING & SIGNAL SUPPRESSION] ---")

	var lm := _get_leadership_manager()
	var eb := _get_event_bus()

	lm.reset_charges()
	lm.current_charges = 0
	lm._debounce_timer = 0.0

	var emitted_orders: Array[int] = []
	var emitted_charge_changes: Array[int] = []
	var failed_reasons: Array[String] = []

	var on_order = func(o: int, _t: Vector2): emitted_orders.append(o)
	var on_charge = func(curr: int, _max_c: int): emitted_charge_changes.append(curr)
	var on_fail = func(r: String): failed_reasons.append(r)

	eb.leadership_order_issued.connect(on_order)
	eb.leadership_charges_changed.connect(on_charge)
	eb.leadership_order_failed.connect(on_fail)

	# 11.1 Test Order 1 (ATTACK) at 0 charges
	var ok_attack: bool = lm.issue_order(1, Vector2.ZERO)
	assert_false(ok_attack, "STRESS.ZERO.01: Attack order at 0 charges returned false")
	assert_eq(lm.current_charges, 0, "STRESS.ZERO.02: Charges stayed at 0")
	assert_eq(emitted_orders.size(), 0, "STRESS.ZERO.03: leadership_order_issued was NOT emitted")
	assert_eq(failed_reasons.size(), 1, "STRESS.ZERO.04: leadership_order_failed emitted once")

	lm._debounce_timer = 0.0

	# 11.2 Test Order 2 (RETREAT) at 0 charges
	var ok_retreat: bool = lm.issue_order(2, Vector2.ZERO)
	assert_false(ok_retreat, "STRESS.ZERO.05: Retreat order at 0 charges returned false")
	assert_eq(lm.current_charges, 0, "STRESS.ZERO.06: Charges stayed at 0")
	assert_eq(emitted_orders.size(), 0, "STRESS.ZERO.07: leadership_order_issued was NOT emitted")
	assert_eq(failed_reasons.size(), 2, "STRESS.ZERO.08: leadership_order_failed emitted for retreat")

	lm._debounce_timer = 0.0

	# 11.3 Test Order 3 (HELP) at 0 charges
	var ok_help: bool = lm.issue_order(3, Vector2.ZERO)
	assert_false(ok_help, "STRESS.ZERO.09: Help order at 0 charges returned false")
	assert_eq(lm.current_charges, 0, "STRESS.ZERO.10: Charges stayed at 0")
	assert_eq(emitted_orders.size(), 0, "STRESS.ZERO.11: leadership_order_issued was NOT emitted")
	assert_eq(failed_reasons.size(), 3, "STRESS.ZERO.12: leadership_order_failed emitted for help")

	# 11.4 High-Volume 1,000 Stress Hammering at 0 Charges
	var hammer_accepted_count: int = 0
	for i in range(1000):
		var order_candidate: int = (i % 3) + 1
		if i % 2 == 0:
			lm._debounce_timer = 0.0
		else:
			lm._process(0.01)

		if lm.issue_order(order_candidate, Vector2.ZERO):
			hammer_accepted_count += 1

		if lm.current_charges < 0:
			record_fail("STRESS.ZERO.13: Invariant Violation", "Charges dropped below 0 to %d" % lm.current_charges)
			break

	assert_eq(hammer_accepted_count, 0, "STRESS.ZERO.14: 1,000 attempts at 0 charges all rejected")
	assert_eq(lm.current_charges, 0, "STRESS.ZERO.15: Charges strictly clamped at 0 after 1,000 attempts")
	assert_eq(emitted_orders.size(), 0, "STRESS.ZERO.16: Zero orders issued during 1,000 zero-charge attempts")

	var found_negative: bool = false
	for c in emitted_charge_changes:
		if c < 0:
			found_negative = true
	assert_false(found_negative, "STRESS.ZERO.17: No leadership_charges_changed signals with negative value")

	eb.leadership_order_issued.disconnect(on_order)
	eb.leadership_charges_changed.disconnect(on_charge)
	eb.leadership_order_failed.disconnect(on_fail)

# ==============================================================================
# PART 12: STRESS: CHARGE OVERFLOW PROTECTION & CLAMPING AT MAX (3)
# ==============================================================================

func _test_part12_stress_charge_overflow_protection() -> void:
	print("\n--- [PART 12: STRESS: CHARGE OVERFLOW PROTECTION & CLAMPING AT MAX (3)] ---")

	var lm := _get_leadership_manager()
	var eb := _get_event_bus()

	lm.reset_charges()
	assert_eq(lm.current_charges, 3, "STRESS.OVERFLOW.01: Initialized at MAX_CHARGES (3)")

	var charge_changes: Array[int] = []
	var on_charge = func(curr: int, _max_c: int): charge_changes.append(curr)
	eb.leadership_charges_changed.connect(on_charge)

	# 12.1 Kill 10 enemies while at 3 charges
	for i in range(10):
		eb.emit_enemy_died(Vector2.ZERO, 10)
	assert_eq(lm.current_charges, 3, "STRESS.OVERFLOW.02: 10 kills at max charges stays clamped at 3")
	assert_eq(charge_changes.size(), 0, "STRESS.OVERFLOW.03: Zero spurious charges_changed signals emitted")

	# 12.2 Kill 20 more enemies (30 total kills at max)
	for i in range(20):
		eb.emit_enemy_died(Vector2.ZERO, 10)
	assert_eq(lm.current_charges, 3, "STRESS.OVERFLOW.04: 30 total kills at max charges stays clamped at 3")
	assert_eq(charge_changes.size(), 0, "STRESS.OVERFLOW.05: Still zero spurious charges_changed signals")

	# 12.3 Burst of 1,000 kills at max charges
	for i in range(1000):
		eb.emit_enemy_died(Vector2.ZERO, 10)
		if lm.current_charges > 3:
			record_fail("STRESS.OVERFLOW.06: Overflow Invariant Breached", "Charges exceeded 3: %d" % lm.current_charges)
			break

	assert_eq(lm.current_charges, 3, "STRESS.OVERFLOW.07: 1,000 kills burst at max charges strictly clamped at 3")
	assert_eq(charge_changes.size(), 0, "STRESS.OVERFLOW.08: Zero spurious signals during 1,000 kills burst")

	# 12.4 Direct API overflow stress
	lm.add_charge(1)
	assert_eq(lm.current_charges, 3, "STRESS.OVERFLOW.09: add_charge(1) at max clamped at 3")
	lm.add_charge(10)
	assert_eq(lm.current_charges, 3, "STRESS.OVERFLOW.10: add_charge(10) at max clamped at 3")
	lm.add_charge(999999)
	assert_eq(lm.current_charges, 3, "STRESS.OVERFLOW.11: add_charge(999999) at max clamped at 3")

	eb.leadership_charges_changed.disconnect(on_charge)

# ==============================================================================
# PART 13: STRESS: RECHARGE PRECISION & 5,000-STEP STOCHASTIC ORACLE
# ==============================================================================

func _test_part13_stress_recharge_precision_and_oracle() -> void:
	print("\n--- [PART 13: STRESS: RECHARGE PRECISION & STOCHASTIC ORACLE] ---")

	var lm := _get_leadership_manager()
	var eb := _get_event_bus()

	# 13.1 Granular Step-by-Step Cadence Test
	lm.reset_charges()
	lm.current_charges = 0
	lm.kills_towards_recharge = 0

	var recharge_events: Array[Dictionary] = []
	var on_recharge = func(curr: int, _max_c: int):
		recharge_events.append({"curr": curr, "total_kills": lm.kills_towards_recharge})
	eb.leadership_charges_changed.connect(on_recharge)

	# Cycle 1: Kills 1 to 10
	for k in range(1, 10):
		eb.emit_enemy_died(Vector2.ZERO, 5)
		assert_eq(lm.current_charges, 0, "STRESS.PRECISION.01: Kill %d did not recharge early" % k)
		assert_eq(lm.kills_towards_recharge, k, "STRESS.PRECISION.02: Kills counter matches %d" % k)
	assert_eq(recharge_events.size(), 0, "STRESS.PRECISION.03: Zero recharge events before 10th kill")

	eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 1, "STRESS.PRECISION.04: 10th kill restored exactly 1 charge")
	assert_eq(lm.kills_towards_recharge, 0, "STRESS.PRECISION.05: Counter reset to 0 on 10th kill")
	assert_eq(recharge_events.size(), 1, "STRESS.PRECISION.06: Exactly 1 recharge signal on 10th kill")

	# Cycle 2: Kills 11 to 20
	for k in range(1, 10):
		eb.emit_enemy_died(Vector2.ZERO, 5)
		assert_eq(lm.current_charges, 1, "STRESS.PRECISION.07: Kill %d of cycle 2 did not recharge early" % k)
	eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 2, "STRESS.PRECISION.08: 20th kill restored 2nd charge")
	assert_eq(recharge_events.size(), 2, "STRESS.PRECISION.09: Exactly 2 recharge signals total")

	# Cycle 3: Kills 21 to 30
	for k in range(1, 10):
		eb.emit_enemy_died(Vector2.ZERO, 5)
		assert_eq(lm.current_charges, 2, "STRESS.PRECISION.10: Kill %d of cycle 3 did not recharge early" % k)
	eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 3, "STRESS.PRECISION.11: 30th kill restored 3rd charge (max)")
	assert_eq(recharge_events.size(), 3, "STRESS.PRECISION.12: Exactly 3 recharge signals total")

	eb.leadership_charges_changed.disconnect(on_recharge)

	# 13.2 Partial Cycle Continuity Across Order Spending
	for i in range(6):
		eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 3, "STRESS.PRECISION.13: Still at max charges")
	assert_eq(lm.kills_towards_recharge, 6, "STRESS.PRECISION.14: 6 kills accumulated in current cycle")

	lm._debounce_timer = 0.0
	var spent_ok: bool = lm.issue_order(1, Vector2.ZERO)
	assert_true(spent_ok, "STRESS.PRECISION.15: Order spent successfully")
	assert_eq(lm.current_charges, 2, "STRESS.PRECISION.16: Charges now 2")
	assert_eq(lm.kills_towards_recharge, 6, "STRESS.PRECISION.17: Accumulated cycle kills preserved across spend")

	for i in range(3):
		eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 2, "STRESS.PRECISION.18: 9 total cycle kills does not yet restore")
	assert_eq(lm.kills_towards_recharge, 9, "STRESS.PRECISION.19: Counter reached 9")

	eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 3, "STRESS.PRECISION.20: 10th kill restored charge back to 3")
	assert_eq(lm.kills_towards_recharge, 0, "STRESS.PRECISION.21: Counter reset to 0 after cycle completion")

	# 13.3 5,000-Step Stochastic Oracle Monte Carlo Simulation
	lm.reset_charges()
	var oracle_charges: int = 3
	var oracle_kills_in_cycle: int = 0
	var oracle_debounce: float = 0.0
	var oracle_total_orders: int = 0

	var rng := RandomNumberGenerator.new()
	rng.seed = 987654321

	var oracle_discrepancy: bool = false
	var step_failure_msg: String = ""

	for step in range(5000):
		var action: int = rng.randi_range(0, 2)

		match action:
			0:
				var delta: float = rng.randf_range(0.01, 0.20)
				lm._process(delta)
				oracle_debounce = maxf(0.0, oracle_debounce - delta)

			1:
				var kill_count: int = rng.randi_range(1, 5)
				for k in range(kill_count):
					eb.emit_enemy_died(Vector2.ZERO, 10)
					oracle_kills_in_cycle += 1
					if oracle_kills_in_cycle >= 10:
						oracle_kills_in_cycle -= 10
						if oracle_charges < 3:
							oracle_charges += 1

			2:
				var order_type: int = rng.randi_range(1, 3)
				var expected_success: bool = (oracle_debounce <= 0.0) and (oracle_charges > 0)
				var actual_success: bool = lm.issue_order(order_type, Vector2.ZERO)

				if expected_success != actual_success:
					oracle_discrepancy = true
					step_failure_msg = "Step %d: Order success mismatch! Expected %s, got %s (oracle charges=%d, deb=%.3f | lm charges=%d, deb=%.3f)" % [
						step, str(expected_success), str(actual_success),
						oracle_charges, oracle_debounce, lm.current_charges, lm._debounce_timer
					]
					break

				if expected_success:
					oracle_charges -= 1
					oracle_debounce = 0.15
					oracle_total_orders += 1
				else:
					if oracle_charges <= 0 and oracle_debounce <= 0.0:
						oracle_debounce = 0.15

		if lm.current_charges != oracle_charges:
			oracle_discrepancy = true
			step_failure_msg = "Step %d: Charge count mismatch! Oracle=%d, LM=%d" % [step, oracle_charges, lm.current_charges]
			break

		if lm.kills_towards_recharge != oracle_kills_in_cycle:
			oracle_discrepancy = true
			step_failure_msg = "Step %d: Kills in cycle mismatch! Oracle=%d, LM=%d" % [step, oracle_kills_in_cycle, lm.kills_towards_recharge]
			break

		if lm.current_charges < 0 or lm.current_charges > 3:
			oracle_discrepancy = true
			step_failure_msg = "Step %d: LM charges out of bounds [0, 3]: %d" % [step, lm.current_charges]
			break

		if lm.kills_towards_recharge < 0 or lm.kills_towards_recharge >= 10:
			oracle_discrepancy = true
			step_failure_msg = "Step %d: LM kills towards recharge out of bounds [0, 9]: %d" % [step, lm.kills_towards_recharge]
			break

	assert_false(oracle_discrepancy, "STRESS.PRECISION.22: 5,000-Step Stochastic Oracle Model Invariant Check", step_failure_msg)
	assert_eq(lm.current_charges, oracle_charges, "STRESS.PRECISION.23: Final charges match oracle after 5,000 steps")
	assert_eq(lm.kills_towards_recharge, oracle_kills_in_cycle, "STRESS.PRECISION.24: Final kills cycle matches oracle after 5,000 steps")

# ==============================================================================
# PART 14: Regression Fixes & Quality Improvements
# ==============================================================================

func _test_part14_regression_fixes_and_improvements() -> void:
	print("\n--- [PART 14: REGRESSION FIXES & QUALITY IMPROVEMENTS] ---")

	# 14.1 Defect 1: Negative charge underflow clamped to 0
	var lm := _get_leadership_manager()
	lm.reset_charges()
	lm.add_charge(-10)
	assert_eq(lm.current_charges, 0, "M1.73: LeadershipManager.add_charge(-10) clamped strictly to 0 (No underflow)")
	lm.add_charge(-5)
	assert_eq(lm.current_charges, 0, "M1.74: LeadershipManager.add_charge(-5) maintains 0")

	# 14.2 Defect 2: Stress modifier formula inversion guarded against default/zero stress
	var t1 := EnneagramData.create_preset(EnneagramData.Type.REFORMER)
	var ctx := TacticalContext.new()
	ctx.nearby_enemies_count = 5
	var score_healthy := EnneagramEvaluator.calculate_obedience_score(
		1, t1, EnneagramEvaluator.MentalState.HEALTHY, ctx, 0.0
	)
	var score_collapsed := EnneagramEvaluator.calculate_obedience_score(
		1, t1, EnneagramEvaluator.MentalState.COLLAPSED, ctx, 0.0
	)
	var score_stressed := EnneagramEvaluator.calculate_obedience_score(
		1, t1, EnneagramEvaluator.MentalState.STRESSED, ctx, 0.0
	)
	assert_true(score_collapsed < score_healthy, "M1.75: Collapsed obedience strictly less than Healthy at default 0.0 stress")
	assert_true(score_stressed < score_healthy, "M1.76: Stressed obedience strictly less than Healthy at default 0.0 stress")

	# 14.3 Improvement 1: Companion hesitation timer and pending order reset on new order
	var CompanionScene = load("res://scenes/entities/companion/companion.tscn")
	var comp = CompanionScene.instantiate()
	root.add_child(comp)
	comp.hesitation_timer = 2.5
	comp.pending_order_after_hesitation = 1
	comp._pending_order = 1
	# Emit new retreat order
	comp._on_leadership_order_issued(2, Vector2(50, 50))
	assert_ne(comp.pending_order_after_hesitation, 1, "M1.77: Stale pending order 1 successfully cleared on new order")
	root.remove_child(comp)
	comp.free()

	# 14.4 Improvement 2: LeadershipManager property & method aliases
	lm.reset_charges()
	assert_eq(lm.charges, 3, "M1.78: lm.charges getter returns 3")
	lm.charges = 2
	assert_eq(lm.current_charges, 2, "M1.79: lm.charges setter updates current_charges to 2")
	var spent: bool = bool(lm.consume_charge())
	assert_true(spent, "M1.80: lm.consume_charge() returns true")
	assert_eq(lm.charges, 1, "M1.81: lm.charges decremented to 1")
	lm.consume_charge()
	assert_eq(lm.charges, 0, "M1.82: lm.charges decremented to 0")
	var spent_empty: bool = bool(lm.consume_charge())
	assert_false(spent_empty, "M1.83: lm.consume_charge() at 0 returns false")
	assert_eq(lm.charges, 0, "M1.84: lm.charges stays at 0")

	# notify_kill alias
	for k in range(10):
		lm.notify_kill()
	assert_eq(lm.charges, 1, "M1.85: 10 calls to notify_kill() recharges 1 charge")
	lm.reset_charges()


