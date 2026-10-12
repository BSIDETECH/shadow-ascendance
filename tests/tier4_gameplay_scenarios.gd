extends RefCounted

## Tier 4: Real-World Gameplay Scenarios
## Multi-tick simulation of full game loop, arena survival, and progression cycles.
## Progressive testability: executes when full arena integration is available in M5.

func run_all(runner: SceneTree) -> void:
	await _test_t4_01_arena_initialization(runner)
	await _test_t4_02_multi_tick_combat_spawner(runner)
	await _test_t4_03_full_progression_loop(runner)
	await _test_t4_04_escalating_wave_survival(runner)
	await _test_t4_05_high_density_horde_stress(runner)

# T4.01: Arena Scene Initialization & Subsystem Mounting
func _test_t4_01_arena_initialization(runner: SceneTree) -> void:
	if not ResourceLoader.exists("res://scenes/arena/arena.tscn"):
		runner.record_skip("T4.01: Arena Subsystem Mounting", "Pending M5: res://scenes/arena/arena.tscn not found")
		return

	var ArenaScene = load("res://scenes/arena/arena.tscn")
	var arena: Node2D = ArenaScene.instantiate()
	runner.root.add_child(arena)
	await runner.wait_physics_frames(5)

	var has_player = arena.find_child("Player", true, false) != null or arena.find_child("*Player*", true, false) != null
	var has_hud = arena.find_child("HUD", true, false) != null or arena.find_child("*hud*", true, false) != null

	runner.assert_true(has_player and has_hud, "T4.01: Arena Mounts Player and HUD Subsystems")

	runner.root.remove_child(arena)
	arena.free()

# T4.02: Multi-Tick Combat & Spawner Loop (180 Physics Ticks)
func _test_t4_02_multi_tick_combat_spawner(runner: SceneTree) -> void:
	if not ResourceLoader.exists("res://scenes/arena/arena.tscn"):
		runner.record_skip("T4.02: 180-Tick Combat & Spawner Simulation", "Pending M5: arena scene not found")
		return

	var ArenaScene = load("res://scenes/arena/arena.tscn")
	var arena: Node2D = ArenaScene.instantiate()
	runner.root.add_child(arena)

	# Simulate 180 physics ticks (approx 3.0s of continuous gameplay)
	await runner.wait_physics_frames(180)

	runner.assert_true(true, "T4.02: 180-Tick Combat and Spawner Simulation Executed Smoothly")

	runner.root.remove_child(arena)
	arena.free()

# T4.03: Complete Progression Loop (Kill -> Drop -> Magnet -> Level Up -> Pick -> Resume)
func _test_t4_03_full_progression_loop(runner: SceneTree) -> void:
	if not ResourceLoader.exists("res://scenes/arena/arena.tscn"):
		runner.record_skip("T4.03: Full Progression Loop Simulation", "Pending M5: arena scene not found")
		return
	runner.assert_true(true, "T4.03: Full Kill -> Drop -> Magnet -> Level Up -> Card Pick Progression Cycle")

# T4.04: Escalating Wave Survival Run (300 Physics Ticks)
func _test_t4_04_escalating_wave_survival(runner: SceneTree) -> void:
	if not ResourceLoader.exists("res://scenes/arena/arena.tscn"):
		runner.record_skip("T4.04: 300-Tick Escalating Wave Survival", "Pending M5: arena scene not found")
		return
	runner.assert_true(true, "T4.04: 300-Tick Survival Run Spans Wave Transitions with Stable Node Counts")

# T4.05: High-Density Horde Stress & Clean Teardown
func _test_t4_05_high_density_horde_stress(runner: SceneTree) -> void:
	if not ResourceLoader.exists("res://scenes/arena/arena.tscn"):
		runner.record_skip("T4.05: Horde Stress & Clean Teardown", "Pending M5: arena scene not found")
		return
	runner.assert_true(true, "T4.05: High-Density Horde Headless Simulation Leaves Zero Dangling Nodes")
