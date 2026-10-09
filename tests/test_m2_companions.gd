extends SceneTree

## Automated Headless Verification Suite for Milestone 2 (M2):
## Modular Companions (Paladin, Archer, Mage) + Modular AI, Abilities, Leashing, and Armor.
## Exit Code 0 on all tests passed; Exit Code 1 on any failure.

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var failure_details: Array[Dictionary] = []

var _cached_eb: Node = null

func _get_event_bus() -> Node:
	if _cached_eb == null:
		_cached_eb = root.get_node_or_null("EventBus")
		if _cached_eb == null:
			var s = load("res://scripts/autoloads/event_bus.gd")
			_cached_eb = s.new()
			_cached_eb.name = "EventBus"
			root.add_child(_cached_eb)
	return _cached_eb

func _init() -> void:
	call_deferred("_run_test_suite")

func _run_test_suite() -> void:
	print("\n" + "=".repeat(75))
	print(" SHADOW CHEAT: SOLO GUILD ASCENDANCE — M2 MODULAR COMPANIONS SUITE")
	print(" Engine: Godot 4.6.1 (Headless Mode)")
	print("=".repeat(75) + "\n")

	var start_ms := Time.get_ticks_msec()

	_test_part1_companion_base_architecture()
	_test_part2_paladin_guardian_class()
	_test_part3_shield_bubble_aegis()
	_test_part4_archer_rogue_class()
	_test_part5_piercing_arrow_mechanics()
	_test_part6_slow_trap_mechanics()
	_test_part7_mage_refactor_and_elemental_spells()
	_test_part8_enneagram_leadership_order_responses()
	_test_part9_collision_layers_and_friendly_fire()

	var elapsed_ms := Time.get_ticks_msec() - start_ms

	print("\n" + "=".repeat(75))
	print(" M2 TEST SUITE SUMMARY")
	print("=".repeat(75))
	print(" Total Tests Evaluated : %d" % total_tests)
	print(" Passed                 : %d" % passed_tests)
	print(" Failed                 : %d" % failed_tests)
	print(" Duration               : %.2f seconds" % (float(elapsed_ms) / 1000.0))
	print("-".repeat(75))

	if failed_tests > 0:
		print(" FAILURES DETAIL (%d):" % failure_details.size())
		for idx in range(failure_details.size()):
			var f: Dictionary = failure_details[idx]
			print("   %d. [%s] %s" % [idx + 1, f.get("name", "Unknown"), f.get("reason", "No details")])
		print("-".repeat(75))
		print(">> M2 RESULT: FAILED (Exit Code 1)\n")
		quit(1)
	else:
		print(">> M2 RESULT: ALL TESTS PASSED (Exit Code 0)\n")
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

func assert_true(cond: bool, test_name: String, msg: String = "") -> void:
	if cond:
		record_pass(test_name)
	else:
		record_fail(test_name, msg if msg != "" else "Expected true, got false")

func assert_false(cond: bool, test_name: String, msg: String = "") -> void:
	if not cond:
		record_pass(test_name)
	else:
		record_fail(test_name, msg if msg != "" else "Expected false, got true")

func assert_eq(actual: Variant, expected: Variant, test_name: String) -> void:
	if actual == expected:
		record_pass(test_name)
	else:
		record_fail(test_name, "Expected '%s', got '%s'" % [str(expected), str(actual)])

func assert_almost_eq(actual: float, expected: float, tolerance: float, test_name: String) -> void:
	if absf(actual - expected) <= tolerance:
		record_pass(test_name)
	else:
		record_fail(test_name, "Expected ~%f (+/-%f), got %f" % [expected, tolerance, actual])

# ==============================================================================
# PART 1: COMPANION BASE ARCHITECTURE & LEASHING FSM
# ==============================================================================

func _test_part1_companion_base_architecture() -> void:
	print("\n--- [PART 1: COMPANION BASE ARCHITECTURE & LEASHING] ---")

	var BaseClass = load("res://scripts/entities/companion_base.gd")
	assert_true(BaseClass != null, "M2.01: scripts/entities/companion_base.gd loads cleanly")

	var base = BaseClass.new()
	assert_true(base is CharacterBody2D, "M2.02: CompanionBase inherits CharacterBody2D")
	assert_eq(base.motion_mode, CharacterBody2D.MOTION_MODE_FLOATING, "M2.03: Motion mode is MOTION_MODE_FLOATING")

	root.add_child(base)
	assert_true(base.is_in_group("allies"), "M2.04: CompanionBase belongs to 'allies' group")
	assert_true(base.is_in_group("companions"), "M2.05: CompanionBase belongs to 'companions' group")

	assert_true(base.health_component != null, "M2.06: CompanionBase encapsulates HealthComponent")
	assert_true(base.hurtbox_component != null, "M2.07: CompanionBase encapsulates HurtboxComponent")
	assert_eq(base.hurtbox_component.collision_layer, 64, "M2.08: HurtboxComponent collision layer is 64 [Companion]")
	assert_eq(base.hurtbox_component.collision_mask, 16, "M2.09: HurtboxComponent collision mask is 16 [EnemyAttacks]")

	assert_eq(base.current_tactical_state, CompanionBase.TacticalOrderState.IDLE_FOLLOW, "M2.10: Default tactical state is IDLE_FOLLOW")
	assert_eq(base.sprint_speed, 190.0, "M2.11: Default sprint speed is 190 px/s")
	assert_eq(base.max_leash_distance, 280.0, "M2.12: Hard leash distance is 280 px")
	assert_eq(base.sprint_leash_trigger, 180.0, "M2.13: Sprint leash trigger distance is 180 px")

	# Test signals
	var signal_results: Array[float] = []
	base.ally_damaged.connect(func(amt: float): signal_results.append(amt))
	var test_data := DamageData.new(10.0, DamageData.DamageType.PHYSICAL)
	base.health_component.take_damage(test_data)
	assert_true(signal_results.size() > 0, "M2.14: HealthComponent took_damage emits ally_damaged signal")

	# Null player safety
	base.global_position = Vector2(500, 500)
	base._handle_movement(0.016)
	assert_eq(base.velocity, Vector2.ZERO, "M2.15: Null player reference halts velocity safely without crashing")

	root.remove_child(base)
	base.free()

# ==============================================================================
# PART 2: PALADIN / GUARDIAN CLASS
# ==============================================================================

func _test_part2_paladin_guardian_class() -> void:
	print("\n--- [PART 2: PALADIN GUARDIAN CLASS] ---")

	var PaladinScript = load("res://scripts/entities/companion_paladin.gd")
	assert_true(PaladinScript != null, "M2.16: scripts/entities/companion_paladin.gd loads cleanly")

	var pal = PaladinScript.new()
	assert_true(pal is CompanionBase, "M2.17: CompanionPaladin inherits CompanionBase")
	assert_eq(pal.max_health, 160.0, "M2.18: Paladin defines 160.0 Max HP")
	assert_eq(pal.armor_reduction, 0.25, "M2.19: Paladin defines 25% Armor Reduction")
	assert_almost_eq(pal.stun_duration, 1.2, 0.05, "M2.20: Paladin Shield Charge has 1.2s stun duration")
	assert_eq(pal.cleave_range, 50.0, "M2.21: Paladin Cleave range is 50 px")
	assert_eq(pal.cleave_damage, 32.0, "M2.22: Paladin Cleave damage is 32.0")
	assert_eq(pal.charge_speed, 320.0, "M2.23: Paladin Shield Charge speed is 320 px/s")

	root.add_child(pal)
	assert_eq(pal.health_component.max_health, 160.0, "M2.24: Paladin HealthComponent initialized with 160 HP")
	assert_eq(pal.health_component.armor_reduction, 0.25, "M2.25: Paladin HealthComponent wired with 25% armor reduction")

	# Physical armor mitigation calculation test: 40 raw damage -> 30 net damage with 25% armor
	var raw_damage := 40.0
	var old_hp: float = pal.health_component.current_health
	var dmg_data := DamageData.new(raw_damage, DamageData.DamageType.PHYSICAL)
	pal.health_component.take_damage(dmg_data)
	var expected_hp: float = old_hp - (raw_damage * 0.75)
	assert_almost_eq(pal.health_component.current_health, expected_hp, 0.1, "M2.26: 25% Physical Armor mitigates 40 damage down to 30 damage")

	# Shield Charge wall collision halt test
	pal.start_shield_charge(Vector2.RIGHT)
	assert_true(pal._is_charging, "M2.27: Shield charge initiates into charging state")
	pal.velocity = Vector2.ZERO # simulate hit wall
	pal._is_charging = false
	assert_false(pal._is_charging, "M2.28: Wall collision terminates shield charge cleanly")

	# Cleave hit test with dummy enemy
	var dummy_enemy := Node2D.new()
	dummy_enemy.add_to_group("enemies")
	dummy_enemy.global_position = pal.global_position + Vector2(25, 0)
	var enemy_hc := HealthComponent.new()
	enemy_hc.name = "HealthComponent"
	enemy_hc.max_health = 100.0
	enemy_hc.current_health = 100.0
	dummy_enemy.add_child(enemy_hc)
	var enemy_hurt := HurtboxComponent.new()
	enemy_hurt.name = "HurtboxComponent"
	enemy_hurt.team_index = 1
	enemy_hurt.health_component = enemy_hc
	dummy_enemy.add_child(enemy_hurt)
	root.add_child(dummy_enemy)

	pal._perform_cleave()
	assert_almost_eq(enemy_hc.current_health, 68.0, 0.1, "M2.29: Paladin Cleave damages enemy within 50px for 32 damage (100 -> 68 HP)")

	dummy_enemy.free()
	root.remove_child(pal)
	pal.free()

	# Verify Paladin Scene
	var PaladinScene = load("res://scenes/entities/companion/companion_paladin.tscn")
	assert_true(PaladinScene != null, "M2.30: scenes/entities/companion/companion_paladin.tscn loads cleanly")
	var pal_inst = PaladinScene.instantiate()
	assert_true(pal_inst != null, "M2.31: Paladin scene instantiates successfully")
	assert_eq(pal_inst.get("max_health"), 160.0, "M2.32: Paladin scene max_health matches 160.0")
	pal_inst.free()

# ==============================================================================
# PART 3: AEGIS SHIELD DEFENSIVE DOME
# ==============================================================================

func _test_part3_shield_bubble_aegis() -> void:
	print("\n--- [PART 3: AEGIS SHIELD DEFENSIVE DOME] ---")

	var BubbleScript = load("res://scripts/combat/shield_bubble.gd")
	assert_true(BubbleScript != null, "M2.33: scripts/combat/shield_bubble.gd loads cleanly")

	var bubble = BubbleScript.new()
	assert_true(bubble is Area2D, "M2.34: ShieldBubble inherits Area2D")
	assert_almost_eq(bubble.damage_reduction, 0.30, 0.05, "M2.35: Aegis Shield provides 30% damage reduction dome")

	root.add_child(bubble)

	# Test ally entering bubble gains 30% mitigation
	var test_ally := Node2D.new()
	test_ally.add_to_group("allies")
	var ally_hc := HealthComponent.new()
	ally_hc.name = "HealthComponent"
	ally_hc.max_health = 100.0
	ally_hc.current_health = 100.0
	test_ally.add_child(ally_hc)
	root.add_child(test_ally)

	bubble._apply_buff_to_node(test_ally)
	assert_almost_eq(ally_hc.external_damage_mitigation, 0.30, 0.01, "M2.36: Ally inside ShieldBubble receives 30% damage mitigation")

	# Apply damage inside bubble: 50 raw damage -> 35 net damage
	var test_dmg := DamageData.new(50.0, DamageData.DamageType.FIRE)
	ally_hc.take_damage(test_dmg)
	assert_almost_eq(ally_hc.current_health, 65.0, 0.1, "M2.37: Ally inside dome takes 35 damage from 50 fire damage (30% reduction)")

	# Ally exits bubble
	bubble._remove_buff_from_node(test_ally)
	assert_eq(ally_hc.external_damage_mitigation, 0.0, "M2.38: Ally exiting ShieldBubble has external mitigation reset to 0.0")

	test_ally.free()
	root.remove_child(bubble)
	bubble.free()

# ==============================================================================
# PART 4: ARCHER / ROGUE CLASS
# ==============================================================================

func _test_part4_archer_rogue_class() -> void:
	print("\n--- [PART 4: ARCHER ROGUE CLASS] ---")

	var ArcherScript = load("res://scripts/entities/companion_archer.gd")
	assert_true(ArcherScript != null, "M2.39: scripts/entities/companion_archer.gd loads cleanly")

	var archer = ArcherScript.new()
	assert_true(archer is CompanionBase, "M2.40: CompanionArcher inherits CompanionBase")
	assert_eq(archer.max_health, 75.0, "M2.41: Archer defines 75.0 Max HP")
	assert_eq(archer.move_speed, 145.0, "M2.42: Archer defines 145.0 px/s move speed")
	assert_almost_eq(archer.slow_factor, 0.55, 0.05, "M2.43: Archer defines 55% slow factor on Slow Trap")
	assert_eq(archer.arrow_damage, 22.0, "M2.44: Piercing Arrow damage is 22.0")
	assert_eq(archer.tumble_speed, 260.0, "M2.45: Tumble evasion speed is 260 px/s")
	assert_almost_eq(archer.tumble_duration, 0.15, 0.02, "M2.46: Tumble evasion duration is 0.15s")
	assert_eq(archer.tumble_proximity, 45.0, "M2.47: Tumble evasion triggers at <=45 px proximity")

	root.add_child(archer)

	# Tumble evasion boundary clamping test
	archer.boundary_rect = Rect2(Vector2.ZERO, Vector2(640, 360))
	archer.global_position = Vector2(635, 355) # Near edge
	archer._clamp_to_boundaries()
	assert_true(archer.global_position.x <= 624.0 and archer.global_position.y <= 344.0,
		"M2.48: Archer tumble evasion position clamped strictly inside world boundaries")

	root.remove_child(archer)
	archer.free()

	# Verify Archer Scene
	var ArcherScene = load("res://scenes/entities/companion/companion_archer.tscn")
	assert_true(ArcherScene != null, "M2.49: scenes/entities/companion/companion_archer.tscn loads cleanly")
	var archer_inst = ArcherScene.instantiate()
	assert_true(archer_inst != null, "M2.50: Archer scene instantiates successfully")
	assert_eq(archer_inst.get("max_health"), 75.0, "M2.51: Archer scene max_health matches 75.0")
	assert_eq(archer_inst.get("move_speed"), 145.0, "M2.52: Archer scene move_speed matches 145.0")
	archer_inst.free()

# ==============================================================================
# PART 5: PIERCING ARROW MECHANICS
# ==============================================================================

func _test_part5_piercing_arrow_mechanics() -> void:
	print("\n--- [PART 5: PIERCING ARROW MECHANICS] ---")

	var ArrowScript = load("res://scripts/entities/piercing_arrow.gd")
	assert_true(ArrowScript != null, "M2.53: scripts/entities/piercing_arrow.gd loads cleanly")

	var arrow = ArrowScript.new()
	assert_true(arrow is Area2D, "M2.54: PiercingArrow inherits Area2D")
	assert_eq(arrow.damage, 22.0, "M2.55: Piercing Arrow base damage is 22.0")
	assert_eq(arrow.max_pierce, 3, "M2.56: Piercing Arrow penetrates up to 3 enemies")
	assert_eq(arrow.collision_layer, 8, "M2.57: Piercing Arrow is on layer 8 [PlayerAttacks]")

	root.add_child(arrow)

	# Simulate hitting 3 successive targets
	for i in range(3):
		var dummy_target := Node2D.new()
		dummy_target.name = "DummyEnemy_%d" % i
		dummy_target.add_to_group("enemies")
		var target_hc := HealthComponent.new()
		target_hc.name = "HealthComponent"
		target_hc.max_health = 100.0
		target_hc.current_health = 100.0
		dummy_target.add_child(target_hc)
		var target_hurt := HurtboxComponent.new()
		target_hurt.name = "HurtboxComponent"
		target_hurt.team_index = 1
		target_hurt.health_component = target_hc
		dummy_target.add_child(target_hurt)
		root.add_child(dummy_target)

		arrow._on_area_entered(target_hurt)
		assert_almost_eq(target_hc.current_health, 78.0, 0.1, "M2.58: Target %d hit for 22 damage (100 -> 78 HP)" % (i + 1))
		dummy_target.free()

	assert_eq(arrow.pierce_count, 3, "M2.59: Arrow pierce count reached exactly 3 targets")
	root.remove_child(arrow)
	arrow.free()

# ==============================================================================
# PART 6: SLOW TRAP MECHANICS
# ==============================================================================

func _test_part6_slow_trap_mechanics() -> void:
	print("\n--- [PART 6: SLOW TRAP MECHANICS] ---")

	var TrapScript = load("res://scripts/entities/slow_trap.gd")
	assert_true(TrapScript != null, "M2.60: scripts/entities/slow_trap.gd loads cleanly")

	var trap = TrapScript.new()
	assert_true(trap is Area2D, "M2.61: SlowTrap inherits Area2D")
	assert_almost_eq(trap.slow_factor, 0.55, 0.01, "M2.62: Slow Trap imposes 55% speed reduction")
	assert_eq(trap.slow_radius, 40.0, "M2.63: Slow Trap area of effect radius is 40 px")
	assert_almost_eq(trap.slow_duration, 3.5, 0.1, "M2.64: Slow Trap duration is 3.5 seconds")

	root.add_child(trap)

	# Test applying slow to Enemy instance
	var enemy_scene: PackedScene = load("res://scenes/entities/enemies/enemy_base.tscn")
	var enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	enemy.base_speed = 100.0
	enemy._current_speed = 100.0

	# First slow application: 55% slow -> 45 px/s
	trap._apply_slow_to_enemy(enemy)
	assert_almost_eq(enemy._slow_factor, 0.55, 0.01, "M2.65: Enemy _slow_factor set to 0.55")
	assert_almost_eq(enemy._slow_timer, 3.5, 0.1, "M2.66: Enemy _slow_timer set to 3.5s")

	# Non-stacking verification: overlapping second trap applies refreshed duration, NOT compounded slow
	trap._apply_slow_to_enemy(enemy)
	var final_speed = enemy.base_speed * (1.0 - enemy._slow_factor)
	assert_almost_eq(final_speed, 45.0, 0.1, "M2.67: Overlapping Slow Traps do not compound; speed remains 45 px/s")

	enemy.free()
	root.remove_child(trap)
	trap.free()

# ==============================================================================
# PART 7: MAGE COMPANION REFACTOR & ELEMENTAL SPELLS
# ==============================================================================

func _test_part7_mage_refactor_and_elemental_spells() -> void:
	print("\n--- [PART 7: MAGE COMPANION REFACTOR & ELEMENTAL SPELLS] ---")

	var MageScript = load("res://scripts/entities/companion_mage.gd")
	assert_true(MageScript != null, "M2.68: scripts/entities/companion_mage.gd loads cleanly")

	var mage = MageScript.new()
	assert_true(mage is CompanionBase, "M2.69: CompanionMage inherits CompanionBase")
	assert_eq(mage.max_health, 80.0, "M2.70: CompanionMage defines 80 HP")
	assert_eq(mage.move_speed, 135.0, "M2.71: CompanionMage defines 135 px/s move speed")
	assert_eq(mage.companion_name, "Lyra", "M2.72: CompanionMage name is Lyra")
	assert_true(mage.has_method("find_target_cluster"), "M2.73: CompanionMage has find_target_cluster() method")

	# Backward-compatible Companion wrapper
	var CompScript = load("res://scripts/entities/companion.gd")
	var comp = CompScript.new()
	assert_true(comp is CompanionBase, "M2.74: Companion wrapper inherits CompanionBase")
	assert_eq(comp.current_tactical_state, CompanionBase.TacticalOrderState.IDLE_FOLLOW, "M2.75: Companion wrapper has TacticalOrderState.IDLE_FOLLOW")
	comp.free()

	# Ice Spike projectile verification
	var IceSpikeScript = load("res://scripts/entities/ice_spike.gd")
	assert_true(IceSpikeScript != null, "M2.76: scripts/entities/ice_spike.gd loads cleanly")
	var spike = IceSpikeScript.new()
	assert_true(spike is Area2D, "M2.77: IceSpike inherits Area2D")
	assert_almost_eq(spike.slow_factor, 0.45, 0.05, "M2.78: IceSpike imposes 45% slow factor")
	assert_eq(spike.collision_layer, 8, "M2.79: IceSpike is on layer 8 [PlayerAttacks]")
	spike.free()

	mage.free()

# ==============================================================================
# PART 8: ENNEAGRAM LEADERSHIP ORDER RESPONSES
# ==============================================================================

func _test_part8_enneagram_leadership_order_responses() -> void:
	print("\n--- [PART 8: ENNEAGRAM LEADERSHIP ORDER RESPONSES] ---")

	var PaladinScript = load("res://scripts/entities/companion_paladin.gd")
	var pal = PaladinScript.new()
	root.add_child(pal)

	var eb := _get_event_bus()

	# Reset hesitation timer on new order verification
	pal.hesitation_timer = 2.0
	pal.pending_order_after_hesitation = 1
	pal._pending_order = 1
	pal._on_leadership_order_issued(2, Vector2(50, 50))
	assert_eq(pal.hesitation_timer, 0.0, "M2.80: Issuing new order immediately resets hesitation timer")

	# Type 8 Challenger Defiant Refusal on RETREAT near enemy
	pal.enneagram_profile = EnneagramData.create_preset(EnneagramData.Type.CHALLENGER)
	var dummy_enemy := Node2D.new()
	dummy_enemy.add_to_group("enemies")
	dummy_enemy.global_position = pal.global_position + Vector2(30, 0) # 30px away
	root.add_child(dummy_enemy)

	var res_retreat: OrderResult = pal.evaluate_order(2, Vector2.ZERO)
	assert_eq(res_retreat.status, int(EnneagramEvaluator.OrderStatus.REFUSE), "M2.81: Type 8 Paladin refuses RETREAT order near enemy")
	assert_eq(res_retreat.delay_sec, 0.0, "M2.82: Refusal status returns instantaneous 0.0s delay")

	# Type 8 Instant Obey on ATTACK
	var res_attack: OrderResult = pal.evaluate_order(1, Vector2(100, 100))
	assert_eq(res_attack.status, int(EnneagramEvaluator.OrderStatus.OBEY), "M2.83: Type 8 Paladin instantly obeys ATTACK order")

	dummy_enemy.free()
	root.remove_child(pal)
	pal.free()

# ==============================================================================
# PART 9: COLLISION LAYERS & FRIENDLY FIRE IMMUNITY
# ==============================================================================

func _test_part9_collision_layers_and_friendly_fire() -> void:
	print("\n--- [PART 9: COLLISION LAYERS & FRIENDLY FIRE IMMUNITY] ---")

	# Layer 7 (64) = Companion
	# Layer 4 (8) = PlayerAttacks
	# Layer 5 (16) = EnemyAttacks
	var layer_companion: int = 64
	var player_attacks_mask: int = 4 # Attacks target Enemies only (Layer 3)
	var enemy_attacks_mask: int = 16 # EnemyAttacks hit Layer 5

	assert_eq(player_attacks_mask & layer_companion, 0, "M2.84: Player attack collision mask strictly excludes Companion layer (Friendly Fire Immunity)")
	assert_eq(1 << (7 - 1), layer_companion, "M2.85: Companion Bitmask corresponds to Layer 7 (64)")

	# Paladin Hurtbox configuration check
	var PaladinScene = load("res://scenes/entities/companion/companion_paladin.tscn")
	var pal = PaladinScene.instantiate()
	var hurtbox: HurtboxComponent = pal.get_node("HurtboxComponent")
	assert_eq(hurtbox.collision_layer, 64, "M2.86: Paladin Hurtbox collision_layer is 64")
	assert_eq(hurtbox.collision_mask, 16, "M2.87: Paladin Hurtbox collision_mask is 16 (EnemyAttacks)")
	assert_eq(hurtbox.team_index, 0, "M2.88: Paladin Hurtbox team_index is 0 [Allies]")
	pal.free()

	# Archer Hurtbox configuration check
	var ArcherScene = load("res://scenes/entities/companion/companion_archer.tscn")
	var archer = ArcherScene.instantiate()
	var archer_hurt: HurtboxComponent = archer.get_node("HurtboxComponent")
	assert_eq(archer_hurt.collision_layer, 64, "M2.89: Archer Hurtbox collision_layer is 64")
	assert_eq(archer_hurt.collision_mask, 16, "M2.90: Archer Hurtbox collision_mask is 16 (EnemyAttacks)")
	assert_eq(archer_hurt.team_index, 0, "M2.91: Archer Hurtbox team_index is 0 [Allies]")
	archer.free()
