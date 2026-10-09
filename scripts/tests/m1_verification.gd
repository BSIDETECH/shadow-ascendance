extends SceneTree

## Headless Verification Suite for Milestone 1: Project Setup & Combat Foundation
## Tests DamageData, HealthComponent, Hitbox/Hurtbox integration, and EventBus.

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var current_test_name: String = ""

func _init() -> void:
	print("==================================================")
	print("  M1 VERIFICATION SUITE — STARTING")
	print("==================================================")
	
	run_test("DamageData Unit Tests", test_damage_data)
	run_test("HealthComponent Mechanics & Signals", test_health_component)
	run_test("HealthComponent i-Frames & Invincibility", test_health_iframes)
	run_test("Hitbox/Hurtbox Delivery & Team Filtering", test_hitbox_hurtbox)
	run_test("EventBus Signal Architecture", test_event_bus)
	
	print("==================================================")
	print("  M1 VERIFICATION SUMMARY")
	print("  Total Assertions: %d" % total_assertions)
	print("  Passed: %d" % passed_assertions)
	print("  Failed: %d" % failed_assertions)
	print("==================================================")
	
	if failed_assertions == 0:
		print(">>> ALL M1 TESTS PASSED SUCCESSFULLY! <<<")
		quit(0)
	else:
		printerr(">>> M1 TESTS FAILED! Check logs above. <<<")
		quit(1)

func run_test(name: String, test_callable: Callable) -> void:
	current_test_name = name
	print("[TEST] Running: %s" % name)
	test_callable.call()

func assert_true(condition: bool, message: String) -> void:
	total_assertions += 1
	if condition:
		passed_assertions += 1
	else:
		failed_assertions += 1
		printerr("  [FAIL] %s: %s" % [current_test_name, message])

func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	total_assertions += 1
	if actual == expected:
		passed_assertions += 1
	else:
		failed_assertions += 1
		printerr("  [FAIL] %s: %s (Expected '%s', got '%s')" % [current_test_name, message, str(expected), str(actual)])

func assert_almost_eq(actual: float, expected: float, message: String, tolerance: float = 0.001) -> void:
	total_assertions += 1
	if absf(actual - expected) <= tolerance:
		passed_assertions += 1
	else:
		failed_assertions += 1
		printerr("  [FAIL] %s: %s (Expected %f, got %f)" % [current_test_name, message, expected, actual])

# -----------------------------------------------------------------------------
# 1. DamageData Tests
# -----------------------------------------------------------------------------
func test_damage_data() -> void:
	# Default initialization
	var default_data := DamageData.new()
	assert_almost_eq(default_data.amount, 10.0, "Default damage amount should be 10.0")
	assert_eq(default_data.damage_type, DamageData.DamageType.PHYSICAL, "Default type should be PHYSICAL")
	assert_almost_eq(default_data.knockback_force, 50.0, "Default knockback should be 50.0")
	assert_eq(default_data.knockback_direction, Vector2.ZERO, "Default direction should be ZERO")
	assert_true(default_data.source == null, "Default source should be null")
	assert_true(default_data.has_type(DamageData.DamageType.PHYSICAL), "Should have PHYSICAL type flag")
	assert_true(not default_data.has_type(DamageData.DamageType.FIRE), "Should not have FIRE type flag")

	# Custom initialization
	var dummy_source := Node2D.new()
	var custom_type: int = DamageData.DamageType.DARK | DamageData.DamageType.ICE
	var custom_data := DamageData.new(45.5, custom_type, 120.0, Vector2(1, 0), dummy_source)
	assert_almost_eq(custom_data.amount, 45.5, "Custom damage amount matches")
	assert_true(custom_data.has_type(DamageData.DamageType.DARK), "Custom data has DARK type")
	assert_true(custom_data.has_type(DamageData.DamageType.ICE), "Custom data has ICE type")
	assert_true(not custom_data.has_type(DamageData.DamageType.PHYSICAL), "Custom data does not have PHYSICAL")
	assert_almost_eq(custom_data.knockback_force, 120.0, "Custom knockback force matches")
	assert_eq(custom_data.get_knockback_velocity(), Vector2(120.0, 0.0), "Knockback velocity calculated correctly")

	# Duplication test
	var duplicate_data := custom_data.duplicate_data()
	assert_almost_eq(duplicate_data.amount, 45.5, "Duplicated amount matches")
	assert_eq(duplicate_data.damage_type, custom_type, "Duplicated type matches")
	assert_eq(duplicate_data.knockback_direction, Vector2(1, 0), "Duplicated direction matches")
	assert_true(duplicate_data != custom_data, "Duplication creates a distinct object instance")
	dummy_source.free()

# -----------------------------------------------------------------------------
# 2. HealthComponent Mechanics & Signals
# -----------------------------------------------------------------------------
func test_health_component() -> void:
	var health := HealthComponent.new()
	health.max_health = 100.0
	health.current_health = 100.0
	health.i_frame_duration = 0.0 # disable i-frames for raw damage tests

	var received_health_changed: Array = []
	var received_took_damage: Array = []
	var received_died: Array = []
	var received_healed: Array = []

	health.health_changed.connect(func(curr: float, max_hp: float): received_health_changed.append([curr, max_hp]))
	health.took_damage.connect(func(data: DamageData): received_took_damage.append(data))
	health.died.connect(func(): received_died.append(true))
	health.healed.connect(func(amount: float): received_healed.append(amount))

	# Non-lethal damage
	var dmg1 := DamageData.new(35.0, DamageData.DamageType.PHYSICAL)
	health.take_damage(dmg1)
	assert_almost_eq(health.current_health, 65.0, "Current health reduced by 35.0")
	assert_eq(received_health_changed.size(), 1, "health_changed emitted once")
	assert_almost_eq(received_health_changed[0][0], 65.0, "Signal current health matches 65.0")
	assert_almost_eq(received_health_changed[0][1], 100.0, "Signal max health matches 100.0")
	assert_eq(received_took_damage.size(), 1, "took_damage emitted once")
	assert_eq(received_died.size(), 0, "died signal not emitted for non-lethal hit")

	# Healing
	health.heal(20.0)
	assert_almost_eq(health.current_health, 85.0, "Current health healed to 85.0")
	assert_eq(received_healed.size(), 1, "healed signal emitted")
	assert_almost_eq(received_healed[0], 20.0, "healed amount is 20.0")

	# Overhealing capped at max_health
	health.heal(50.0)
	assert_almost_eq(health.current_health, 100.0, "Current health capped at max_health")

	# Lethal damage
	var lethal_dmg := DamageData.new(150.0, DamageData.DamageType.DARK)
	health.take_damage(lethal_dmg)
	assert_almost_eq(health.current_health, 0.0, "Current health clamped to 0.0 on overkill")
	assert_true(not health.is_alive(), "Entity is not alive after lethal damage")
	assert_eq(received_died.size(), 1, "died signal emitted on death")

	# Damage after death should be ignored
	health.take_damage(dmg1)
	assert_almost_eq(health.current_health, 0.0, "Health remains 0.0 after post-death hit")
	assert_eq(received_died.size(), 1, "died signal not emitted again")

	health.free()

# -----------------------------------------------------------------------------
# 3. HealthComponent i-Frames & Invincibility
# -----------------------------------------------------------------------------
func test_health_iframes() -> void:
	var health := HealthComponent.new()
	health.max_health = 100.0
	health.current_health = 100.0
	health.i_frame_duration = 0.2

	var invuln_started: int = 0
	var invuln_ended: int = 0
	health.invincibility_started.connect(func(): invuln_started += 1)
	health.invincibility_ended.connect(func(): invuln_ended += 1)

	# First hit: triggers i-frames
	health.take_damage(DamageData.new(20.0))
	assert_almost_eq(health.current_health, 80.0, "Health after first hit is 80.0")
	assert_true(health.is_currently_invincible(), "Entity is invincible during i-frame window")
	assert_eq(invuln_started, 1, "invincibility_started emitted")

	# Second hit during i-frames: must be ignored
	health.take_damage(DamageData.new(20.0))
	assert_almost_eq(health.current_health, 80.0, "Health unchanged while in i-frames")

	# Advance time partially
	health.tick(0.1)
	assert_true(health.is_currently_invincible(), "Still invincible after 0.1s out of 0.2s")
	health.take_damage(DamageData.new(20.0))
	assert_almost_eq(health.current_health, 80.0, "Health still unchanged at 0.1s")

	# Advance time past expiration
	health.tick(0.15)
	assert_true(not health.is_currently_invincible(), "Invincibility expired after total 0.25s")
	assert_eq(invuln_ended, 1, "invincibility_ended emitted")

	# Third hit: now damages entity again
	health.take_damage(DamageData.new(20.0))
	assert_almost_eq(health.current_health, 60.0, "Health damaged to 60.0 after i-frames ended")

	# Manual invincibility (Tactical Dash support)
	health.tick(0.3) # clear timer
	health.is_invincible = true
	health.take_damage(DamageData.new(30.0))
	assert_almost_eq(health.current_health, 60.0, "Health protected by manual is_invincible flag")
	health.is_invincible = false

	health.free()

# -----------------------------------------------------------------------------
# 4. Hitbox / Hurtbox Integration & Team Filtering
# -----------------------------------------------------------------------------
func test_hitbox_hurtbox() -> void:
	var enemy_root := Node2D.new()
	var enemy_health := HealthComponent.new()
	enemy_health.max_health = 100.0
	enemy_health.current_health = 100.0
	enemy_health.i_frame_duration = 0.0
	enemy_root.add_child(enemy_health)

	var hurtbox := HurtboxComponent.new()
	hurtbox.health_component = enemy_health
	hurtbox.team_index = 1 # Enemy team
	enemy_root.add_child(hurtbox)

	var hitbox := HitboxComponent.new()
	hitbox.damage_amount = 30.0
	hitbox.damage_type = DamageData.DamageType.DARK
	hitbox.knockback_force = 80.0
	hitbox.team_index = 0 # Player team
	enemy_root.add_child(hitbox)

	var hit_landed_called: Array = []
	var hit_received_called: Array = []
	hitbox.hit_landed.connect(func(hb: HurtboxComponent, d: DamageData): hit_landed_called.append(d))
	hurtbox.hit_received.connect(func(d: DamageData): hit_received_called.append(d))

	# Test 1: Friendly fire protection (same team index)
	hitbox.team_index = 1 # same as hurtbox
	hitbox._on_area_entered(hurtbox)
	assert_almost_eq(enemy_health.current_health, 100.0, "Friendly fire ignored when team indices match")
	assert_eq(hit_landed_called.size(), 0, "No hit_landed emitted on friendly fire")

	# Test 2: Valid attack (opposing teams)
	hitbox.team_index = 0 # player attacking enemy
	hitbox._on_area_entered(hurtbox)
	assert_almost_eq(enemy_health.current_health, 70.0, "Enemy took 30.0 damage from player hitbox")
	assert_eq(hit_landed_called.size(), 1, "hit_landed emitted on successful hit")
	assert_eq(hit_received_called.size(), 1, "hit_received emitted on hurtbox")
	assert_true(hit_landed_called[0].has_type(DamageData.DamageType.DARK), "DamageData contains DARK type flag")

	enemy_root.free()

# -----------------------------------------------------------------------------
# 5. EventBus Signal Architecture
# -----------------------------------------------------------------------------
func test_event_bus() -> void:
	var bus := preload("res://scripts/autoloads/event_bus.gd").new()

	var died_reports: Array = []
	var xp_reports: Array = []
	var level_reports: Array = []
	var damage_reports: Array = []

	bus.enemy_died.connect(func(pos: Vector2, xp: int): died_reports.append([pos, xp]))
	bus.xp_collected.connect(func(amt: int): xp_reports.append(amt))
	bus.level_up_requested.connect(func(lvl: int): level_reports.append(lvl))
	bus.damage_dealt.connect(func(target: Node, d: DamageData): damage_reports.append([target, d]))

	# Test emissions via helpers
	bus.emit_enemy_died(Vector2(120, 80), 25)
	assert_eq(died_reports.size(), 1, "enemy_died received")
	assert_eq(died_reports[0][0], Vector2(120, 80), "enemy_died position matches")
	assert_eq(died_reports[0][1], 25, "enemy_died xp matches 25")

	bus.emit_xp_collected(50)
	assert_eq(xp_reports.size(), 1, "xp_collected received")
	assert_eq(xp_reports[0], 50, "xp amount is 50")

	bus.emit_level_up(2)
	assert_eq(level_reports.size(), 1, "level_up_requested received")
	assert_eq(level_reports[0], 2, "new level is 2")

	var dummy_node := Node.new()
	var test_dmg := DamageData.new(15.0)
	bus.emit_damage_dealt(dummy_node, test_dmg)
	assert_eq(damage_reports.size(), 1, "damage_dealt received")
	assert_eq(damage_reports[0][0], dummy_node, "damage_dealt target node matches")
	assert_eq(damage_reports[0][1], test_dmg, "damage_dealt DamageData payload matches")

	dummy_node.free()
	bus.free()
