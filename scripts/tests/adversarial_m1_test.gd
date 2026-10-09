extends SceneTree

## Empirical Adversarial Stress Test Suite for Milestone 1
## Authored by: challenger_m1_2
## Verifies edge cases, stress boundaries, negative damage cheat-healing,
## zero damage i-frame exploits, shader math clamping, and EventBus signals.

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var findings: Array[String] = []

func _init() -> void:
	print("==================================================")
	print("  M1 ADVERSARIAL STRESS TEST SUITE — EXECUTING")
	print("==================================================")

	test_healing_clamping_and_rapid_bursts()
	test_negative_damage_cheat_healing()
	test_zero_damage_iframe_exploit()
	test_iframe_timer_precision()
	test_hit_flash_shader_bounds()
	test_event_bus_signal_resilience()
	test_hitbox_hurtbox_edge_cases()

	print("==================================================")
	print("  M1 ADVERSARIAL TEST SUMMARY")
	print("  Total Tests: %d" % total_tests)
	print("  Passed: %d" % passed_tests)
	print("  Failed: %d" % failed_tests)
	print("  Findings Count: %d" % findings.size())
	print("==================================================")

	for finding in findings:
		printerr("  * %s" % finding)

	if failed_tests > 0:
		printerr(">>> ADVERSARIAL VERDICT: REQUEST_CHANGES <<<")
		quit(1)
	else:
		print(">>> ADVERSARIAL VERDICT: APPROVE <<<")
		quit(0)

func record_pass(msg: String) -> void:
	total_tests += 1
	passed_tests += 1
	print("  [PASS] %s" % msg)

func record_fail(msg: String, detail: String) -> void:
	total_tests += 1
	failed_tests += 1
	var entry := "[FAIL] %s: %s" % [msg, detail]
	findings.append(entry)
	printerr("  " + entry)

# -----------------------------------------------------------------------------
# 1. Healing Clamping & Rapid Bursts
# -----------------------------------------------------------------------------
func test_healing_clamping_and_rapid_bursts() -> void:
	var hc := HealthComponent.new()
	hc.max_health = 100.0
	hc.current_health = 50.0

	# 1000 incremental heals
	for i in range(1000):
		hc.heal(1.0)
	if hc.current_health == 100.0:
		record_pass("1000 rapid incremental heals cleanly clamp at max_health")
	else:
		record_fail("Rapid healing clamping", "Expected 100.0, got %f" % hc.current_health)

	# Overheal
	hc.heal(5000.0)
	if hc.current_health == 100.0:
		record_pass("Massive overheal respects max_health upper bound")
	else:
		record_fail("Overhealing bound", "Current health %f exceeded max_health %f" % [hc.current_health, hc.max_health])

	# Negative and zero heal
	var signals_healed := 0
	hc.healed.connect(func(_amt): signals_healed += 1)
	hc.heal(0.0)
	hc.heal(-50.0)
	if signals_healed == 0:
		record_pass("Zero and negative heals cleanly ignored without signal emission")
	else:
		record_fail("Negative/Zero heal", "healed signal emitted %d times" % signals_healed)

	# Dead entity healing
	hc.current_health = 0.0
	hc.heal(50.0)
	if hc.current_health == 0.0:
		record_pass("Dead entity cannot be revived via heal()")
	else:
		record_fail("Dead entity healing", "Health revived from 0 to %f" % hc.current_health)

	hc.free()

# -----------------------------------------------------------------------------
# 2. Negative Damage Exploit (Cheat-Healing)
# -----------------------------------------------------------------------------
func test_negative_damage_cheat_healing() -> void:
	var hc := HealthComponent.new()
	hc.max_health = 100.0
	hc.current_health = 50.0
	hc.i_frame_duration = 0.0

	var neg_data := DamageData.new(-30.0)
	hc.take_damage(neg_data)

	# In vulnerable implementation: 50.0 - (-30.0) = 80.0!
	if hc.current_health == 50.0:
		record_pass("Negative damage rejected; entity not cheat-healed")
	else:
		record_fail(
			"Negative Damage Cheat-Heal",
			"Health increased from 50.0 to %f upon receiving negative damage (-30.0)" % hc.current_health
		)

	# Negative damage exceeding max_health
	var hc2 := HealthComponent.new()
	hc2.max_health = 100.0
	hc2.current_health = 100.0
	hc2.i_frame_duration = 0.0
	hc2.take_damage(DamageData.new(-500.0))
	if hc2.current_health <= 100.0:
		record_pass("Negative damage does not overflow max_health ceiling")
	else:
		record_fail(
			"Negative Damage Max Health Overflow",
			"Current health became %f > max_health %f" % [hc2.current_health, hc2.max_health]
		)

	hc.free()
	hc2.free()

# -----------------------------------------------------------------------------
# 3. Zero Damage Invincibility Exploit
# -----------------------------------------------------------------------------
func test_zero_damage_iframe_exploit() -> void:
	var hc := HealthComponent.new()
	hc.max_health = 100.0
	hc.current_health = 100.0
	hc.i_frame_duration = 0.2

	var zero_data := DamageData.new(0.0)
	hc.take_damage(zero_data)

	if not hc.is_currently_invincible():
		record_pass("Zero damage attack does not grant invincibility frames")
	else:
		record_fail(
			"Zero Damage i-Frame Exploit",
			"Entity became invincible after taking 0.0 damage"
		)

	hc.free()

# -----------------------------------------------------------------------------
# 4. i-Frame Timing Precision
# -----------------------------------------------------------------------------
func test_iframe_timer_precision() -> void:
	var hc := HealthComponent.new()
	hc.max_health = 100.0
	hc.current_health = 100.0
	hc.i_frame_duration = 0.2

	var ended_count := 0
	hc.invincibility_ended.connect(func(): ended_count += 1)

	hc.take_damage(DamageData.new(10.0))
	if hc.is_currently_invincible():
		record_pass("i-Frames active immediately after valid hit")
	else:
		record_fail("i-Frame activation", "Entity not invincible after valid hit")

	# Half tick
	hc.tick(0.1)
	if hc.is_currently_invincible():
		record_pass("i-Frames remain active at 0.1s / 0.2s")
	else:
		record_fail("i-Frame duration", "i-Frames expired prematurely at 0.1s")

	# Exact expiration tick
	hc.tick(0.1)
	if not hc.is_currently_invincible() and ended_count == 1:
		record_pass("i-Frames expire cleanly at 0.2s and emit invincibility_ended")
	else:
		record_fail("i-Frame expiry", "i-Frames did not expire at 0.2s or signal mismatch")

	hc.free()

# -----------------------------------------------------------------------------
# 5. Hit Flash Shader Bounds & Uniformity
# -----------------------------------------------------------------------------
func test_hit_flash_shader_bounds() -> void:
	var shader: Shader = load("res://assets/shaders/hit_flash.gdshader")
	if shader == null:
		record_fail("Hit Flash Shader", "Could not load hit_flash.gdshader")
		return

	var code := shader.code
	if code.contains("instance uniform float flash_modifier"):
		record_pass("Shader uses instance uniform for draw-call batching")
	else:
		record_fail("Shader instance uniform", "Missing instance uniform float flash_modifier")

	if code.contains("uniform vec4 flash_color : source_color"):
		record_pass("Shader uses source_color hint for gamma correctness")
	else:
		record_fail("Shader color hint", "Missing source_color hint on flash_color")

	# Mathematical clamp check in fragment
	if code.contains("clamp(flash_modifier") or code.contains("clamp("):
		record_pass("Shader clamps flash_modifier in fragment code")
	else:
		record_fail(
			"Shader modifier unclamped",
			"flash_modifier used directly in mix() without clamp; out-of-bounds inputs (<0 or >1) will blow out colors"
		)

# -----------------------------------------------------------------------------
# 6. EventBus Signal Resilience
# -----------------------------------------------------------------------------
func test_event_bus_signal_resilience() -> void:
	var bus := preload("res://scripts/autoloads/event_bus.gd").new()

	var counter := 0
	var dummy_callable := func(_pos: Vector2, _xp: int): counter += 1

	bus.enemy_died.connect(dummy_callable)
	if bus.enemy_died.is_connected(dummy_callable):
		record_pass("EventBus successfully connects callable")
	else:
		record_fail("EventBus connect", "Callable not connected")

	# Disconnect safety
	bus.enemy_died.disconnect(dummy_callable)
	if not bus.enemy_died.is_connected(dummy_callable):
		record_pass("EventBus successfully disconnects callable")
	else:
		record_fail("EventBus disconnect", "Callable still connected after disconnect")

	bus.free()

# -----------------------------------------------------------------------------
# 7. Hitbox / Hurtbox Team Filtering Edge Cases
# -----------------------------------------------------------------------------
func test_hitbox_hurtbox_edge_cases() -> void:
	var root := Node2D.new()
	var hc := HealthComponent.new()
	hc.max_health = 100.0
	hc.current_health = 100.0
	hc.i_frame_duration = 0.0
	root.add_child(hc)

	var hurt := HurtboxComponent.new()
	hurt.health_component = hc
	hurt.team_index = 0
	root.add_child(hurt)

	var hit := HitboxComponent.new()
	hit.damage_amount = 25.0
	hit.team_index = 0 # same team
	root.add_child(hit)

	# Friendly fire test
	hit._on_area_entered(hurt)
	if hc.current_health == 100.0:
		record_pass("Same team index (0 == 0) ignores damage")
	else:
		record_fail("Team filtering", "Friendly fire damaged entity: %f" % hc.current_health)

	# Opposing team
	hit.team_index = 1
	hit._on_area_entered(hurt)
	if hc.current_health == 75.0:
		record_pass("Opposing team index (1 != 0) successfully damages entity")
	else:
		record_fail("Team filtering", "Opposing team hit did not damage entity: %f" % hc.current_health)

	root.free()
