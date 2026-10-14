extends SceneTree

## Automated Headless Test Runner for "Shadow Cheat: Solo Guild Ascendance"
## Executes Tiers 1 through 4 and returns deterministic exit code 0 or 1.

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var skipped_tests: int = 0
var failure_details: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_start_runner")

func _start_runner() -> void:
	print("\n" + "=".repeat(70))
	print(" SHADOW CHEAT: SOLO GUILD ASCENDANCE — E2E TEST RUNNER")
	print(" Engine: Godot 4.6.1 (Headless Mode)")
	print("=".repeat(70) + "\n")

	var start_time := Time.get_ticks_msec()

	await _run_tier1()
	await _run_tier2()
	await _run_tier3()
	await _run_tier4()
	await _run_expansion()
	await _run_m3()
	await _run_m4()
	await _run_m5()
	await _run_relic_tests()
	await _run_economy_tests()
	await _run_dialogue_card_tests()
	await _run_enneagram_tests()
	await _run_dynamic_pacing_tests()
	await _run_weapon_chest_tests()

	var elapsed_ms := Time.get_ticks_msec() - start_time
	_print_summary(elapsed_ms)

	if failed_tests > 0:
		print(">> RESULT: FAILED (Exit Code 1)\n")
		quit(1)
	else:
		print(">> RESULT: PASSED (Exit Code 0)\n")
		quit(0)

func _run_tier1() -> void:
	print("\n--- [TIER 1: FEATURE COVERAGE TESTS] ---")
	if not ResourceLoader.exists("res://tests/tier1_feature_tests.gd"):
		record_fail("Tier 1 Harness", "tests/tier1_feature_tests.gd not found")
		return
	var Tier1Class = load("res://tests/tier1_feature_tests.gd")
	var t1 = Tier1Class.new()
	if t1.has_method("run_all"):
		await t1.run_all(self)
	else:
		record_fail("Tier 1 Harness", "run_all method missing on tier1_feature_tests")

func _run_tier2() -> void:
	print("\n--- [TIER 2: BOUNDARY & CORNER CASE TESTS] ---")
	if not ResourceLoader.exists("res://tests/tier2_boundary_tests.gd"):
		record_fail("Tier 2 Harness", "tests/tier2_boundary_tests.gd not found")
		return
	var Tier2Class = load("res://tests/tier2_boundary_tests.gd")
	var t2 = Tier2Class.new()
	if t2.has_method("run_all"):
		await t2.run_all(self)
	else:
		record_fail("Tier 2 Harness", "run_all method missing on tier2_boundary_tests")

func _run_tier3() -> void:
	print("\n--- [TIER 3: CROSS-FEATURE INTERACTION TESTS] ---")
	if not ResourceLoader.exists("res://tests/tier3_cross_feature_tests.gd"):
		record_fail("Tier 3 Harness", "tests/tier3_cross_feature_tests.gd not found")
		return
	var Tier3Class = load("res://tests/tier3_cross_feature_tests.gd")
	var t3 = Tier3Class.new()
	if t3.has_method("run_all"):
		await t3.run_all(self)
	else:
		record_fail("Tier 3 Harness", "run_all method missing on tier3_cross_feature_tests")

func _run_tier4() -> void:
	print("\n--- [TIER 4: REAL-WORLD GAMEPLAY SCENARIOS] ---")
	if not ResourceLoader.exists("res://tests/tier4_gameplay_scenarios.gd"):
		record_fail("Tier 4 Harness", "tests/tier4_gameplay_scenarios.gd not found")
		return
	var Tier4Class = load("res://tests/tier4_gameplay_scenarios.gd")
	var t4 = Tier4Class.new()
	if t4.has_method("run_all"):
		await t4.run_all(self)
	else:
		record_fail("Tier 4 Harness", "run_all method missing on tier4_gameplay_scenarios")

func _run_expansion() -> void:
	print("\n--- [EXPANSION SUITE: TIERS 1-4 COMPREHENSIVE] ---")
	if not ResourceLoader.exists("res://tests/test_expansion_suite.gd"):
		record_fail("Expansion Harness", "tests/test_expansion_suite.gd not found")
		return
	var ExpansionClass = load("res://tests/test_expansion_suite.gd")
	var exp_suite = ExpansionClass.new()
	if exp_suite.has_method("run_all"):
		await exp_suite.run_all(self)
	else:
		record_fail("Expansion Harness", "run_all method missing on test_expansion_suite")

func _run_m3() -> void:
	if not ResourceLoader.exists("res://tests/test_m3_village_hub_suite.gd"):
		record_skip("M3 Hub Suite", "tests/test_m3_village_hub_suite.gd not found")
		return
	var M3SuiteClass = load("res://tests/test_m3_village_hub_suite.gd")
	var m3_suite = M3SuiteClass.new()
	if m3_suite.has_method("run_all"):
		await m3_suite.run_all(self)
	else:
		record_fail("M3 Hub Suite", "run_all method missing on test_m3_village_hub_suite")

func _run_m4() -> void:
	if not ResourceLoader.exists("res://tests/test_m4_fortress_bosses.gd"):
		record_skip("M4 Bosses Suite", "tests/test_m4_fortress_bosses.gd not found")
		return
	var M4SuiteClass = load("res://tests/test_m4_fortress_bosses.gd")
	var m4_suite = M4SuiteClass.new()
	if m4_suite.has_method("run_all"):
		await m4_suite.run_all(self)
	else:
		record_fail("M4 Bosses Suite", "run_all method missing on test_m4_fortress_bosses")

func _run_m5() -> void:
	if not ResourceLoader.exists("res://tests/test_m5_silent_agency.gd"):
		record_skip("M5 Silent Agency Suite", "tests/test_m5_silent_agency.gd not found")
		return
	var M5SuiteClass = load("res://tests/test_m5_silent_agency.gd")
	var m5_suite = M5SuiteClass.new()
	if m5_suite.has_method("run_all"):
		await m5_suite.run_all(self)
	else:
		record_fail("M5 Silent Agency Suite", "run_all method missing on test_m5_silent_agency")

func _run_relic_tests() -> void:
	if not ResourceLoader.exists("res://tests/test_relic_system.gd"):
		record_skip("Relic System Suite", "tests/test_relic_system.gd not found")
		return
	var RelicSuiteClass = load("res://tests/test_relic_system.gd")
	var relic_suite = RelicSuiteClass.new()
	if relic_suite.has_method("run_all"):
		await relic_suite.run_all(self)
	else:
		record_fail("Relic System Suite", "run_all method missing on test_relic_system")

func _run_economy_tests() -> void:
	if not ResourceLoader.exists("res://tests/test_economy_system.gd"):
		record_skip("Economy System Suite", "tests/test_economy_system.gd not found")
		return
	var EconomySuiteClass = load("res://tests/test_economy_system.gd")
	var economy_suite = EconomySuiteClass.new()
	if economy_suite.has_method("run_all"):
		await economy_suite.run_all(self)
	else:
		record_fail("Economy System Suite", "run_all method missing on test_economy_system")

func _print_summary(elapsed_ms: int) -> void:
	print("\n" + "=".repeat(70))
	print(" TEST EXECUTION SUMMARY")
	print("=".repeat(70))
	print(" Total Test Cases Evaluated : %d" % total_tests)
	print(" Passed                     : %d" % passed_tests)
	print(" Skipped (Pending Scope)    : %d" % skipped_tests)
	print(" Failed                     : %d" % failed_tests)
	print(" Execution Time             : %.2f seconds" % (float(elapsed_ms) / 1000.0))
	print("-".repeat(70))

	if failure_details.size() > 0:
		print(" FAILURES DETAIL (%d):" % failure_details.size())
		for idx in range(failure_details.size()):
			var f: Dictionary = failure_details[idx]
			print("   %d. [%s] %s" % [idx + 1, f.get("name", "Unknown"), f.get("reason", "No details")])
		print("-".repeat(70))
	print("=".repeat(70))

## Test result recording API

func record_pass(test_name: String, details: String = "") -> void:
	total_tests += 1
	passed_tests += 1

func record_fail(test_name: String, reason: String) -> void:
	total_tests += 1
	failed_tests += 1
	failure_details.append({"name": test_name, "reason": reason})
	print("  [FAIL] %s -> %s" % [test_name, reason])

func record_skip(test_name: String, reason: String) -> void:
	total_tests += 1
	skipped_tests += 1
	print("  [SKIP] %s -> %s" % [test_name, reason])

## Assertion helpers

func assert_true(cond: bool, test_name: String, message: String = "") -> bool:
	if cond:
		record_pass(test_name)
		return true
	record_fail(test_name, message if message != "" else "Assertion failed: expected true, got false")
	return false

func assert_false(cond: bool, test_name: String, message: String = "") -> bool:
	if not cond:
		record_pass(test_name)
		return true
	record_fail(test_name, message if message != "" else "Assertion failed: expected false, got true")
	return false

func assert_eq(actual: Variant, expected: Variant, test_name: String, message: String = "") -> bool:
	if actual == expected:
		record_pass(test_name)
		return true
	var detail := "Expected '%s', got '%s'" % [str(expected), str(actual)]
	if message != "":
		detail = "%s (%s)" % [message, detail]
	record_fail(test_name, detail)
	return false

func assert_ne(actual: Variant, expected: Variant, test_name: String, message: String = "") -> bool:
	if actual != expected:
		record_pass(test_name)
		return true
	var detail := "Expected value NOT equal to '%s', but both were equal" % str(expected)
	if message != "":
		detail = "%s (%s)" % [message, detail]
	record_fail(test_name, detail)
	return false

func assert_almost_eq(actual: float, expected: float, tolerance: float, test_name: String, message: String = "") -> bool:
	if absf(actual - expected) <= tolerance:
		record_pass(test_name)
		return true
	var detail := "Expected %f +/- %f, got %f (diff: %f)" % [expected, tolerance, actual, absf(actual - expected)]
	if message != "":
		detail = "%s (%s)" % [message, detail]
	record_fail(test_name, detail)
	return false

func assert_gt(actual: Variant, threshold: Variant, test_name: String, message: String = "") -> bool:
	if actual > threshold:
		record_pass(test_name)
		return true
	var detail := "Expected %s > %s" % [str(actual), str(threshold)]
	if message != "":
		detail = "%s (%s)" % [message, detail]
	record_fail(test_name, detail)
	return false

func assert_lt(actual: Variant, threshold: Variant, test_name: String, message: String = "") -> bool:
	if actual < threshold:
		record_pass(test_name)
		return true
	var detail := "Expected %s < %s" % [str(actual), str(threshold)]
	if message != "":
		detail = "%s (%s)" % [message, detail]
	record_fail(test_name, detail)
	return false

func wait_frames(count: int = 1) -> void:
	for i in range(count):
		await process_frame

func wait_physics_frames(count: int = 1) -> void:
	for i in range(count):
		await physics_frame

func _run_dialogue_card_tests() -> void:
	if not ResourceLoader.exists("res://tests/test_dialogue_card.gd"):
		record_skip("Dialogue Card Suite", "tests/test_dialogue_card.gd not found")
		return
	var DialogueCardClass = load("res://tests/test_dialogue_card.gd")
	var suite = DialogueCardClass.new()
	if suite.has_method("run_all"):
		await suite.run_all(self)
	else:
		record_fail("Dialogue Card Suite", "run_all method missing on test_dialogue_card")

func _run_enneagram_tests() -> void:
	print("\n--- [ENNEAGRAM DATA TESTS] ---")
	if not ResourceLoader.exists("res://tests/test_enneagram_data.gd"):
		record_fail("Enneagram Data Harness", "tests/test_enneagram_data.gd not found")
		return
	var TestClass = load("res://tests/test_enneagram_data.gd")
	var tc = TestClass.new()
	if tc.has_method("run_all"):
		await tc.run_all(self)
	else:
		record_fail("Enneagram Data Harness", "run_all method missing on test_enneagram_data")

func _run_dynamic_pacing_tests() -> void:
	if not ResourceLoader.exists("res://tests/test_dynamic_pacing_and_monster_dialect.gd"):
		record_skip("Dynamic Pacing Suite", "tests/test_dynamic_pacing_and_monster_dialect.gd not found")
		return
	var SuiteClass = load("res://tests/test_dynamic_pacing_and_monster_dialect.gd")
	var suite = SuiteClass.new()
	if suite.has_method("run_all"):
		await suite.run_all(self)
	else:
		record_fail("Dynamic Pacing Suite", "run_all method missing on test_dynamic_pacing_and_monster_dialect")

func _run_weapon_chest_tests() -> void:
	if not ResourceLoader.exists("res://tests/test_weapon_chest_system.gd"):
		record_skip("Weapon Chest System Suite", "tests/test_weapon_chest_system.gd not found")
		return
	var SuiteClass = load("res://tests/test_weapon_chest_system.gd")
	var suite = SuiteClass.new()
	if suite.has_method("run_all"):
		await suite.run_all(self)
	else:
		record_fail("Weapon Chest System Suite", "run_all method missing on test_weapon_chest_system")
