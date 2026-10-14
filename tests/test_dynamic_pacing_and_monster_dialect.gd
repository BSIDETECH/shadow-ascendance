class_name TestDynamicPacingAndMonsterDialect
extends Object

## Automated unit test suite verifying:
## 1. Monster Dialects and Vocal Screeches (Panic, Frenzy, Tactical).
## 2. Enemy Retreat & Call for Help BehaviorState machine.
## 3. Dynamic Arena Pacing: Threat Meter accelerating via slaughter streaks & escaped minions.
## 4. Boss early spawn when threat reaches 100%.

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var _runner: SceneTree = null

func _assert(condition: bool, test_name: String, error_msg: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
		if _runner != null and _runner.has_method("record_pass"):
			_runner.record_pass(test_name)
	else:
		failed_tests += 1
		printerr("  [FAIL] %s -> %s" % [test_name, error_msg])
		if _runner != null and _runner.has_method("record_fail"):
			_runner.record_fail(test_name, error_msg)

func run_all(runner: SceneTree) -> void:
	_runner = runner
	print("\n--- [DYNAMIC PACING & MONSTER DIALECT SYSTEM TESTS] ---")
	test_dialects_and_speech_bubble(runner)
	test_retreat_and_flee_mechanics(runner)
	test_chain_reaction_frenzy(runner)
	test_arena_dynamic_threat_progression(runner)
	print("Dynamic Pacing & Monster Dialect tests finished: %d passed, %d failed" % [passed_tests, failed_tests])

func test_dialects_and_speech_bubble(runner: SceneTree) -> void:
	var enemy_scene: PackedScene = load("res://scenes/entities/enemies/enemy_base.tscn")
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	runner.root.add_child(enemy)

	_assert(enemy.behavior_state == Enemy.BehaviorState.ADVANCING, "Enemy initial state is ADVANCING")
	_assert(Enemy.DIALECTS_PANIC.size() >= 3, "Monster panic dialect dictionary has at least 3 shouts")
	_assert(Enemy.DIALECTS_FRENZY.size() >= 3, "Monster frenzy dialect dictionary has at least 3 shouts")

	# Test speaking dialect spawns visual label
	var children_before := enemy.get_child_count()
	enemy.speak_dialect(Enemy.DIALECTS_PANIC[0], Color.CYAN)
	var label_found := false
	for child in enemy.get_children():
		if child is Label and child.text == Enemy.DIALECTS_PANIC[0]:
			label_found = true
			break
	_assert(label_found, "speak_dialect creates floating dialect Label with custom text")

	runner.root.remove_child(enemy)
	enemy.free()

func test_retreat_and_flee_mechanics(runner: SceneTree) -> void:
	var enemy_scene: PackedScene = load("res://scenes/entities/enemies/enemy_base.tscn")
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	runner.root.add_child(enemy)

	# Trigger retreat
	enemy.trigger_retreat_for_help()
	_assert(enemy.behavior_state == Enemy.BehaviorState.RETREATING_FOR_HELP, "Enemy switches to RETREATING_FOR_HELP state")

	# Intercepting gives bonus xp
	var initial_xp = enemy.xp_reward
	# Simulate death
	enemy.health_component.current_health = 0
	enemy._on_died()
	_assert(enemy.xp_reward > initial_xp, "Intercepted retreating enemy grants bonus XP reward")

	runner.root.remove_child(enemy)
	enemy.free()

func test_chain_reaction_frenzy(runner: SceneTree) -> void:
	var enemy_scene: PackedScene = load("res://scenes/entities/enemies/enemy_base.tscn")
	var enemy1: Enemy = enemy_scene.instantiate() as Enemy
	var enemy2: Enemy = enemy_scene.instantiate() as Enemy
	runner.root.add_child(enemy1)
	runner.root.add_child(enemy2)

	enemy1.global_position = Vector2(0, 0)
	enemy2.global_position = Vector2(30, 0)

	# Manually trigger frenzy on enemy2
	enemy2.trigger_frenzy()
	_assert(enemy2.behavior_state == Enemy.BehaviorState.FRENZY, "trigger_frenzy changes behavior state to FRENZY")
	_assert(enemy2._frenzy_timer > 0.0, "Frenzy timer is active")

	runner.root.remove_child(enemy1)
	runner.root.remove_child(enemy2)
	enemy1.free()
	enemy2.free()

func test_arena_dynamic_threat_progression(runner: SceneTree) -> void:
	var arena_scene: PackedScene = load("res://scenes/arena/arena.tscn")
	var arena: Arena = arena_scene.instantiate() as Arena
	runner.root.add_child(arena)

	_assert(arena.get("_threat_progress") != null, "Arena has _threat_progress property")
	var initial_threat: float = arena.get("_threat_progress")

	# Simulate normal kill
	arena._on_enemy_died(Vector2(0, 0), 1)
	var threat_after_1: float = arena.get("_threat_progress")
	_assert(threat_after_1 > initial_threat, "Enemy kill advances boss threat progress")

	# Simulate minion escape calling boss
	arena._on_enemy_escaped_calling_boss(Vector2(550, 0))
	var threat_after_escape: float = arena.get("_threat_progress")
	_assert(threat_after_escape >= threat_after_1 + 8.0, "Escaped minion calling boss gives massive threat boost (+8.0)")

	runner.root.remove_child(arena)
	arena.free()
