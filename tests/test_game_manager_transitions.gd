class_name TestGameManagerTransitions
extends Node

## Unit tests to validate GameManager's change_scene_with_fade method.

func run_all(runner: SceneTree) -> void:
	print("\n--- [GAME MANAGER TRANSITIONS TESTS] ---")
	test_change_scene_with_fade_starts_transition(runner)
	test_change_scene_with_fade_no_tree(runner)

func test_change_scene_with_fade_starts_transition(runner: SceneTree) -> void:
	var gm = runner.root.get_node_or_null("GameManager")
	if gm == null:
		runner.call("record_skip", "GM_TRANS.01: GameManager Exists", "Could not find GameManager")
		return

	var initial_transitioning = gm.is_transitioning

	# Simulate setting it to false just in case
	gm.is_transitioning = false

	var emitted = [false]
	var path_received = [""]

	var callable = func(path):
		emitted[0] = true
		path_received[0] = path

	gm.scene_transition_started.connect(callable)

	# Using Arena as dummy target since it's defined
	gm.change_scene_with_fade("res://scenes/arena/arena.tscn")

	runner.call("assert_true", emitted[0], "GM_TRANS.02: scene_transition_started emitted on change_scene_with_fade")
	runner.call("assert_eq", path_received[0], "res://scenes/arena/arena.tscn", "GM_TRANS.03: EventBus emitted with correct target path")
	runner.call("assert_true", gm.is_transitioning, "GM_TRANS.04: is_transitioning is set to true after start")

	# Try a concurrent change_scene_with_fade
	var emitted_concurrent = [false]
	var concurrent_callable = func(_path):
		emitted_concurrent[0] = true

	gm.scene_transition_started.connect(concurrent_callable)

	gm.change_scene_with_fade("res://scenes/hub/greyrock_village.tscn")
	runner.call("assert_false", emitted_concurrent[0], "GM_TRANS.05: Concurrent change_scene_with_fade is blocked while is_transitioning=true")

	gm.scene_transition_started.disconnect(callable)
	gm.scene_transition_started.disconnect(concurrent_callable)

	# Reset state
	gm.is_transitioning = false

func test_change_scene_with_fade_no_tree(runner: SceneTree) -> void:
	var gm = load("res://scripts/autoloads/game_manager.gd").new()

	var emitted_started = [false]
	var emitted_finished = [false]

	var callable_started = func(_path): emitted_started[0] = true
	var callable_finished = func(_path): emitted_finished[0] = true

	gm.scene_transition_started.connect(callable_started)
	gm.scene_transition_finished.connect(callable_finished)

	# Since it's not in the SceneTree, tree will be null
	gm.change_scene_with_fade("res://scenes/arena/arena.tscn")

	runner.call("assert_true", emitted_started[0], "GM_TRANS.06: scene_transition_started emitted when tree is null")
	runner.call("assert_true", emitted_finished[0], "GM_TRANS.07: scene_transition_finished emitted when tree is null")
	runner.call("assert_false", gm.is_transitioning, "GM_TRANS.08: is_transitioning reset to false when tree is null")

	gm.scene_transition_started.disconnect(callable_started)
	gm.scene_transition_finished.disconnect(callable_finished)
	gm.free()
