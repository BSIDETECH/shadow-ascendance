extends SceneTree

## Empirical Adversarial Stress Test Suite for Milestone 1 (M1):
## Leadership Orders & Charge Management
##
## Stress dimensions tested:
## 1. Rapid Input Spam (< 0.15s debounce rejection, zero charge leak, input map spam)
## 2. Zero Charge Spending (Keys 1, 2, 3 at 0 charges: no order emission, clamp at 0)
## 3. Charge Overflow Protection (10+ to 1,000+ kills at max 3 charges, add_charge clamp, zero spurious signals)
## 4. Recharge Precision (Exact 10-kill cadence kills % 10 == 0, partial cycle continuity, 5,000-step stochastic oracle)

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var failure_details: Array[Dictionary] = []

var _cached_eb: Node = null
var _cached_lm: Node = null

func _init() -> void:
	call_deferred("_run_stress_suite")

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

func assert_almost_eq(actual: float, expected: float, tol: float, test_name: String) -> bool:
	if absf(actual - expected) <= tol:
		record_pass(test_name)
		return true
	record_fail(test_name, "Expected %f +/- %f, got %f" % [expected, tol, actual])
	return false

func _run_stress_suite() -> void:
	print("\n" + "=".repeat(75))
	print(" EMPIRICAL ADVERSARIAL STRESS CHALLENGE: M1 LEADERSHIP & CHARGES")
	print(" Engine: Godot 4.6.1 (Headless Mode)")
	print("=".repeat(75) + "\n")

	var start_ms := Time.get_ticks_msec()

	_stress_rapid_input_spam()
	_stress_zero_charge_spending()
	_stress_charge_overflow_protection()
	_stress_recharge_precision_and_oracle()

	var elapsed_ms := Time.get_ticks_msec() - start_ms

	print("\n" + "=".repeat(75))
	print(" M1 ADVERSARIAL STRESS SUITE SUMMARY")
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
		print(">> STRESS CHALLENGE VERDICT: FAILED (Exit Code 1)\n")
		quit(1)
	else:
		print(">> STRESS CHALLENGE VERDICT: ALL TESTS PASSED (Exit Code 0)\n")
		quit(0)

# ==============================================================================
# DIMENSION 1: RAPID INPUT SPAM & DEBOUNCE REJECTION (< 0.15s)
# ==============================================================================

func _stress_rapid_input_spam() -> void:
	print("\n--- [DIMENSION 1: RAPID INPUT SPAM & DEBOUNCE REJECTION] ---")

	var lm := _get_leadership_manager()
	var eb := _get_event_bus()
	lm.reset_charges()

	# 1.1 Microsecond precision boundary timing test
	# Initial order at t = 0.0s
	var ok_initial: bool = lm.issue_order(1, Vector2.ZERO)
	assert_true(ok_initial, "SPAM.01: Initial order at t=0.0s accepted")
	assert_eq(lm.current_charges, 2, "SPAM.02: Charges decremented from 3 to 2")
	assert_almost_eq(lm._debounce_timer, 0.15, 0.001, "SPAM.03: Debounce timer initialized to exactly 0.15s")

	# Attempt at t = 0.000s (instant repeat)
	assert_false(lm.issue_order(1, Vector2.ZERO), "SPAM.04: Instant repeat at t=0.000s rejected")
	assert_eq(lm.current_charges, 2, "SPAM.05: Charges untouched at t=0.000s")

	# Advance 0.05s -> t = 0.05s (remaining 0.10s)
	lm._process(0.05)
	assert_almost_eq(lm._debounce_timer, 0.10, 0.001, "SPAM.06: Debounce timer decays to 0.10s")
	assert_false(lm.issue_order(2, Vector2.ZERO), "SPAM.07: Order 2 rejected at t=0.05s (< 0.15s)")
	assert_eq(lm.current_charges, 2, "SPAM.08: Charges untouched at t=0.05s")

	# Advance 0.05s -> t = 0.10s (remaining 0.05s)
	lm._process(0.05)
	assert_almost_eq(lm._debounce_timer, 0.05, 0.001, "SPAM.09: Debounce timer decays to 0.05s")
	assert_false(lm.issue_order(3, Vector2.ZERO), "SPAM.10: Order 3 rejected at t=0.10s (< 0.15s)")
	assert_eq(lm.current_charges, 2, "SPAM.11: Charges untouched at t=0.10s")

	# Advance 0.049s -> t = 0.149s (remaining 0.001s)
	lm._process(0.049)
	assert_true(lm._debounce_timer > 0.0, "SPAM.12: Debounce timer strictly > 0 at t=0.149s")
	assert_false(lm.issue_order(1, Vector2.ZERO), "SPAM.13: Order 1 rejected at t=0.149s boundary")
	assert_eq(lm.current_charges, 2, "SPAM.14: Charges untouched at t=0.149s")

	# Advance 0.002s -> t = 0.151s (expired)
	lm._process(0.002)
	assert_eq(lm._debounce_timer, 0.0, "SPAM.15: Debounce timer reached 0.0s")
	assert_true(lm.issue_order(2, Vector2.ZERO), "SPAM.16: Order 2 accepted at t=0.151s")
	assert_eq(lm.current_charges, 1, "SPAM.17: Charges decremented from 2 to 1")
	assert_almost_eq(lm._debounce_timer, 0.15, 0.001, "SPAM.18: Debounce timer reset to 0.15s")

	# 1.2 High-Throughput 1,000 Call Spam Burst within Active Debounce Window
	var orders_issued_signals: Array[Dictionary] = []
	var on_order_issued = func(o: int, t: Vector2):
		orders_issued_signals.append({"type": o, "target": t})
	eb.leadership_order_issued.connect(on_order_issued)

	var spam_accepted_count: int = 0
	for i in range(1000):
		var order_candidate: int = (i % 3) + 1 # cycles 1, 2, 3
		# advance tiny micro-delta < 0.0001s so timer stays > 0
		lm._process(0.00001)
		if lm.issue_order(order_candidate, Vector2(i, i)):
			spam_accepted_count += 1

	assert_eq(spam_accepted_count, 0, "SPAM.19: 1,000 rapid spam calls strictly rejected (0 accepted)")
	assert_eq(orders_issued_signals.size(), 0, "SPAM.20: Zero leadership_order_issued signals emitted during 1,000 spam calls")
	assert_eq(lm.current_charges, 1, "SPAM.21: Zero charges leaked during 1,000 spam burst")

	eb.leadership_order_issued.disconnect(on_order_issued)

	# 1.3 Rapid Alternating Command Key Spam via _unhandled_input
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

	# First key press via input event
	lm._unhandled_input(attack_event)
	assert_eq(lm.current_charges, 2, "SPAM.22: InputEvent KEY_1 consumed 1 charge")
	assert_true(lm._debounce_timer > 0.0, "SPAM.23: InputEvent triggered debounce")

	# Rapid spam of KEY_2, KEY_3, KEY_1 without time advance
	lm._unhandled_input(retreat_event)
	lm._unhandled_input(help_event)
	lm._unhandled_input(attack_event)
	assert_eq(lm.current_charges, 2, "SPAM.24: Alternating keys rejected by debounce via _unhandled_input")

	# Wait debounce expiration
	lm._process(0.16)
	lm._unhandled_input(retreat_event)
	assert_eq(lm.current_charges, 1, "SPAM.25: KEY_2 accepted after debounce expiration")

	# Wait debounce expiration
	lm._process(0.16)
	lm._unhandled_input(help_event)
	assert_eq(lm.current_charges, 0, "SPAM.26: KEY_3 accepted after debounce expiration")

# ==============================================================================
# DIMENSION 2: ZERO CHARGE SPENDING & SIGNAL SUPPRESSION
# ==============================================================================

func _stress_zero_charge_spending() -> void:
	print("\n--- [DIMENSION 2: ZERO CHARGE SPENDING & SIGNAL SUPPRESSION] ---")

	var lm := _get_leadership_manager()
	var eb := _get_event_bus()

	# Force charges to 0 and clear debounce
	lm.reset_charges()
	lm.current_charges = 0
	lm._debounce_timer = 0.0
	assert_eq(lm.current_charges, 0, "ZERO.01: Starting test at 0 charges")

	# Track signal emissions
	var emitted_orders: Array[int] = []
	var emitted_charge_changes: Array[int] = []
	var failed_reasons: Array[String] = []

	var on_order = func(o: int, _t: Vector2): emitted_orders.append(o)
	var on_charge = func(curr: int, _max_c: int): emitted_charge_changes.append(curr)
	var on_fail = func(r: String): failed_reasons.append(r)

	eb.leadership_order_issued.connect(on_order)
	eb.leadership_charges_changed.connect(on_charge)
	eb.leadership_order_failed.connect(on_fail)

	# 2.1 Test Order 1 (ATTACK) at 0 charges
	var ok_attack: bool = lm.issue_order(1, Vector2.ZERO)
	assert_false(ok_attack, "ZERO.02: Attack order at 0 charges returned false")
	assert_eq(lm.current_charges, 0, "ZERO.03: Charges stayed at 0 (did not decrement to -1)")
	assert_eq(emitted_orders.size(), 0, "ZERO.04: leadership_order_issued was NOT emitted")
	assert_eq(failed_reasons.size(), 1, "ZERO.05: leadership_order_failed was emitted once")

	# Clear debounce for next attempt
	lm._debounce_timer = 0.0

	# 2.2 Test Order 2 (RETREAT) at 0 charges
	var ok_retreat: bool = lm.issue_order(2, Vector2.ZERO)
	assert_false(ok_retreat, "ZERO.06: Retreat order at 0 charges returned false")
	assert_eq(lm.current_charges, 0, "ZERO.07: Charges stayed at 0")
	assert_eq(emitted_orders.size(), 0, "ZERO.08: leadership_order_issued was NOT emitted")
	assert_eq(failed_reasons.size(), 2, "ZERO.09: leadership_order_failed emitted for retreat")

	lm._debounce_timer = 0.0

	# 2.3 Test Order 3 (HELP) at 0 charges
	var ok_help: bool = lm.issue_order(3, Vector2.ZERO)
	assert_false(ok_help, "ZERO.10: Help order at 0 charges returned false")
	assert_eq(lm.current_charges, 0, "ZERO.11: Charges stayed at 0")
	assert_eq(emitted_orders.size(), 0, "ZERO.12: leadership_order_issued was NOT emitted")
	assert_eq(failed_reasons.size(), 3, "ZERO.13: leadership_order_failed emitted for help")

	# 2.4 High-Volume 1,000 Stress Hammering at 0 Charges
	var hammer_accepted_count: int = 0
	for i in range(1000):
		var order_candidate: int = (i % 3) + 1
		# vary debounce state: sometimes advance time, sometimes not
		if i % 2 == 0:
			lm._debounce_timer = 0.0
		else:
			lm._process(0.01)

		if lm.issue_order(order_candidate, Vector2.ZERO):
			hammer_accepted_count += 1

		# Invariant check on every iteration: charges must never be < 0
		if lm.current_charges < 0:
			record_fail("ZERO.14: Invariant Violation", "Charges dropped below 0 to %d at iter %d" % [lm.current_charges, i])
			break

	assert_eq(hammer_accepted_count, 0, "ZERO.15: 1,000 attempts at 0 charges all rejected")
	assert_eq(lm.current_charges, 0, "ZERO.16: Charges strictly clamped at 0 after 1,000 attempts")
	assert_eq(emitted_orders.size(), 0, "ZERO.17: Zero orders issued during 1,000 zero-charge attempts")

	# Verify no negative charge changes were ever broadcast
	var found_negative: bool = false
	for c in emitted_charge_changes:
		if c < 0:
			found_negative = true
	assert_false(found_negative, "ZERO.18: No leadership_charges_changed signals with negative value")

	eb.leadership_order_issued.disconnect(on_order)
	eb.leadership_charges_changed.disconnect(on_charge)
	eb.leadership_order_failed.disconnect(on_fail)

# ==============================================================================
# DIMENSION 3: CHARGE OVERFLOW PROTECTION & CLAMPING AT MAX (3)
# ==============================================================================

func _stress_charge_overflow_protection() -> void:
	print("\n--- [DIMENSION 3: CHARGE OVERFLOW PROTECTION & CLAMPING AT MAX (3)] ---")

	var lm := _get_leadership_manager()
	var eb := _get_event_bus()

	lm.reset_charges()
	assert_eq(lm.current_charges, 3, "OVERFLOW.01: Initialized at MAX_CHARGES (3)")

	# Track charges changed signal
	var charge_changes: Array[int] = []
	var on_charge = func(curr: int, _max_c: int): charge_changes.append(curr)
	eb.leadership_charges_changed.connect(on_charge)

	# 3.1 Kill 10 enemies while at 3 charges
	for i in range(10):
		eb.emit_enemy_died(Vector2.ZERO, 10)
	assert_eq(lm.current_charges, 3, "OVERFLOW.02: 10 kills at max charges stays clamped at 3")
	assert_eq(charge_changes.size(), 0, "OVERFLOW.03: Zero spurious charges_changed signals emitted when clamped")

	# 3.2 Kill 20 more enemies (30 total kills at max)
	for i in range(20):
		eb.emit_enemy_died(Vector2.ZERO, 10)
	assert_eq(lm.current_charges, 3, "OVERFLOW.04: 30 total kills at max charges stays clamped at 3")
	assert_eq(charge_changes.size(), 0, "OVERFLOW.05: Still zero spurious charges_changed signals")

	# 3.3 Burst of 1,000 kills at max charges
	for i in range(1000):
		eb.emit_enemy_died(Vector2.ZERO, 10)
		if lm.current_charges > 3:
			record_fail("OVERFLOW.06: Overflow Invariant Breached", "Charges exceeded 3: %d" % lm.current_charges)
			break

	assert_eq(lm.current_charges, 3, "OVERFLOW.07: 1,000 kills burst at max charges strictly clamped at 3")
	assert_eq(charge_changes.size(), 0, "OVERFLOW.08: Zero spurious signals during 1,000 kills overflow burst")

	# 3.4 Direct API overflow stress: add_charge with huge amounts
	lm.add_charge(1)
	assert_eq(lm.current_charges, 3, "OVERFLOW.09: add_charge(1) at max clamped at 3")
	lm.add_charge(10)
	assert_eq(lm.current_charges, 3, "OVERFLOW.10: add_charge(10) at max clamped at 3")
	lm.add_charge(999999)
	assert_eq(lm.current_charges, 3, "OVERFLOW.11: add_charge(999999) at max clamped at 3")

	eb.leadership_charges_changed.disconnect(on_charge)

# ==============================================================================
# DIMENSION 4: RECHARGE PRECISION & 5,000-STEP STOCHASTIC ORACLE
# ==============================================================================

func _stress_recharge_precision_and_oracle() -> void:
	print("\n--- [DIMENSION 4: RECHARGE PRECISION & STOCHASTIC ORACLE] ---")

	var lm := _get_leadership_manager()
	var eb := _get_event_bus()

	# 4.1 Granular Step-by-Step Cadence Test (0 -> 1 -> 2 -> 3)
	lm.reset_charges()
	lm.current_charges = 0
	lm.kills_towards_recharge = 0

	var recharge_events: Array[Dictionary] = []
	var on_recharge = func(curr: int, _max_c: int):
		recharge_events.append({"curr": curr, "total_kills": lm.kills_towards_recharge})
	eb.leadership_charges_changed.connect(on_recharge)

	# Cycle 1: Kills 1 to 10
	for k in range(1, 10): # 1 through 9
		eb.emit_enemy_died(Vector2.ZERO, 5)
		assert_eq(lm.current_charges, 0, "PRECISION.01: Kill %d did not recharge early" % k)
		assert_eq(lm.kills_towards_recharge, k, "PRECISION.02: Kills counter matches %d" % k)
	assert_eq(recharge_events.size(), 0, "PRECISION.03: Zero recharge events before 10th kill")

	# 10th kill
	eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 1, "PRECISION.04: 10th kill restored exactly 1 charge")
	assert_eq(lm.kills_towards_recharge, 0, "PRECISION.05: Counter reset to 0 on 10th kill")
	assert_eq(recharge_events.size(), 1, "PRECISION.06: Exactly 1 recharge signal on 10th kill")

	# Cycle 2: Kills 11 to 20
	for k in range(1, 10):
		eb.emit_enemy_died(Vector2.ZERO, 5)
		assert_eq(lm.current_charges, 1, "PRECISION.07: Kill %d of cycle 2 did not recharge early" % k)
	eb.emit_enemy_died(Vector2.ZERO, 5) # 20th kill
	assert_eq(lm.current_charges, 2, "PRECISION.08: 20th kill restored 2nd charge")
	assert_eq(recharge_events.size(), 2, "PRECISION.09: Exactly 2 recharge signals total")

	# Cycle 3: Kills 21 to 30
	for k in range(1, 10):
		eb.emit_enemy_died(Vector2.ZERO, 5)
		assert_eq(lm.current_charges, 2, "PRECISION.10: Kill %d of cycle 3 did not recharge early" % k)
	eb.emit_enemy_died(Vector2.ZERO, 5) # 30th kill
	assert_eq(lm.current_charges, 3, "PRECISION.11: 30th kill restored 3rd charge (max)")
	assert_eq(recharge_events.size(), 3, "PRECISION.12: Exactly 3 recharge signals total")

	eb.leadership_charges_changed.disconnect(on_recharge)

	# 4.2 Partial Cycle Continuity Across Order Spending
	# At 3 charges: kill 6 enemies (kills_towards_recharge = 6)
	for i in range(6):
		eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 3, "PRECISION.13: Still at max charges")
	assert_eq(lm.kills_towards_recharge, 6, "PRECISION.14: 6 kills accumulated in current cycle")

	# Player spends 1 charge -> charges = 2
	lm._debounce_timer = 0.0
	var spent_ok: bool = lm.issue_order(1, Vector2.ZERO)
	assert_true(spent_ok, "PRECISION.15: Order spent successfully")
	assert_eq(lm.current_charges, 2, "PRECISION.16: Charges now 2")
	assert_eq(lm.kills_towards_recharge, 6, "PRECISION.17: Accumulated cycle kills preserved across spend")

	# Kill 3 more enemies -> 9 total in cycle
	for i in range(3):
		eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 2, "PRECISION.18: 9 total cycle kills does not yet restore")
	assert_eq(lm.kills_towards_recharge, 9, "PRECISION.19: Counter reached 9")

	# 10th kill of cycle completes -> restores charge 2 -> 3
	eb.emit_enemy_died(Vector2.ZERO, 5)
	assert_eq(lm.current_charges, 3, "PRECISION.20: 10th kill restored charge back to 3")
	assert_eq(lm.kills_towards_recharge, 0, "PRECISION.21: Counter reset to 0 after cycle completion")

	# 4.3 5,000-Step Stochastic Oracle Monte Carlo Simulation
	# Independent mathematical model that mirrors expected LeadershipManager behavior
	lm.reset_charges()
	var oracle_charges: int = 3
	var oracle_kills_in_cycle: int = 0
	var oracle_debounce: float = 0.0
	var oracle_total_orders: int = 0

	var rng := RandomNumberGenerator.new()
	rng.seed = 987654321 # Deterministic seed

	var oracle_discrepancy: bool = false
	var step_failure_msg: String = ""

	for step in range(5000):
		# Action choices:
		# 0: Process time step (0.01 to 0.20s)
		# 1: Enemy died (1 to 5 enemies)
		# 2: Attempt order (1, 2, or 3)
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

		# Invariant checks at end of each step
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

	assert_false(oracle_discrepancy, "PRECISION.22: 5,000-Step Stochastic Oracle Model Invariant Check", step_failure_msg)
	assert_eq(lm.current_charges, oracle_charges, "PRECISION.23: Final charges match oracle after 5,000 steps")
	assert_eq(lm.kills_towards_recharge, oracle_kills_in_cycle, "PRECISION.24: Final kills cycle matches oracle after 5,000 steps")
