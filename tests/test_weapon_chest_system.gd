class_name TestWeaponChestSystem
extends Object

## Automated unit test suite verifying:
## 1. WeaponData catalog definitions and properties (dual daggers, greatsword, thunder spear, reaper scythe).
## 2. Player unarmed initial punch state ("soquinho").
## 3. WeaponChest interactive opening, rolling, and equipping weapon on Player.
## 4. Player dynamic hitbox, polygon, damage type, cooldown, and visual FX switching.
## 5. Chest one-time use protection (no duplicate opens).
## 6. GameManager Gacha decoupling (Gacha upgrades do NOT forcibly grant weapons).
## 7. Arena scene hierarchy containing WeaponChest node.

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
	print("\n--- [RANDOM WEAPON CHEST & WEAPON SYSTEM TESTS] ---")
	test_weapon_catalog(runner)
	test_player_unarmed_initial_state(runner)
	test_weapon_chest_interaction(runner)
	test_weapon_switching_and_stats(runner)
	test_gacha_decoupling(runner)
	test_arena_chest_placement(runner)
	print("Weapon Chest & Weapon System tests finished: %d passed, %d failed" % [passed_tests, failed_tests])

func test_weapon_catalog(runner: SceneTree) -> void:
	var weapons: Array[WeaponData] = WeaponData.get_all_weapons()
	_assert(weapons.size() == 4, "WeaponData catalog contains exactly 4 distinct weapons")

	var ids: Array[String] = []
	for w in weapons:
		ids.append(w.id)
		_assert(w.base_damage > 0.0, "Weapon %s has base_damage > 0" % w.id)
		_assert(w.attack_cooldown > 0.0, "Weapon %s has attack_cooldown > 0" % w.id)
		_assert(w.hitbox_polygon.size() >= 3, "Weapon %s has valid polygon geometry (>=3 vertices)" % w.id)
		_assert(w.display_name != "", "Weapon %s has display_name" % w.id)

	_assert(ids.has("dual_daggers"), "Catalog contains dual_daggers")
	_assert(ids.has("greatsword"), "Catalog contains greatsword")
	_assert(ids.has("thunder_spear"), "Catalog contains thunder_spear")
	_assert(ids.has("reaper_scythe"), "Catalog contains reaper_scythe")

	var rand_w := WeaponData.get_random_weapon()
	_assert(rand_w != null and ids.has(rand_w.id), "get_random_weapon returns a valid catalog weapon")

func test_player_unarmed_initial_state(runner: SceneTree) -> void:
	var player_scene: PackedScene = load("res://scenes/entities/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	runner.root.add_child(player)

	_assert(player.weapon_unlocked == false, "Player starts unarmed (weapon_unlocked == false)")
	_assert(player.current_weapon == null, "Player current_weapon is null at start")
	_assert(player.slash_hitbox.damage_type == DamageData.DamageType.PHYSICAL, "Unarmed punch does PHYSICAL damage")
	_assert(player.slash_collision.polygon == Player.PUNCH_POLYGON, "Unarmed punch uses compact PUNCH_POLYGON")

	runner.root.remove_child(player)
	player.free()

func test_weapon_chest_interaction(runner: SceneTree) -> void:
	var chest_scene: PackedScene = load("res://scenes/env/weapon_chest.tscn")
	var chest: WeaponChest = chest_scene.instantiate() as WeaponChest
	runner.root.add_child(chest)

	var player_scene: PackedScene = load("res://scenes/entities/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	runner.root.add_child(player)

	# Verify initial chest state
	_assert(chest.is_opened == false, "Weapon chest starts unopened")

	# Test predetermined weapon granting
	var greatsword := WeaponData.create_greatsword()
	chest.predetermined_weapon = greatsword

	var weapon_signal_received: Array[WeaponData] = []
	chest.weapon_granted.connect(func(w: WeaponData): weapon_signal_received.append(w))

	var granted := chest.open_chest(player)
	_assert(granted != null and granted.id == "greatsword", "open_chest returns granted WeaponData (greatsword)")
	_assert(chest.is_opened == true, "Chest is_opened becomes true after open_chest")
	_assert(weapon_signal_received.size() == 1 and weapon_signal_received[0].id == "greatsword", "weapon_granted signal emitted with weapon")
	_assert(player.weapon_unlocked == true, "Player weapon_unlocked is true after chest opened")
	_assert(player.current_weapon != null and player.current_weapon.id == "greatsword", "Player has greatsword equipped")
	_assert(player.base_damage == 34.0, "Player base_damage updated to 34.0 from greatsword")
	_assert(player.attack_cooldown == 0.58, "Player attack_cooldown updated to 0.58 from greatsword")
	_assert(player.slash_collision.polygon == greatsword.hitbox_polygon, "Player slash_collision matches greatsword polygon")

	# Test one-time use duplicate open attempt
	var second_attempt := chest.open_chest(player)
	_assert(second_attempt == null, "Second open_chest attempt returns null and cannot be opened again")

	runner.root.remove_child(chest)
	runner.root.remove_child(player)
	chest.free()
	player.free()

func test_weapon_switching_and_stats(runner: SceneTree) -> void:
	var player_scene: PackedScene = load("res://scenes/entities/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	runner.root.add_child(player)

	# Equip Thunder Spear
	var spear := WeaponData.create_thunder_spear()
	player.equip_weapon(spear)
	_assert(player.current_weapon.id == "thunder_spear", "Player equipped thunder_spear")
	_assert(player.base_damage == 22.0, "Player damage updated for thunder_spear (22.0)")
	_assert(player.attack_cooldown == 0.38, "Player cooldown updated for thunder_spear (0.38)")
	_assert(player.slash_hitbox.damage_type == DamageData.DamageType.LIGHTNING, "Thunder spear deals LIGHTNING damage")
	_assert(player.slash_collision.polygon == spear.hitbox_polygon, "Thunder spear hitbox polygon applied")

	# Equip Reaper Scythe
	var scythe := WeaponData.create_reaper_scythe()
	player.equip_weapon(scythe)
	_assert(player.current_weapon.id == "reaper_scythe", "Player equipped reaper_scythe")
	_assert(player.base_damage == 18.0, "Player damage updated for reaper_scythe (18.0)")
	_assert(player.slash_hitbox.damage_type == DamageData.DamageType.DARK, "Reaper scythe deals DARK damage")
	_assert(player.slash_collision.polygon == scythe.hitbox_polygon, "Reaper scythe 360 sweep polygon applied")

	runner.root.remove_child(player)
	player.free()

func test_gacha_decoupling(runner: SceneTree) -> void:
	var player_scene: PackedScene = load("res://scenes/entities/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	runner.root.add_child(player)

	_assert(player.weapon_unlocked == false, "Player starts unarmed before gacha")

	var gm = runner.root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("apply_gacha_card"):
		# Apply common card: dmg_up
		gm.apply_gacha_card({"id": "dmg_up"}, player, null, runner)
		_assert(player.weapon_unlocked == false, "Gacha dmg_up card does NOT unlock weapon (decoupled)")
		_assert(player.damage_mult > 1.0, "Gacha dmg_up card correctly applies damage multiplier")

	runner.root.remove_child(player)
	player.free()

func test_arena_chest_placement(runner: SceneTree) -> void:
	var arena_scene: PackedScene = load("res://scenes/arena/arena.tscn")
	_assert(arena_scene != null, "arena.tscn loaded successfully")

	var arena: Node2D = arena_scene.instantiate() as Node2D
	runner.root.add_child(arena)

	var chest = arena.get_node_or_null("WeaponChest")
	_assert(chest != null, "Arena scene contains child node 'WeaponChest'")
	_assert(chest is WeaponChest, "Arena 'WeaponChest' is instance of WeaponChest class")
	if chest is WeaponChest:
		_assert(chest.is_opened == false, "Arena WeaponChest starts unopened")
		_assert(chest.position == Vector2(0, 50), "Arena WeaponChest placed at center clearing (0, 50)")

	runner.root.remove_child(arena)
	arena.free()
