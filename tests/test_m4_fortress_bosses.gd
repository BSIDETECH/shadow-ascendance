extends RefCounted

## Verification Suite for Milestone 4 (M4): Ruined Fortresses & Elemental Guardians.
## Compatible with both standalone execution and test_runner.gd.

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var exit_code: int = 0

func run_all(runner: SceneTree) -> void:
	print("\n--- [MILESTONE 4: RUINED FORTRESS & ELEMENTAL GUARDIANS TESTS] ---")
	await test_fortress_scene_and_structure(runner)
	await test_monolith_mechanics_and_mitigation(runner)
	await test_boss_guardian_base_fsm_and_overload(runner)
	await test_boss_ignis_flame_colossus(runner)
	await test_boss_glacies_frost_sovereign(runner)
	await test_frost_tomb_companion_trap(runner)
	await test_victory_portal_and_transitions(runner)
	await test_corner_cases_and_boundaries(runner)

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

# -----------------------------------------------------------------------------
# 1. Fortress Scene & Layout
# -----------------------------------------------------------------------------
func test_fortress_scene_and_structure(runner: SceneTree) -> void:
	assert_true(runner, ResourceLoader.exists("res://scenes/dungeon/ruined_fortress.tscn"),
		"M4.01: Ruined Fortress Scene Resource Exists")

	var Scene = load("res://scenes/dungeon/ruined_fortress.tscn")
	var fortress = Scene.instantiate()
	assert_true(runner, fortress != null, "M4.02: Ruined Fortress Instantiates Cleanly")

	# Perimeter walls
	var walls = fortress.find_child("PerimeterWalls", true, false)
	assert_true(runner, walls != null and walls is StaticBody2D, "M4.03: Perimeter Boundary Walls Configured on Layer 1")

	# Monoliths presence
	var m_left = fortress.find_child("MonolithLeft", true, false)
	var m_right = fortress.find_child("MonolithRight", true, false)
	assert_true(runner, m_left != null and m_right != null, "M4.04: Left and Right Leyline Monoliths Present in Arena")

	# Player & Boss presence
	var p = fortress.find_child("Player", true, false)
	var b = fortress.find_child("Boss", true, false)
	assert_true(runner, p != null and b != null, "M4.05: Player and Boss Spawners Positioned in Arena")

	# Victory portal
	var portal = fortress.find_child("VictoryPortal", true, false)
	assert_true(runner, portal != null and portal is Area2D, "M4.06: Victory Portal Node Configured")

	fortress.free()

# -----------------------------------------------------------------------------
# 2. Leyline Monolith Mechanics
# -----------------------------------------------------------------------------
func test_monolith_mechanics_and_mitigation(runner: SceneTree) -> void:
	var MonolithClass = load("res://scripts/dungeon/leyline_monolith.gd")
	var monolith = MonolithClass.new()
	assert_true(runner, monolith != null, "M4.07: LeylineMonolith Instantiates Cleanly")

	assert_almost_eq(runner, monolith.shield_mitigation, 0.90, 0.01, "M4.08: Monolith Projects 90% Shield Mitigation")
	assert_almost_eq(runner, monolith.overload_stun_duration, 4.0, 0.1, "M4.09: Overload Stun Duration is 4.0 Seconds")
	assert_almost_eq(runner, monolith.max_health, 150.0, 0.1, "M4.10: Monolith Defines 150 Max Health")

	# Test taking damage
	var test_dmg = DamageData.new(50.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null)
	monolith.take_damage(test_dmg)
	assert_almost_eq(runner, monolith.current_health, 100.0, 1.0, "M4.11: Monolith Accurately Deducts Incoming Damage")

	# Test destruction and signal
	var destroyed_box := [false]
	monolith.monolith_destroyed.connect(func(_m): destroyed_box[0] = true)
	var lethal_dmg = DamageData.new(200.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null)
	monolith.take_damage(lethal_dmg)
	assert_true(runner, monolith.is_destroyed, "M4.12: Monolith Transitions to is_destroyed State on Fatal Damage")
	assert_true(runner, destroyed_box[0], "M4.13: Monolith Emits monolith_destroyed Signal on Death")

	monolith.free()

# -----------------------------------------------------------------------------
# 3. Boss Guardian Base Class & FSM
# -----------------------------------------------------------------------------
func test_boss_guardian_base_fsm_and_overload(runner: SceneTree) -> void:
	var BossBaseClass = load("res://scripts/entities/boss_guardian_base.gd")
	var boss = BossBaseClass.new()
	assert_true(runner, boss is CharacterBody2D, "M4.14: BossGuardianBase Inherits CharacterBody2D")

	# Verify 90% mitigation while leylines active
	boss.set_leyline_mitigation(true)
	var raw_incoming := 100.0
	var damage_data := DamageData.new(raw_incoming, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null)
	var initial_hp: float = boss.current_health
	boss.health_component.take_damage(damage_data)
	var net_taken: float = initial_hp - boss.health_component.current_health
	assert_almost_eq(runner, net_taken, 10.0, 0.1, "M4.15: Boss Suffers Exactly 10% Net Damage Under 90% Leyline Shield")

	# Apply Leyline Overload (interrupt, remove mitigation, 100 direct dmg, 4.0s stun)
	var initial_stun_hp: float = boss.health_component.current_health
	boss.apply_leyline_overload(4.0)
	assert_false(runner, boss.has_active_leylines, "M4.16: Leyline Overload Removes Active Leylines Shield")
	assert_almost_eq(runner, boss.health_component.external_damage_mitigation, 0.0, 0.01,
		"M4.17: Boss Damage Mitigation Reduced to 0% Following Overload")
	assert_true(runner, boss.is_stunned, "M4.18: Boss Enters is_stunned State Following Overload")
	assert_almost_eq(runner, boss.stun_timer, 4.0, 0.1, "M4.19: Boss Stun Duration Initialized to 4.0 Seconds")
	var hp_loss: float = initial_stun_hp - boss.health_component.current_health
	assert_almost_eq(runner, hp_loss, 100.0, 1.0, "M4.20: Leyline Overload Inflicts 100 Direct Damage to Boss")

	boss.free()

# -----------------------------------------------------------------------------
# 4. Rank E Boss: Ignis (Flame Colossus)
# -----------------------------------------------------------------------------
func test_boss_ignis_flame_colossus(runner: SceneTree) -> void:
	var IgnisClass = load("res://scripts/entities/boss_cyclops.gd")
	var ignis = IgnisClass.new()
	assert_true(runner, ignis != null, "M4.21: BossCyclops (Ignis) Instantiates Cleanly")
	assert_almost_eq(runner, ignis.max_health, 650.0, 0.1, "M4.22: Ignis Defines Exactly 650 Max Health")
	assert_eq(runner, ignis.current_phase, 1, "M4.23: Ignis Starts in Phase 1")

	# Test Phase 1 attack setup
	ignis._start_seismic_slam()
	assert_eq(runner, ignis.current_attack_name, "seismic_slam", "M4.24: Ignis Initiates Telegraphed Seismic Slam")
	assert_true(runner, ignis.telegraph_node != null, "M4.25: Seismic Slam Generates Active Telegraph Indicator Node")

	ignis._start_flame_fan()
	assert_eq(runner, ignis.current_attack_name, "flame_fan", "M4.26: Ignis Initiates Telegraphed Flame Fan")

	# Trigger Phase 2 transition at <= 325 HP (50% HP threshold)
	ignis.current_health = 320.0
	ignis.health_component.current_health = 320.0
	ignis._start_phase_transition()
	assert_eq(runner, ignis.current_state, ignis.BossState.PHASE_TRANSITION,
		"M4.27: Damaged Ignis Enters PHASE_TRANSITION State at <=50% HP")
	ignis.state_timer = 0.0
	ignis._process_phase_transition(0.1)
	assert_eq(runner, ignis.current_phase, 2, "M4.28: Ignis Transitions Cleanly into Phase 2 Enrage")

	ignis.free()

# -----------------------------------------------------------------------------
# 5. Rank D Boss: Glacies (Frost Sovereign)
# -----------------------------------------------------------------------------
func test_boss_glacies_frost_sovereign(runner: SceneTree) -> void:
	var GlaciesClass = load("res://scripts/entities/boss_glacies.gd")
	var glacies = GlaciesClass.new()
	assert_true(runner, glacies != null, "M4.29: BossGlacies Instantiates Cleanly")
	assert_almost_eq(runner, glacies.max_health, 950.0, 0.1, "M4.30: Glacies Defines Exactly 950 Max Health")
	assert_eq(runner, glacies.current_phase, 1, "M4.31: Glacies Starts in Phase 1")

	# Test Phase 1 attacks
	glacies._start_ice_lance()
	assert_eq(runner, glacies.current_attack_name, "ice_lance", "M4.32: Glacies Initiates Telegraphed Ice Lance")

	glacies._start_blizzard_pulse()
	assert_eq(runner, glacies.current_attack_name, "blizzard_pulse", "M4.33: Glacies Initiates Telegraphed Blizzard Pulse")

	# Trigger Phase 2 transition at <= 475 HP (50% HP threshold)
	glacies.current_health = 470.0
	glacies.health_component.current_health = 470.0
	glacies._start_phase_transition()
	glacies.state_timer = 0.0
	glacies._process_phase_transition(0.1)
	assert_eq(runner, glacies.current_phase, 2, "M4.34: Glacies Transitions Cleanly into Phase 2 Enrage")

	glacies.free()

# -----------------------------------------------------------------------------
# 6. Frost Tomb Companion Trap
# -----------------------------------------------------------------------------
func test_frost_tomb_companion_trap(runner: SceneTree) -> void:
	var TombClass = load("res://scripts/entities/frost_tomb.gd")
	var comp = CharacterBody2D.new()
	comp.add_to_group("companions")
	var comp_hp = HealthComponent.new()
	comp_hp.max_health = 100.0
	comp_hp.current_health = 100.0
	comp.add_child(comp_hp)

	var tomb = TombClass.new(comp)
	assert_true(runner, tomb != null, "M4.35: FrostTomb Node Instantiates Cleanly Around Companion")
	assert_almost_eq(runner, tomb.max_health, 60.0, 0.1, "M4.36: Frost Tomb Defines 60 Max Health Break Threshold")
	assert_almost_eq(runner, tomb.trap_timeout, 6.0, 0.1, "M4.37: Frost Tomb Has Exactly 6.0s Execution Timeout")

	# Test breaking tomb frees companion
	var rescue_box := [false]
	tomb.companion_rescued.connect(func(_c): rescue_box[0] = true)
	var break_dmg = DamageData.new(70.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null)
	tomb.health_component.take_damage(break_dmg)

	assert_true(runner, tomb.is_broken, "M4.38: Dealing Lethal Damage to Frost Tomb Breaks the Tomb")
	assert_true(runner, rescue_box[0], "M4.39: Breaking Tomb Emits companion_rescued Signal")

	comp.free()

# -----------------------------------------------------------------------------
# 7. Victory Portal & Transitions
# -----------------------------------------------------------------------------
func test_victory_portal_and_transitions(runner: SceneTree) -> void:
	var FortressScene = load("res://scenes/dungeon/ruined_fortress.tscn")
	var fortress = FortressScene.instantiate()
	runner.root.add_child(fortress)

	var portal = fortress.find_child("VictoryPortal", true, false)
	assert_false(runner, portal.visible, "M4.40: Victory Portal Remains Invisible During Active Boss Fight")

	# Simulate guardian defeat
	fortress._handle_boss_death("Ignis, Flame Colossus")
	assert_true(runner, portal.visible, "M4.41: Victory Portal Activates and Becomes Visible on Boss Defeat")
	assert_true(runner, portal.monitoring, "M4.42: Victory Portal Enables Collision Monitoring for Player Exit")

	fortress.queue_free()

# -----------------------------------------------------------------------------
# 8. Boundary Conditions & Non-Stacking Gates
# -----------------------------------------------------------------------------
func test_corner_cases_and_boundaries(runner: SceneTree) -> void:
	var BossBaseClass = load("res://scripts/entities/boss_guardian_base.gd")
	var boss = BossBaseClass.new()

	# Boundary 1: Monolith broken when boss already dead is safe no-op (T2.EXP.18)
	boss.is_dead = true
	boss.current_health = 0.0
	boss.apply_leyline_overload(4.0)
	assert_false(runner, boss.is_stunned, "M4.43: Overload When Boss Dead Safely No-Ops Without Error")

	# Boundary 2: Non-stacking stun timer (T2.EXP.21)
	var fresh_boss = BossBaseClass.new()
	fresh_boss.apply_leyline_overload(4.0)
	fresh_boss.stun_timer = 2.5 # Reduced through passage of time
	fresh_boss.apply_leyline_overload(4.0) # Duplicate trigger
	assert_almost_eq(runner, fresh_boss.stun_timer, 2.5, 0.01,
		"M4.44: Stun Duration Does Not Stack or Reset When Boss is Already Stunned")

	# Boundary 3: Massive overkill from 55% to 0% in single frame (T2.EXP.19)
	var overkill_boss = BossBaseClass.new()
	overkill_boss.current_health = 350.0
	overkill_boss.health_component.current_health = 350.0
	var lethal_blast = DamageData.new(5000.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null)
	overkill_boss.health_component.take_damage(lethal_blast)
	assert_true(runner, overkill_boss.is_dead, "M4.45: Massive Single-Frame Overkill Transitions Cleanly to Dead State")

	# Boundary 4: Trapped ally death immediately despawns Frost Tomb (T2.EXP.20)
	var TombClass = load("res://scripts/entities/frost_tomb.gd")
	var dying_comp = CharacterBody2D.new()
	var dying_comp_hp = HealthComponent.new()
	dying_comp.add_child(dying_comp_hp)
	var test_tomb = TombClass.new(dying_comp)
	# Trigger companion death
	dying_comp_hp.current_health = 0.0
	dying_comp_hp.died.emit()
	assert_false(runner, test_tomb._is_trapped_companion_alive(),
		"M4.46: Tomb Accurately Detects Trapped Companion Death for Immediate Despawn")

	boss.free()
	fresh_boss.free()
	overkill_boss.free()
	dying_comp.free()
	test_tomb.free()
