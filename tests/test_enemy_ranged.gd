extends RefCounted

## Unit tests for EnemyRanged class.

func run_all(runner: SceneTree) -> void:
	await _test_instantiation(runner)
	await _test_kite_movement(runner)
	await _test_shooting_behaviour(runner)
	await _test_projectile_damage(runner)

func _test_instantiation(runner: SceneTree) -> void:
	var enemy_scene := preload("res://scenes/entities/enemies/enemy_ranged.tscn")
	var enemy := enemy_scene.instantiate() as EnemyRanged
	if enemy == null:
		runner.record_fail("EnemyRanged Instantiation", "Could not instantiate EnemyRanged from scene")
		return

	# Check defaults
	runner.assert_eq(enemy.enemy_type, Enemy.EnemyType.RANGED, "Should be EnemyType.RANGED")
	enemy.free()

func _test_kite_movement(runner: SceneTree) -> void:
	var root := Node2D.new()
	runner.root.add_child(root)

	var player := CharacterBody2D.new()
	player.add_to_group("player")
	player.global_position = Vector2(0, 0)
	root.add_child(player)

	var enemy_scene := preload("res://scenes/entities/enemies/enemy_ranged.tscn")
	var enemy := enemy_scene.instantiate() as EnemyRanged
	enemy.global_position = Vector2(100, 0) # Distance 100 < 120 (should retreat)
	enemy._target = player
	root.add_child(enemy)

	# Initial ready sets target and stats. We manually override current speed to be sure.
	enemy._current_speed = 60.0

	# Process physics
	enemy._physics_process(0.1)

	# Should move away from player (positive X direction, because it's to the right of player)
	runner.assert_true(enemy.velocity.x > 0.0, "Enemy should have positive X velocity to kite away from player", str(enemy.velocity))

	enemy.global_position = Vector2(300, 0) # Distance 300 > 200 (should advance)
	enemy._physics_process(0.1)
	runner.assert_true(enemy.velocity.x < 0.0, "Enemy should have negative X velocity to advance towards player", str(enemy.velocity))

	root.queue_free()

func _test_shooting_behaviour(runner: SceneTree) -> void:
	var root := Node2D.new()
	runner.root.add_child(root)

	var player := CharacterBody2D.new()
	player.add_to_group("player")
	player.global_position = Vector2(0, 0)
	root.add_child(player)

	var enemy_scene := preload("res://scenes/entities/enemies/enemy_ranged.tscn")
	var enemy := enemy_scene.instantiate() as EnemyRanged
	enemy.enemy_projectile_scene = preload("res://scenes/entities/projectile/enemy_projectile.tscn")
	enemy.global_position = Vector2(150, 0) # Distance 150 (should stand and shoot)
	enemy._target = player
	enemy._attack_timer = 0.05
	root.add_child(enemy)

	# Process physics - timer should decrease and trigger shoot
	enemy._physics_process(0.1)

	runner.assert_true(enemy.velocity == Vector2.ZERO, "Enemy should stand still while in shooting range", str(enemy.velocity))

	# Wait for deferred add_child if any
	await runner.process_frame

	var found_projectile = false
	for child in root.get_children():
		if child is EnemyProjectile:
			found_projectile = true
			break

	runner.assert_true(found_projectile, "Enemy should spawn projectile when in range and timer expires")

	root.queue_free()

func _test_projectile_damage(runner: SceneTree) -> void:
	var root := Node2D.new()
	runner.root.add_child(root)

	# Player Team setup
	var hurtbox := HurtboxComponent.new()
	hurtbox.team_index = 0 # Player team

	var health := HealthComponent.new()
	health.max_health = 100.0
	health.current_health = 100.0
	hurtbox.health_component = health

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	hurtbox.add_child(collision)

	root.add_child(health)
	root.add_child(hurtbox)

	# Enemy Projectile setup
	var proj := EnemyProjectile.new()
	proj.damage = 10.0

	var proj_collision := CollisionShape2D.new()
	var proj_shape := CircleShape2D.new()
	proj_shape.radius = 4.0
	proj_collision.shape = proj_shape
	proj.add_child(proj_collision)

	root.add_child(proj)

	proj.global_position = hurtbox.global_position

	# Manually trigger area enter to simulate hit
	proj._on_area_entered(hurtbox)

	runner.assert_true(health.current_health < 100.0, "Projectile should damage target on team 0", "Current health: %f" % health.current_health)

	root.queue_free()
