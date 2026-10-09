extends RefCounted

## Verification Suite for Milestone 5 (M5):
## Organic Agency, Silent Dual Endings & Full E2E Integration.
## Compatible with standalone execution and test_runner.gd.

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var exit_code: int = 0

func run_all(runner: SceneTree) -> void:
	print("\n--- [MILESTONE 5: ORGANIC AGENCY & SILENT DUAL ENDINGS TESTS] ---")
	await test_tracker_autoload_and_initialization(runner)
	await test_zero_interpretive_aid_hud(runner)
	await test_agency_score_mathematical_formula(runner)
	await test_dual_endings_evaluation_rules(runner)
	await test_telemetry_recording_methods(runner)
	await test_negative_telemetry_sanitization(runner)
	await test_event_bus_signal_integration(runner)
	await test_distance_combat_abandonment_monitoring(runner)
	await test_ending_screen_ui_component(runner)
	await test_game_loop_and_victory_portal_integration(runner)
	await test_e2e_full_campaign_simulation(runner)

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

func assert_almost_eq(runner: SceneTree, actual: float, expected: float, tolerance: float, test_name: String, msg: String = "") -> void:
	if absf(actual - expected) <= tolerance:
		record_pass(runner, test_name)
	else:
		var detail := "Expected %f +/- %f, got %f" % [expected, tolerance, actual]
		if msg != "":
			detail = "%s (%s)" % [msg, detail]
		record_fail(runner, test_name, detail)

# ==============================================================================
# TEST CASES
# ==============================================================================

## 1. SilentAgencyTracker Script & AutoLoad Registration
func test_tracker_autoload_and_initialization(runner: SceneTree) -> void:
	assert_true(runner, ResourceLoader.exists("res://scripts/autoloads/agency_tracker.gd"),
		"M5.01: scripts/autoloads/agency_tracker.gd exists")

	var TrackerScript = load("res://scripts/autoloads/agency_tracker.gd")
	assert_true(runner, TrackerScript != null and TrackerScript.can_instantiate(),
		"M5.02: SilentAgencyTracker script compiles and instantiates cleanly")

	var tracker = TrackerScript.new()
	assert_true(runner, tracker != null, "M5.03: SilentAgencyTracker instantiates node")

	# Check metric properties initial values
	assert_eq(runner, tracker.get("allies_deployed"), 0, "M5.04: allies_deployed initialized to 0")
	assert_eq(runner, tracker.get("allies_survived"), 0, "M5.05: allies_survived initialized to 0")
	assert_eq(runner, tracker.get("allies_fallen"), 0, "M5.06: allies_fallen initialized to 0")
	assert_eq(runner, tracker.get("rescues_performed"), 0, "M5.07: rescues_performed initialized to 0")
	assert_eq(runner, tracker.get("reckless_orders_issued"), 0, "M5.08: reckless_orders_issued initialized to 0")
	assert_eq(runner, tracker.get("abandonment_ticks"), 0, "M5.09: abandonment_ticks initialized to 0")

	# Check methods exist
	assert_true(runner, tracker.has_method("record_order"), "M5.10: Has record_order()")
	assert_true(runner, tracker.has_method("record_rescue"), "M5.11: Has record_rescue()")
	assert_true(runner, tracker.has_method("record_ally_death"), "M5.12: Has record_ally_death()")
	assert_true(runner, tracker.has_method("record_abandonment_tick"), "M5.13: Has record_abandonment_tick()")
	assert_true(runner, tracker.has_method("record_ally_deployed"), "M5.14: Has record_ally_deployed()")
	assert_true(runner, tracker.has_method("record_ally_survived"), "M5.15: Has record_ally_survived()")
	assert_true(runner, tracker.has_method("calculate_agency_score"), "M5.16: Has calculate_agency_score()")
	assert_true(runner, tracker.has_method("evaluate_ending"), "M5.17: Has evaluate_ending()")
	assert_true(runner, tracker.has_method("get_metrics"), "M5.18: Has get_metrics()")
	assert_true(runner, tracker.has_method("reset_metrics"), "M5.19: Has reset_metrics()")

	tracker.free()

	# Verify project.godot autoload config
	var cfg := ConfigFile.new()
	var err := cfg.load("res://project.godot")
	assert_true(runner, err == OK and cfg.has_section_key("autoload", "SilentAgencyTracker"),
		"M5.20: SilentAgencyTracker registered as AutoLoad in project.godot")

## 2. Zero Interpretive Aid (HUD Morality/Karma Inspection)
func test_zero_interpretive_aid_hud(runner: SceneTree) -> void:
	assert_true(runner, ResourceLoader.exists("res://scenes/ui/hud/hud.tscn"),
		"M5.21: scenes/ui/hud/hud.tscn exists")

	var HUDScene = load("res://scenes/ui/hud/hud.tscn")
	var hud = HUDScene.instantiate()
	assert_true(runner, hud != null, "M5.22: HUD scene instantiates cleanly")

	var has_morality_meter = hud.find_child("*morality*", true, false) != null or \
							hud.find_child("*karma*", true, false) != null or \
							hud.find_child("*alignment*", true, false) != null or \
							hud.find_child("*good_evil*", true, false) != null
	assert_false(runner, has_morality_meter,
		"M5.23: Pure Immersion: HUD has strictly zero visible morality/karma/alignment meters")

	hud.free()

## 3. AgencyScore Mathematical Formula
func test_agency_score_mathematical_formula(runner: SceneTree) -> void:
	var TrackerScript = load("res://scripts/autoloads/agency_tracker.gd")
	var tracker = TrackerScript.new()

	# Base score at 0
	assert_eq(runner, tracker.calculate_agency_score(), 0, "M5.24: Base AgencyScore is 0")

	# Ideal run: 2 survived, 1 rescue, 0 fallen, 0 reckless, 0 abandon
	# Formula: (2 * 25) + (1 * 15) - 0 - 0 - 0 = 50 + 15 = +65
	tracker.allies_survived = 2
	tracker.rescues_performed = 1
	assert_eq(runner, tracker.calculate_agency_score(), 65,
		"M5.25: Ideal run calculates exactly +65 AgencyScore")

	# Catastrophic run: 0 survived, 0 rescue, 3 fallen (-105), 2 reckless (-20), 1 abandon (-15) = -140
	tracker.reset_metrics()
	tracker.allies_fallen = 3
	tracker.reckless_orders_issued = 2
	tracker.abandonment_ticks = 1
	assert_eq(runner, tracker.calculate_agency_score(), -140,
		"M5.26: Catastrophic run calculates exactly -140 AgencyScore")

	# Mixed run: 1 survived (+25), 2 rescues (+30), 1 fallen (-35), 1 reckless (-10), 0 abandon = +10
	tracker.reset_metrics()
	tracker.allies_survived = 1
	tracker.rescues_performed = 2
	tracker.allies_fallen = 1
	tracker.reckless_orders_issued = 1
	assert_eq(runner, tracker.calculate_agency_score(), 10,
		"M5.27: Mixed run calculates exactly +10 AgencyScore")

	tracker.free()

## 4. Dual Endings Resolution Logic
func test_dual_endings_evaluation_rules(runner: SceneTree) -> void:
	var TrackerScript = load("res://scripts/autoloads/agency_tracker.gd")
	var tracker = TrackerScript.new()

	# Rule 1: Zero allies deployed (Solo run) -> BAD_ENDING
	tracker.reset_metrics()
	tracker.allies_deployed = 0
	assert_eq(runner, tracker.evaluate_ending(), "BAD_ENDING",
		"M5.28: Solo run (0 deployed) resolves to BAD_ENDING (O Monstro Solitário)")

	# Rule 2: Ideal run -> GOOD_ENDING
	tracker.reset_metrics()
	tracker.allies_deployed = 2
	tracker.allies_survived = 2
	tracker.rescues_performed = 1
	# score: 65, fallen: 0
	assert_eq(runner, tracker.evaluate_ending(), "GOOD_ENDING",
		"M5.29: Ideal metrics resolve to GOOD_ENDING (A Aliança dos Vivos)")

	# Rule 3: Score >= 50 and 1 fallen -> GOOD_ENDING
	tracker.reset_metrics()
	tracker.allies_deployed = 3
	tracker.allies_survived = 3 # 75
	tracker.rescues_performed = 1 # 15 -> 90
	tracker.allies_fallen = 1 # -35 -> 55
	# score: 55 >= 50, fallen: 1 <= 1
	assert_eq(runner, tracker.evaluate_ending(), "GOOD_ENDING",
		"M5.30: Score >= 50 with 1 fallen resolves to GOOD_ENDING")

	# Rule 4: Score >= 50 but 2 fallen -> BAD_ENDING
	tracker.reset_metrics()
	tracker.allies_deployed = 4
	tracker.allies_survived = 4 # 100
	tracker.rescues_performed = 2 # 30 -> 130
	tracker.allies_fallen = 2 # -70 -> 60
	# score: 60 >= 50, but fallen: 2 > 1
	assert_eq(runner, tracker.evaluate_ending(), "BAD_ENDING",
		"M5.31: High score with 2 fallen casualties fails condition and falls back to BAD_ENDING")

	# Rule 5: 3 fallen casualties -> decisive BAD_ENDING regardless of score
	tracker.reset_metrics()
	tracker.allies_deployed = 5
	tracker.allies_survived = 5 # 125
	tracker.allies_fallen = 3 # -105 -> 20
	assert_eq(runner, tracker.evaluate_ending(), "BAD_ENDING",
		"M5.32: 3 or more casualties decisively triggers BAD_ENDING")

	# Rule 6: Negative score -> BAD_ENDING
	tracker.reset_metrics()
	tracker.allies_deployed = 1
	tracker.allies_survived = 0
	tracker.allies_fallen = 1 # -35
	assert_eq(runner, tracker.evaluate_ending(), "BAD_ENDING",
		"M5.33: Negative AgencyScore resolves to BAD_ENDING")

	tracker.free()

## 5. Telemetry Recording API
func test_telemetry_recording_methods(runner: SceneTree) -> void:
	var TrackerScript = load("res://scripts/autoloads/agency_tracker.gd")
	var tracker = TrackerScript.new()

	tracker.reset_metrics()
	tracker.record_ally_deployed({"id": "merc_1", "class": "paladin"})
	tracker.record_ally_deployed({"id": "merc_2", "class": "archer"})
	assert_eq(runner, tracker.allies_deployed, 2, "M5.34: record_ally_deployed increments counter")

	tracker.record_rescue()
	assert_eq(runner, tracker.rescues_performed, 1, "M5.35: record_rescue increments counter")

	tracker.record_order(1, false)
	assert_eq(runner, tracker.reckless_orders_issued, 0, "M5.36: Non-reckless order does not increment reckless counter")

	tracker.record_order(1, true)
	assert_eq(runner, tracker.reckless_orders_issued, 1, "M5.37: Reckless order increments reckless counter")

	tracker.record_abandonment_tick()
	assert_eq(runner, tracker.abandonment_ticks, 1, "M5.38: record_abandonment_tick increments counter")

	tracker.record_ally_death()
	assert_eq(runner, tracker.allies_fallen, 1, "M5.39: record_ally_death increments counter")

	tracker.record_ally_survived()
	assert_eq(runner, tracker.allies_survived, 1, "M5.40: record_ally_survived increments counter")

	var metrics = tracker.get_metrics()
	assert_true(runner, metrics.has("allies_deployed") and metrics.has("agency_score") and metrics.has("ending"),
		"M5.41: get_metrics returns complete dictionary containing telemetry and ending")

	tracker.reset_metrics()
	assert_eq(runner, tracker.allies_deployed, 0, "M5.42: reset_metrics clears all counters")

	tracker.free()

## 6. Negative Value Sanitization Clamping (T2.EXP.26)
func test_negative_telemetry_sanitization(runner: SceneTree) -> void:
	var TrackerScript = load("res://scripts/autoloads/agency_tracker.gd")
	var tracker = TrackerScript.new()

	tracker.allies_deployed = -5
	assert_eq(runner, tracker.allies_deployed, 0, "M5.43: allies_deployed clamped to >= 0")

	tracker.allies_survived = -10
	assert_eq(runner, tracker.allies_survived, 0, "M5.44: allies_survived clamped to >= 0")

	tracker.allies_fallen = -3
	assert_eq(runner, tracker.allies_fallen, 0, "M5.45: allies_fallen clamped to >= 0")

	tracker.rescues_performed = -8
	assert_eq(runner, tracker.rescues_performed, 0, "M5.46: rescues_performed clamped to >= 0")

	tracker.reckless_orders_issued = -2
	assert_eq(runner, tracker.reckless_orders_issued, 0, "M5.47: reckless_orders_issued clamped to >= 0")

	tracker.abandonment_ticks = -99
	assert_eq(runner, tracker.abandonment_ticks, 0, "M5.48: abandonment_ticks clamped to >= 0")

	tracker.free()

## 7. EventBus Signal Wiring & Reckless Order Detection (T2.EXP.23)
func test_event_bus_signal_integration(runner: SceneTree) -> void:
	var eb = runner.root.get_node_or_null("EventBus")
	assert_true(runner, eb != null, "M5.49: EventBus AutoLoad available in SceneTree")

	assert_true(runner, eb.has_signal("companion_rescued"), "M5.50: EventBus declares companion_rescued signal")
	assert_true(runner, eb.has_signal("ally_died"), "M5.51: EventBus declares ally_died signal")

	var tracker = runner.root.get_node_or_null("SilentAgencyTracker")
	assert_true(runner, tracker != null, "M5.52: SilentAgencyTracker AutoLoad available in SceneTree")

	if tracker != null:
		tracker.reset_metrics()

		# Trigger companion_rescued via EventBus
		eb.companion_rescued.emit(null)
		assert_eq(runner, tracker.rescues_performed, 1, "M5.53: EventBus companion_rescued increments rescues_performed")

		# Trigger ally_died via EventBus
		eb.ally_died.emit(null)
		assert_eq(runner, tracker.allies_fallen, 1, "M5.54: EventBus ally_died increments allies_fallen")

		# Test Reckless Order detection on low ally health (<20%)
		var mock_companion := Node2D.new()
		mock_companion.name = "LowHealthCompanion"
		mock_companion.add_to_group("companions")
		var health := HealthComponent.new()
		health.name = "HealthComponent"
		health.max_health = 100.0
		health.current_health = 15.0 # 15% HP (< 20%)
		mock_companion.add_child(health)
		runner.root.add_child(mock_companion)

		# Emit attack order (1)
		eb.leadership_order_issued.emit(1, Vector2(100, 100))
		assert_eq(runner, tracker.reckless_orders_issued, 1,
			"M5.55: Attack order issued while ally HP < 20% correctly flagged and logged as reckless")

		mock_companion.queue_free()
		tracker.reset_metrics()

## 8. Distance Combat Abandonment Monitoring (T2.EXP.22)
func test_distance_combat_abandonment_monitoring(runner: SceneTree) -> void:
	var TrackerScript = load("res://scripts/autoloads/agency_tracker.gd")
	var tracker = TrackerScript.new()

	tracker.reset_metrics()
	# Distance > 350px while engaged -> Abandonment Tick
	var triggered = tracker.check_abandonment_condition(380.0, true)
	assert_true(runner, triggered and tracker.abandonment_ticks == 1,
		"M5.56: Distance > 350px during combat triggers abandonment tick")

	# Distance <= 350px while engaged -> No tick
	var close_triggered = tracker.check_abandonment_condition(200.0, true)
	assert_true(runner, not close_triggered and tracker.abandonment_ticks == 1,
		"M5.57: Distance <= 350px does not trigger abandonment tick")

	# Distance > 350px while NOT engaged -> No tick
	var peaceful_triggered = tracker.check_abandonment_condition(400.0, false)
	assert_true(runner, not peaceful_triggered and tracker.abandonment_ticks == 1,
		"M5.58: Distance > 350px outside combat does not trigger abandonment tick")

	tracker.free()

## 9. Dual Ending Screen UI Component (M5.EXP.31)
func test_ending_screen_ui_component(runner: SceneTree) -> void:
	assert_true(runner, ResourceLoader.exists("res://scenes/ui/ending_screen/ending_screen.tscn"),
		"M5.59: scenes/ui/ending_screen/ending_screen.tscn exists")
	assert_true(runner, ResourceLoader.exists("res://scripts/ui/ending_screen.gd"),
		"M5.60: scripts/ui/ending_screen.gd exists")

	var EndingScene = load("res://scenes/ui/ending_screen/ending_screen.tscn")
	var ending_inst = EndingScene.instantiate()
	assert_true(runner, ending_inst is CanvasLayer, "M5.61: EndingScreen instantiates as CanvasLayer")

	# Test Good Ending presentation
	var good_metrics := {
		"allies_survived": 2,
		"rescues_performed": 1,
		"allies_fallen": 0,
		"reckless_orders_issued": 0,
		"agency_score": 65
	}
	ending_inst.display_ending("GOOD_ENDING", good_metrics)
	var title_lbl = ending_inst.find_child("TitleLabel", true, false) as Label
	var score_lbl = ending_inst.find_child("ScoreVal", true, false) as Label
	var surv_lbl = ending_inst.find_child("SurvVal", true, false) as Label
	assert_true(runner, title_lbl != null and title_lbl.text == "A Aliança dos Vivos",
		"M5.62: Good Ending displays narrative title 'A Aliança dos Vivos'")
	assert_true(runner, score_lbl != null and score_lbl.text == "65",
		"M5.63: Good Ending telemetry reflects AgencyScore 65")
	assert_true(runner, surv_lbl != null and surv_lbl.text == "2",
		"M5.64: Good Ending telemetry reflects 2 surviving allies")

	# Test Bad Ending presentation
	var bad_metrics := {
		"allies_survived": 0,
		"rescues_performed": 0,
		"allies_fallen": 3,
		"reckless_orders_issued": 2,
		"agency_score": -140
	}
	ending_inst.display_ending("BAD_ENDING", bad_metrics)
	assert_true(runner, title_lbl != null and title_lbl.text == "O Monstro Solitário",
		"M5.65: Bad Ending displays narrative title 'O Monstro Solitário'")
	assert_true(runner, score_lbl != null and score_lbl.text == "-140",
		"M5.66: Bad Ending telemetry reflects AgencyScore -140")

	# Test Return Button
	var return_btn = ending_inst.find_child("ReturnButton", true, false) as Button
	assert_true(runner, return_btn != null and return_btn.text == "Retornar ao Vilarejo",
		"M5.67: Return button 'Retornar ao Vilarejo' exists and is properly configured")

	ending_inst.free()

## 10. Game Loop & Victory Portal Integration
func test_game_loop_and_victory_portal_integration(runner: SceneTree) -> void:
	var gm = runner.root.get_node_or_null("GameManager")
	assert_true(runner, gm != null and gm.has_method("trigger_ending"),
		"M5.68: GameManager implements trigger_ending() method")

	if ResourceLoader.exists("res://scenes/dungeon/ruined_fortress.tscn"):
		var FortressScene = load("res://scenes/dungeon/ruined_fortress.tscn")
		var fortress = FortressScene.instantiate()
		assert_true(runner, fortress != null, "M5.69: Ruined Fortress scene instantiates cleanly")

		var portal = fortress.find_child("VictoryPortal", true, false)
		assert_true(runner, portal != null and portal is Area2D,
			"M5.70: Ruined Fortress contains VictoryPortal Area2D hooked to ending resolution")

		fortress.free()
	else:
		record_fail(runner, "M5.69", "ruined_fortress.tscn not found")

## 11. Full Campaign End-to-End Simulation
func test_e2e_full_campaign_simulation(runner: SceneTree) -> void:
	var tracker = runner.root.get_node_or_null("SilentAgencyTracker")
	if tracker == null:
		var TrackerScript = load("res://scripts/autoloads/agency_tracker.gd")
		tracker = TrackerScript.new()

	# Scenario A: Full Noble Campaign
	tracker.reset_metrics()
	tracker.record_ally_deployed({"id": "paladin_1", "class": "paladin"})
	tracker.record_ally_deployed({"id": "archer_1", "class": "archer"})
	tracker.record_rescue() # Rescued companion from Frost Tomb
	tracker.record_ally_survived()
	tracker.record_ally_survived()
	var noble_ending = tracker.evaluate_ending()
	var noble_score = tracker.calculate_agency_score()
	assert_true(runner, noble_ending == "GOOD_ENDING" and noble_score == 65,
		"M5.71: Campaign Flow A (Heroic Fellowship) cleanly evaluates to GOOD_ENDING with score 65")

	# Scenario B: Full Abandonment / Ruthless Campaign
	tracker.reset_metrics()
	tracker.record_ally_deployed({"id": "paladin_1", "class": "paladin"})
	tracker.record_ally_deployed({"id": "archer_1", "class": "archer"})
	tracker.record_ally_deployed({"id": "mage_1", "class": "mage"})
	tracker.record_ally_death()
	tracker.record_ally_death()
	tracker.record_ally_death()
	tracker.record_order(1, true)
	tracker.record_abandonment_tick()
	var tyrant_ending = tracker.evaluate_ending()
	var tyrant_score = tracker.calculate_agency_score()
	assert_true(runner, tyrant_ending == "BAD_ENDING" and tyrant_score < 0,
		"M5.72: Campaign Flow B (Ruthless Tyrant) cleanly evaluates to BAD_ENDING with negative score")

	# Scenario C: Solo Ronin Campaign
	tracker.reset_metrics() # 0 deployed
	var solo_ending = tracker.evaluate_ending()
	assert_eq(runner, solo_ending, "BAD_ENDING",
		"M5.73: Campaign Flow C (Solo Expedition) cleanly evaluates to BAD_ENDING (Isolationist)")

	tracker.reset_metrics()
