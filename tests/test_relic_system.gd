extends RefCounted

## Unit tests for the Relic System

class MockHealthComponent extends Node:
	var max_health: float = 100.0
	var current_health: float = 100.0

class MockPlayer extends Node:
	var move_speed_mult: float = 1.0
	var lifesteal_on_kill: float = 0.0
	var dash_cooldown_mult: float = 1.0

	func _init() -> void:
		add_to_group("player")

class MockCompanion extends Node:
	var max_health: float = 100.0

	func _init() -> void:
		add_to_group("companions")
		var hc = MockHealthComponent.new()
		hc.name = "HealthComponent"
		add_child(hc)

func run_all(runner: SceneTree) -> void:
	await _test_relics(runner)

func _test_relics(runner: SceneTree) -> void:
	# Add RelicSystem dynamically for the test if it's not already in the tree
	var relic_system = null
	if runner.root.has_node("RelicSystem"):
		relic_system = runner.root.get_node("RelicSystem")
	else:
		relic_system = load("res://scripts/systems/relic_system.gd").new()
		relic_system.name = "RelicSystem"
		runner.root.add_child(relic_system)

	var player = MockPlayer.new()
	var companion = MockCompanion.new()

	runner.root.add_child(player)
	runner.root.add_child(companion)

	var starter_relics = relic_system.get_starter_relics()

	assert(starter_relics.size() == 4, "Should have 4 starter relics")

	for relic in starter_relics:
		relic_system.add_relic(relic)

	# 1. Botas de Vento (+15% vel)
	# move_speed_mult should go from 1.0 to 1.15
	assert(is_equal_approx(player.move_speed_mult, 1.15), "Player move_speed_mult should be 1.15, was " + str(player.move_speed_mult))

	# 2. Brasão do Guardião (+20% vida para companions)
	# max_health should go from 100 to 120
	assert(is_equal_approx(companion.max_health, 120.0), "Companion max_health should be 120.0, was " + str(companion.max_health))
	var hc = companion.get_node("HealthComponent") as MockHealthComponent
	assert(is_equal_approx(hc.max_health, 120.0), "Companion HealthComponent max_health should be 120.0, was " + str(hc.max_health))

	# 3. Colar Vampírico (cura 2 HP por morte)
	# lifesteal_on_kill should go from 0.0 to 2.0
	assert(is_equal_approx(player.lifesteal_on_kill, 2.0), "Player lifesteal_on_kill should be 2.0, was " + str(player.lifesteal_on_kill))

	# 4. Ampulheta Arcana (-10% cooldowns)
	# dash_cooldown_mult should go from 1.0 to 0.9
	assert(is_equal_approx(player.dash_cooldown_mult, 0.90), "Player dash_cooldown_mult should be 0.9, was " + str(player.dash_cooldown_mult))

	player.queue_free()
	companion.queue_free()

	print("[OK] _test_relics passed successfully")
