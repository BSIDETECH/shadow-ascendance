extends SceneTree

## Empirical Adversarial Stress Test Suite for Milestone 1 (M1)
## Author: challenger_m1_2 (Adversarial Critic & Domain Specialist)
##
## Stress-tests:
## 1. Complete 9-Personality Preset Matrix (Types 1-9) across Healthy, Stressed, Collapsed
## 2. Extreme Tactical Contexts (HP=0, HP=1, Overheal, 50 mobs, 500 mobs, distance boundaries)
## 3. Archetype Invariants (Type 8 retreat refusal, Type 2 critical HP martyrdom & help, Type 5 swarm freeze)
## 4. Deterministic Seed Consistency & Reproducibility (Monte Carlo generator with fixed seed)
## 5. Fuzzing & Invalid Input Handling (null profiles, null contexts, out-of-range enums, negative/NaN parameters)
## 6. Live Companion Node FSM & EventBus Integration Under Rapid Operations

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var findings: Array[Dictionary] = []

var _cached_eb: Node = null
var _cached_lm: Node = null

func _init() -> void:
	call_deferred("_execute_adversarial_suite")

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

func assert_true(cond: bool, test_name: String, msg: String = "", severity: String = "HIGH") -> bool:
	if cond:
		record_pass(test_name)
		return true
	record_fail(test_name, msg if msg != "" else "Expected true, got false", severity)
	return false

func assert_false(cond: bool, test_name: String, msg: String = "", severity: String = "HIGH") -> bool:
	if not cond:
		record_pass(test_name)
		return true
	record_fail(test_name, msg if msg != "" else "Expected false, got true", severity)
	return false

func assert_eq(actual: Variant, expected: Variant, test_name: String, severity: String = "HIGH") -> bool:
	if actual == expected:
		record_pass(test_name)
		return true
	record_fail(test_name, "Expected '%s', got '%s'" % [str(expected), str(actual)], severity)
	return false

func assert_ne(actual: Variant, expected: Variant, test_name: String, severity: String = "HIGH") -> bool:
	if actual != expected:
		record_pass(test_name)
		return true
	record_fail(test_name, "Expected '%s' != '%s', but both were equal" % [str(actual), str(expected)], severity)
	return false

func assert_in_range(val: float, min_val: float, max_val: float, test_name: String, severity: String = "HIGH") -> bool:
	if is_nan(val) or is_inf(val):
		record_fail(test_name, "Value is NaN or INF (%f)" % val, "CRITICAL")
		return false
	if val >= min_val and val <= max_val:
		record_pass(test_name)
		return true
	record_fail(test_name, "Value %f out of range [%f, %f]" % [val, min_val, max_val], severity)
	return false

func _execute_adversarial_suite() -> void:
	print("\n" + "=".repeat(80))
	print(" SHADOW CHEAT: SOLO GUILD ASCENDANCE — ADVERSARIAL STRESS TEST SUITE (M1)")
	print(" Engine: Godot 4.6.1 (Headless)")
	print(" Executed by: challenger_m1_2")
	print("=".repeat(80) + "\n")

	var start_time := Time.get_ticks_msec()

	_run_part1_preset_matrix_tests()
	_run_part2_extreme_tactical_contexts()
	_run_part3_archetype_invariants()
	_run_part4_deterministic_seed_generator()
	_run_part5_fuzzing_and_invalid_inputs()
	_run_part6_live_companion_lifecycle()

	var elapsed_ms := Time.get_ticks_msec() - start_time

	print("\n" + "=".repeat(80))
	print(" ADVERSARIAL STRESS SUITE RESULTS")
	print("=".repeat(80))
	print(" Total Assertions Evaluated : %d" % total_assertions)
	print(" Passed                      : %d" % passed_assertions)
	print(" Failed                      : %d" % failed_assertions)
	print(" Execution Time              : %.2f seconds" % (float(elapsed_ms) / 1000.0))
	print("-".repeat(80))

	if findings.size() > 0:
		print(" DISCOVERED FINDINGS / VULNERABILITIES (%d):" % findings.size())
		for i in range(findings.size()):
			var f: Dictionary = findings[i]
			print("   %d. [%s] %s -> %s" % [i + 1, f.get("severity", "UNKNOWN"), f.get("name", "Unknown"), f.get("detail", "")])
		print("-".repeat(80))
		printerr(">>> ADVERSARIAL VERDICT: REQUEST_CHANGES (Exit Code 1)\n")
		quit(1)
	else:
		print(" ALL ADVERSARIAL CHALLENGES WITHSTOOD SUCCESSFULLY!")
		print(">>> ADVERSARIAL VERDICT: APPROVE (Exit Code 0)\n")
		quit(0)

# ==============================================================================
# PART 1: 9-Personality Preset Matrix (Types 1-9 x 3 States x 3 Orders)
# ==============================================================================

func _run_part1_preset_matrix_tests() -> void:
	print("\n--- [PART 1: 9-PRESET MATRIX (TYPES 1-9 x HEALTHY/STRESSED/COLLAPSED x 3 ORDERS)] ---")

	var orders := [
		EnneagramEvaluator.LeadershipOrder.ATTACK,
		EnneagramEvaluator.LeadershipOrder.RETREAT,
		EnneagramEvaluator.LeadershipOrder.HELP
	]
	var states := [
		{"state": EnneagramEvaluator.MentalState.HEALTHY, "stress": 15.0, "name": "HEALTHY"},
		{"state": EnneagramEvaluator.MentalState.STRESSED, "stress": 65.0, "name": "STRESSED"},
		{"state": EnneagramEvaluator.MentalState.COLLAPSED, "stress": 90.0, "name": "COLLAPSED"}
	]

	var context := TacticalContext.new()
	context.companion_hp_ratio = 0.8
	context.player_hp_ratio = 0.8
	context.nearby_enemies_count = 2
	context.closest_enemy_distance = 150.0

	for type_id in range(1, 10):
		var profile := EnneagramData.create_type(type_id)
		assert_true(profile != null, "PresetMatrix: Type %d profile instantiation" % type_id)

		for s_info in states:
			var m_state: EnneagramEvaluator.MentalState = s_info["state"]
			var stress_val: float = s_info["stress"]
			var s_name: String = s_info["name"]

			for order in orders:
				var o_str: String = EnneagramEvaluator.get_order_string(order)
				var tag := "Type%d_%s_%s" % [type_id, s_name, o_str]

				var res: OrderResult = EnneagramEvaluator.evaluate_order(
					order, profile, m_state, context, stress_val, profile.type_name
				)

				# Non-null & valid container
				assert_true(res != null, "Matrix.%s: OrderResult non-null" % tag)
				assert_true(res.status in [0, 1, 2], "Matrix.%s: Status in [OBEY, HESITATE, REFUSE] (got %d)" % [tag, res.status])
				assert_in_range(res.raw_score, 0.0, 100.0, "Matrix.%s: Score bounded [0..100]" % tag)
				assert_in_range(res.delay_sec, 0.0, 5.0, "Matrix.%s: Delay non-negative and finite" % tag)

				# Status/Delay integrity invariants
				if res.status == int(EnneagramEvaluator.OrderStatus.OBEY):
					if m_state == EnneagramEvaluator.MentalState.HEALTHY:
						assert_eq(res.delay_sec, 0.0, "Matrix.%s: Healthy OBEY must have 0.0s delay" % tag)
				elif res.status == int(EnneagramEvaluator.OrderStatus.REFUSE):
					assert_eq(res.delay_sec, 0.0, "Matrix.%s: Immediate refusal (0.0s delay)" % tag)
				elif res.status == int(EnneagramEvaluator.OrderStatus.HESITATE):
					assert_true(res.delay_sec > 0.0, "Matrix.%s: Hesitation requires positive delay (>0.0s)" % tag)

				# Voice line & BBCode Color integrity
				assert_true(res.voice_line != "", "Matrix.%s: Voice line non-empty" % tag)
				assert_ne(res.voice_line, "Ordem processada.", "Matrix.%s: Must use authentic dialogue, not unconfigured fallback" % tag, "MEDIUM")
				assert_true(res.bbcode_color.a > 0.0, "Matrix.%s: Color has positive alpha" % tag)

# ==============================================================================
# PART 2: Extreme Tactical Contexts Stress Test
# ==============================================================================

func _run_part2_extreme_tactical_contexts() -> void:
	print("\n--- [PART 2: EXTREME TACTICAL CONTEXTS STRESS TEST] ---")

	var extreme_cases: Array[Dictionary] = [
		{"name": "Companion_HP_Zero", "c_hp": 0.0, "p_hp": 1.0, "mobs": 0, "dist": 999.0, "freq": 0.0},
		{"name": "Companion_HP_Full", "c_hp": 1.0, "p_hp": 1.0, "mobs": 0, "dist": 999.0, "freq": 0.0},
		{"name": "Companion_HP_Overheal", "c_hp": 2.5, "p_hp": 1.0, "mobs": 0, "dist": 999.0, "freq": 0.0},
		{"name": "Companion_HP_Negative", "c_hp": -1.0, "p_hp": 1.0, "mobs": 0, "dist": 999.0, "freq": 0.0},
		{"name": "Player_HP_Zero", "c_hp": 1.0, "p_hp": 0.0, "mobs": 0, "dist": 999.0, "freq": 0.0},
		{"name": "Player_HP_Critical_10pct", "c_hp": 1.0, "p_hp": 0.10, "mobs": 2, "dist": 100.0, "freq": 0.0},
		{"name": "Swarm_50_Mobs", "c_hp": 1.0, "p_hp": 1.0, "mobs": 50, "dist": 50.0, "freq": 0.0},
		{"name": "Swarm_500_Mobs", "c_hp": 0.5, "p_hp": 0.5, "mobs": 500, "dist": 10.0, "freq": 0.0},
		{"name": "Enemy_In_Face_0px", "c_hp": 1.0, "p_hp": 1.0, "mobs": 1, "dist": 0.0, "freq": 0.0},
		{"name": "Enemy_Infinite_Dist", "c_hp": 1.0, "p_hp": 1.0, "mobs": 0, "dist": 999999.0, "freq": 0.0},
		{"name": "Extreme_Order_Spam_50cps", "c_hp": 1.0, "p_hp": 1.0, "mobs": 1, "dist": 100.0, "freq": 50.0},
		{"name": "Negative_Order_Spam", "c_hp": 1.0, "p_hp": 1.0, "mobs": 1, "dist": 100.0, "freq": -5.0},
	]

	var t1 := EnneagramData.create_preset(EnneagramData.Type.REFORMER)
	var t5 := EnneagramData.create_preset(EnneagramData.Type.INVESTIGATOR)
	var t8 := EnneagramData.create_preset(EnneagramData.Type.CHALLENGER)
	var profiles_to_test := [t1, t5, t8]

	for ec in extreme_cases:
		var cname: String = ec["name"]
		var ctx := TacticalContext.new()
		ctx.companion_hp_ratio = ec["c_hp"]
		ctx.player_hp_ratio = ec["p_hp"]
		ctx.nearby_enemies_count = ec["mobs"]
		ctx.closest_enemy_distance = ec["dist"]
		ctx.order_frequency = ec["freq"]

		for prof in profiles_to_test:
			var tag := "%s_Type%d" % [cname, prof.enneagram_type]

			# Test update_stress
			var stress_res := EnneagramEvaluator.update_stress(1.0, 50.0, ctx, prof)
			assert_in_range(stress_res, 0.0, 100.0, "ExtremeStress.%s: update_stress bounded [0..100]" % tag)

			# Test calculate_obedience_score for all 3 orders
			for ord in [1, 2, 3]:
				var score := EnneagramEvaluator.calculate_obedience_score(
					ord, prof, EnneagramEvaluator.MentalState.HEALTHY, ctx, 0.0
				)
				assert_in_range(score, 0.0, 100.0, "ExtremeScore.%s_Ord%d: score bounded [0..100]" % [tag, ord])

				var res := EnneagramEvaluator.evaluate_order(
					ord, prof, EnneagramEvaluator.MentalState.HEALTHY, ctx, 0.0, "Tester"
				)
				assert_true(res != null, "ExtremeEval.%s_Ord%d: OrderResult non-null" % [tag, ord])
				assert_in_range(res.delay_sec, 0.0, 5.0, "ExtremeEval.%s_Ord%d: delay in range" % [tag, ord])

# ==============================================================================
# PART 3: Specific Archetype Invariants (Type 8, Type 2, Type 5)
# ==============================================================================

func _run_part3_archetype_invariants() -> void:
	print("\n--- [PART 3: SPECIFIC ARCHETYPE INVARIANTS] ---")

	# -------------------------------------------------------------------------
	# 3.1: Type 8 Challenger Invariants
	# -------------------------------------------------------------------------
	var t8 := EnneagramData.create_preset(EnneagramData.Type.CHALLENGER)

	# Invariant 3.1.1: Refusal on retreat when enemy is in combat range (< 100px)
	var ctx_t8_close := TacticalContext.new()
	ctx_t8_close.closest_enemy_distance = 45.0
	var res_t8_close := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.RETREAT, t8, EnneagramEvaluator.MentalState.HEALTHY, ctx_t8_close, 0.0, "Valtor"
	)
	assert_eq(res_t8_close.status, int(EnneagramEvaluator.OrderStatus.REFUSE), "Type8.Invariant: Refuses RETREAT when enemy is close (<100px)")
	assert_eq(res_t8_close.delay_sec, 0.0, "Type8.Invariant: Refusal is instant (delay 0.0s)")
	assert_true(res_t8_close.voice_line.contains("lixo") or res_t8_close.voice_line.contains("recuo"), "Type8.Invariant: Emits defiant refusal dialogue")

	# Invariant 3.1.2: Relentless attack dominance
	var res_t8_attack := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.ATTACK, t8, EnneagramEvaluator.MentalState.HEALTHY, ctx_t8_close, 0.0, "Valtor"
	)
	assert_eq(res_t8_attack.status, int(EnneagramEvaluator.OrderStatus.OBEY), "Type8.Invariant: Instant OBEY on ATTACK")
	assert_eq(res_t8_attack.delay_sec, 0.0, "Type8.Invariant: Healthy attack delay is 0.0s")

	# Invariant 3.1.3: Retreat behavior when out of combat / distant enemies
	var ctx_t8_far := TacticalContext.new()
	ctx_t8_far.closest_enemy_distance = 600.0
	var res_t8_far := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.RETREAT, t8, EnneagramEvaluator.MentalState.HEALTHY, ctx_t8_far, 0.0, "Valtor"
	)
	# Check whether Type 8 refuses retreat even at distance
	assert_eq(res_t8_far.status, int(EnneagramEvaluator.OrderStatus.REFUSE), "Type8.Invariant: Refuses RETREAT across all combat proximities due to anti-retreat disposition")

	# -------------------------------------------------------------------------
	# 3.2: Type 2 Helper Invariants
	# -------------------------------------------------------------------------
	var t2 := EnneagramData.create_preset(EnneagramData.Type.HELPER)

	# Invariant 3.2.1: Martyrdom when player HP is critical (< 25%)
	var ctx_t2_martyr := TacticalContext.new()
	ctx_t2_martyr.player_hp_ratio = 0.20 # < 25% critical
	var res_t2_retreat := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.RETREAT, t2, EnneagramEvaluator.MentalState.HEALTHY, ctx_t2_martyr, 0.0, "Lyra"
	)
	assert_eq(res_t2_retreat.status, int(EnneagramEvaluator.OrderStatus.REFUSE), "Type2.Invariant: Refuses RETREAT when Player HP < 25% (Martyr syndrome)")
	assert_true(res_t2_retreat.voice_line.contains("recuar"), "Type2.Invariant: Emits protective refusal voice line")

	# Invariant 3.2.2: Instant intervention on HELP when player is critical
	var res_t2_help := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.HELP, t2, EnneagramEvaluator.MentalState.HEALTHY, ctx_t2_martyr, 0.0, "Lyra"
	)
	assert_eq(res_t2_help.status, int(EnneagramEvaluator.OrderStatus.OBEY), "Type2.Invariant: Instant OBEY on HELP when Player is Critical")
	assert_eq(res_t2_help.delay_sec, 0.0, "Type2.Invariant: Zero delay for critical rescue")

	# Invariant 3.2.3: Willingness to retreat when player is safe (HP >= 75%)
	var ctx_t2_safe := TacticalContext.new()
	ctx_t2_safe.player_hp_ratio = 0.90
	var res_t2_safe_retreat := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.RETREAT, t2, EnneagramEvaluator.MentalState.HEALTHY, ctx_t2_safe, 0.0, "Lyra"
	)
	assert_true(res_t2_safe_retreat.status != int(EnneagramEvaluator.OrderStatus.REFUSE), "Type2.Invariant: Does NOT refuse retreat when player is safe (>75% HP)")

	# -------------------------------------------------------------------------
	# 3.3: Type 5 Investigator Swarm Freeze
	# -------------------------------------------------------------------------
	var t5 := EnneagramData.create_preset(EnneagramData.Type.INVESTIGATOR)
	var ctx_t5_swarm := TacticalContext.new()
	ctx_t5_swarm.nearby_enemies_count = 8 # >= 6 mobs
	var res_t5_attack := EnneagramEvaluator.evaluate_order(
		EnneagramEvaluator.LeadershipOrder.ATTACK, t5, EnneagramEvaluator.MentalState.HEALTHY, ctx_t5_swarm, 0.0, "Aria"
	)
	assert_true(res_t5_attack.raw_score < 60.0, "Type5.Invariant: Swarm of 8 mobs drops attack score below OBEY threshold (<60)")

# ==============================================================================
# PART 4: Deterministic Seed Consistency & Reproducibility
# ==============================================================================

func _run_part4_deterministic_seed_generator() -> void:
	print("\n--- [PART 4: DETERMINISTIC SEED CONSISTENCY & REPRODUCIBILITY] ---")

	# Monte Carlo Generator: Run 100 randomized scenarios with fixed RNG seed twice
	var seed_val: int = 133742
	var run1_results: Array[Dictionary] = _generate_evaluation_batch(seed_val, 100)
	var run2_results: Array[Dictionary] = _generate_evaluation_batch(seed_val, 100)

	assert_eq(run1_results.size(), 100, "DeterministicTest: Run 1 generated 100 evaluations")
	assert_eq(run2_results.size(), 100, "DeterministicTest: Run 2 generated 100 evaluations")

	var mismatches: int = 0
	for i in range(100):
		var r1: Dictionary = run1_results[i]
		var r2: Dictionary = run2_results[i]

		if r1["status"] != r2["status"] or absf(r1["score"] - r2["score"]) > 0.0001 or absf(r1["delay"] - r2["delay"]) > 0.0001 or r1["voice"] != r2["voice"]:
			mismatches += 1

	assert_eq(mismatches, 0, "DeterministicTest: 100/100 Evaluations Identical Under Fixed Seed (Bitwise Determinism)")

func _generate_evaluation_batch(p_seed: int, count: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed

	var results: Array[Dictionary] = []

	for _i in range(count):
		var type_id: int = rng.randi_range(1, 9)
		var order_id: int = rng.randi_range(1, 3)
		var stress_val: float = rng.randf_range(0.0, 100.0)
		var mental_state := EnneagramEvaluator.get_mental_state(stress_val)

		var ctx := TacticalContext.new()
		ctx.companion_hp_ratio = rng.randf_range(0.0, 1.0)
		ctx.player_hp_ratio = rng.randf_range(0.0, 1.0)
		ctx.nearby_enemies_count = rng.randi_range(0, 15)
		ctx.closest_enemy_distance = rng.randf_range(10.0, 500.0)
		ctx.order_frequency = rng.randf_range(0.0, 5.0)

		var profile := EnneagramData.create_type(type_id)
		var res: OrderResult = EnneagramEvaluator.evaluate_order(
			order_id, profile, mental_state, ctx, stress_val, "RNG_Tester"
		)

		results.append({
			"status": res.status,
			"score": res.raw_score,
			"delay": res.delay_sec,
			"voice": res.voice_line
		})

	return results

# ==============================================================================
# PART 5: Fuzzing & Invalid Input Handling
# ==============================================================================

func _run_part5_fuzzing_and_invalid_inputs() -> void:
	print("\n--- [PART 5: FUZZING & INVALID INPUT HANDLING] ---")

	var t1 := EnneagramData.create_preset(EnneagramData.Type.REFORMER)
	var ctx := TacticalContext.new()

	# 5.1: Null Profile Handling
	var score_null_prof := EnneagramEvaluator.calculate_obedience_score(
		1, null, EnneagramEvaluator.MentalState.HEALTHY, ctx, 0.0
	)
	assert_eq(score_null_prof, 75.0, "Fuzz.NullProfile: Default score 75.0 returned without crashing")

	var res_null_prof := EnneagramEvaluator.evaluate_order(
		1, null, EnneagramEvaluator.MentalState.HEALTHY, ctx, 0.0, "NullProf"
	)
	assert_true(res_null_prof != null, "Fuzz.NullProfile: evaluate_order non-null without profile")
	assert_eq(res_null_prof.voice_line, "Ordem processada.", "Fuzz.NullProfile: Uses fallback string")

	# 5.2: Null Context Handling
	var score_null_ctx := EnneagramEvaluator.calculate_obedience_score(
		1, t1, EnneagramEvaluator.MentalState.HEALTHY, null, 0.0
	)
	assert_in_range(score_null_ctx, 0.0, 100.0, "Fuzz.NullContext: Handled safely with default fallback context")

	var res_null_ctx := EnneagramEvaluator.evaluate_order(
		1, t1, EnneagramEvaluator.MentalState.HEALTHY, null, 0.0, "NullCtx"
	)
	assert_true(res_null_ctx != null, "Fuzz.NullContext: evaluate_order succeeds with null context")

	# 5.3: Out-of-Range Orders
	var score_bad_ord := EnneagramEvaluator.calculate_obedience_score(
		-999, t1, EnneagramEvaluator.MentalState.HEALTHY, ctx, 0.0
	)
	assert_in_range(score_bad_ord, 0.0, 100.0, "Fuzz.BadOrderNegative: Handled gracefully without crash")

	var score_high_ord := EnneagramEvaluator.calculate_obedience_score(
		99999, t1, EnneagramEvaluator.MentalState.HEALTHY, ctx, 0.0
	)
	assert_in_range(score_high_ord, 0.0, 100.0, "Fuzz.BadOrderLarge: Handled gracefully without crash")

	# 5.4: update_stress Null Resilience
	var stress_null1 := EnneagramEvaluator.update_stress(1.0, 40.0, null, t1)
	assert_eq(stress_null1, 40.0, "Fuzz.UpdateStressNullCtx: Preserves clamped stress without crash")

	var stress_null2 := EnneagramEvaluator.update_stress(1.0, 40.0, ctx, null)
	assert_eq(stress_null2, 40.0, "Fuzz.UpdateStressNullProfile: Preserves clamped stress without crash")

	# 5.5: TacticalContext.create_from_nodes With Nulls
	var ctx_from_nulls := TacticalContext.create_from_nodes(null, null, Vector2.ZERO)
	assert_true(ctx_from_nulls != null, "Fuzz.CreateFromNodesNulls: Returns valid TacticalContext object")
	assert_eq(ctx_from_nulls.companion_hp_ratio, 1.0, "Fuzz.CreateFromNodesNulls: Default companion HP is 1.0")
	assert_eq(ctx_from_nulls.player_hp_ratio, 1.0, "Fuzz.CreateFromNodesNulls: Default player HP is 1.0")

	# 5.6: LeadershipManager Robustness Under Fuzzed Input
	var lm := _get_leadership_manager()
	lm.reset_charges()

	# Fuzzed add_charge with negative and massive values
	lm.add_charge(-10)
	assert_true(lm.current_charges >= 0 and lm.current_charges <= 3, "Fuzz.LeadershipManager: Negative add_charge safe")

	lm.add_charge(1000)
	assert_eq(lm.current_charges, 3, "Fuzz.LeadershipManager: Massive add_charge clamped to max 3")

	# Rapid Kill Emissions Burst (150 kills)
	var eb := _get_event_bus()
	lm.current_charges = 0
	lm.kills_towards_recharge = 0
	for i in range(150):
		eb.emit_enemy_died(Vector2.ZERO, 10)
	assert_eq(lm.current_charges, 3, "Fuzz.LeadershipManager: 150 kills safely fills pool without overflow")

	# 5.7: Stress Formula Inversion on Default/Mismatched stress_level
	# If caller passes MentalState.COLLAPSED but defaults stress_level to 0.0:
	var ctx_neutral := TacticalContext.new()
	ctx_neutral.nearby_enemies_count = 5 # In Reformer (Type 1), 5 mobs yields tactical_mod = 0.0
	var score_healthy := EnneagramEvaluator.calculate_obedience_score(
		1, t1, EnneagramEvaluator.MentalState.HEALTHY, ctx_neutral, 0.0
	)
	var score_collapsed_def := EnneagramEvaluator.calculate_obedience_score(
		1, t1, EnneagramEvaluator.MentalState.COLLAPSED, ctx_neutral, 0.0
	)
	assert_true(
		score_collapsed_def < score_healthy,
		"Fuzz.StressFormulaInversion: Collapsed state must not exceed Healthy obedience (Got Collapsed=%f, Healthy=%f)" % [score_collapsed_def, score_healthy],
		"CRITICAL"
	)

# ==============================================================================
# PART 6: Live Companion Node FSM & Rapid Operations Lifecycle
# ==============================================================================

func _run_part6_live_companion_lifecycle() -> void:
	print("\n--- [PART 6: LIVE COMPANION NODE FSM & LIFECYCLE STRESS] ---")

	var CompanionScene = load("res://scenes/entities/companion/companion.tscn")
	assert_true(CompanionScene != null, "LiveNode: companion.tscn loads")

	var companion = CompanionScene.instantiate()
	root.add_child(companion)

	# 6.1: Run companion through all 9 presets dynamically in real-time
	var eb := _get_event_bus()
	for type_id in range(1, 10):
		companion.enneagram_profile = EnneagramData.create_type(type_id)
		companion.stress_level = 10.0 * float(type_id) # Diverse stress levels

		# Emit attack order
		eb.emit_leadership_order_issued(1, Vector2(150, 150))
		assert_true(companion.current_tactical_state != null, "LiveNode.Type%d: Tactical state valid after attack" % type_id)

	# 6.2: Rapid Debounced Orders Spam Simulation
	var lm := _get_leadership_manager()
	lm.reset_charges()
	var orders_accepted := 0
	for i in range(50):
		var ok: bool = lm.issue_order(1, Vector2(200, 200))
		if ok:
			orders_accepted += 1

	# First order succeeds, remainder in frame blocked by 0.15s debounce
	assert_eq(orders_accepted, 1, "LiveNode.DebounceSpam: Exactly 1 order admitted in burst of 50 calls")

	# 6.3: Clean Node Destruction (Verify no dangling crashes)
	root.remove_child(companion)
	companion.free()

	# Emit orders with companion destroyed to ensure no dead references crash EventBus
	eb.emit_leadership_order_issued(1, Vector2.ZERO)
	eb.emit_enemy_died(Vector2.ZERO, 5)
	record_pass("LiveNode.Cleanup: EventBus broadcasts without crashing after companion destruction")
