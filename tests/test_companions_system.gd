extends Node

## Test suite for Companion System (Scenes, Spawning, Leadership, and Party HUD).

func run_all(runner: SceneTree) -> void:
	print("\n--- [COMPANION SYSTEM TESTS] ---")
	await test_companion_scenes_exist_and_instantiate(runner)
	await test_companion_groups_and_physics_layers(runner)
	await test_companion_stats_and_archetypes(runner)
	await test_companion_leadership_orders_reception(runner)
	await test_party_hud_companion_tracking(runner)
	await test_ruined_fortress_companion_spawning(runner)

func test_companion_scenes_exist_and_instantiate(runner: SceneTree) -> void:
	var scenes := [
		{"path": "res://scenes/entities/companion/companion_paladin.tscn", "type": "CompanionPaladin"},
		{"path": "res://scenes/entities/companion/companion_archer.tscn", "type": "CompanionArcher"},
		{"path": "res://scenes/entities/companion/companion_mage.tscn", "type": "CompanionMage"},
		{"path": "res://scenes/entities/companion/companion_rogue.tscn", "type": "CompanionRogue"}
	]

	for sc in scenes:
		var path: String = sc["path"]
		runner.assert_true(ResourceLoader.exists(path), "COMP.01: Scene exists at %s" % path)
		var packed := load(path) as PackedScene
		runner.assert_true(packed != null, "COMP.02: PackedScene valid for %s" % path)
		var instance = packed.instantiate()
		runner.assert_true(instance != null, "COMP.03: Instance instantiated for %s" % path)
		runner.assert_true(instance is CompanionBase, "COMP.04: Instance inherits CompanionBase (%s)" % path)

		var sprite = instance.get_node_or_null("Sprite2D")
		var health = instance.get_node_or_null("HealthComponent")
		var hurtbox = instance.get_node_or_null("HurtboxComponent")
		var collider = instance.get_node_or_null("CollisionShape2D")

		runner.assert_true(sprite != null, "COMP.05: Has Sprite2D (%s)" % path)
		runner.assert_true(health != null, "COMP.06: Has HealthComponent (%s)" % path)
		runner.assert_true(hurtbox != null, "COMP.07: Has HurtboxComponent (%s)" % path)
		runner.assert_true(collider != null, "COMP.08: Has CollisionShape2D (%s)" % path)
		instance.free()

func test_companion_groups_and_physics_layers(runner: SceneTree) -> void:
	var rogue_scene := load("res://scenes/entities/companion/companion_rogue.tscn") as PackedScene
	var rogue = rogue_scene.instantiate() as CompanionBase
	runner.root.add_child(rogue)

	runner.assert_true(rogue.is_in_group("companions"), "COMP.09: Joins 'companions' group")
	runner.assert_true(rogue.is_in_group("allies"), "COMP.10: Joins 'allies' group")
	runner.assert_eq(rogue.collision_layer, 64, "COMP.11: Collision layer is 64 (Layer 7 Companion)")
	runner.assert_eq(rogue.collision_mask, 1, "COMP.12: Collision mask is 1 (Layer 1 World)")

	var hurtbox := rogue.get_node_or_null("HurtboxComponent") as HurtboxComponent
	runner.assert_true(hurtbox != null, "COMP.13: HurtboxComponent exists")
	runner.assert_eq(hurtbox.collision_layer, 64, "COMP.14: Hurtbox layer is 64")
	runner.assert_eq(hurtbox.collision_mask, 16, "COMP.15: Hurtbox mask is 16 (EnemyAttacks)")

	runner.root.remove_child(rogue)
	rogue.free()

func test_companion_stats_and_archetypes(runner: SceneTree) -> void:
	var paladin_scene := load("res://scenes/entities/companion/companion_paladin.tscn") as PackedScene
	var paladin = paladin_scene.instantiate() as CompanionBase
	runner.assert_eq(paladin.max_health, 160.0, "COMP.16: Paladin max HP is 160.0")
	runner.assert_almost_eq(paladin.armor_reduction, 0.25, 0.01, "COMP.17: Paladin armor is 25%")
	paladin.free()

	var archer_scene := load("res://scenes/entities/companion/companion_archer.tscn") as PackedScene
	var archer = archer_scene.instantiate() as CompanionBase
	runner.assert_eq(archer.max_health, 75.0, "COMP.18: Archer max HP is 75.0")
	archer.free()

	var mage_scene := load("res://scenes/entities/companion/companion_mage.tscn") as PackedScene
	var mage = mage_scene.instantiate() as CompanionBase
	runner.assert_eq(mage.max_health, 80.0, "COMP.19: Mage max HP is 80.0")
	mage.free()

	var rogue_scene := load("res://scenes/entities/companion/companion_rogue.tscn") as PackedScene
	var rogue = rogue_scene.instantiate() as CompanionBase
	runner.assert_eq(rogue.max_health, 90.0, "COMP.20: Rogue max HP is 90.0")
	rogue.free()

func test_companion_leadership_orders_reception(runner: SceneTree) -> void:
	var mage_scene := load("res://scenes/entities/companion/companion_mage.tscn") as PackedScene
	var mage = mage_scene.instantiate() as CompanionBase
	runner.root.add_child(mage)

	# 1. Attack order
	mage._on_leadership_order_issued(1, Vector2(120, 80))
	runner.assert_eq(int(mage.current_tactical_state), int(CompanionBase.TacticalOrderState.ORDER_ATTACK),
		"COMP.21: Order 1 shifts companion state to ORDER_ATTACK")

	# 2. Retreat order
	mage._on_leadership_order_issued(2, Vector2.ZERO)
	runner.assert_eq(int(mage.current_tactical_state), int(CompanionBase.TacticalOrderState.ORDER_RETREAT),
		"COMP.22: Order 2 shifts companion state to ORDER_RETREAT")

	# 3. Help order
	mage._on_leadership_order_issued(3, Vector2(30, 40))
	runner.assert_eq(int(mage.current_tactical_state), int(CompanionBase.TacticalOrderState.ORDER_HELP),
		"COMP.23: Order 3 shifts companion state to ORDER_HELP")

	runner.root.remove_child(mage)
	mage.free()

func test_party_hud_companion_tracking(runner: SceneTree) -> void:
	var hud_scene := load("res://scenes/ui/hud/hud.tscn") as PackedScene
	var hud = hud_scene.instantiate() as GameHUD
	runner.root.add_child(hud)

	var paladin_scene := load("res://scenes/entities/companion/companion_paladin.tscn") as PackedScene
	var paladin = paladin_scene.instantiate() as CompanionBase
	paladin.companion_name = "Roland"
	runner.root.add_child(paladin)

	# Process HUD update
	hud._update_party_hud()
	runner.assert_true(hud.party_vbox != null and hud.party_vbox.visible, "COMP.24: PartyStatusContainer visible with active companion")
	runner.assert_eq(hud._companion_ui_entries.size(), 1, "COMP.25: One companion tracked in HUD")

	# Simulate damage on companion
	paladin.health_component.current_health = 100.0
	hud._update_party_hud()
	runner.assert_eq(hud._companion_ui_entries[0].bar.value, 100.0, "COMP.26: HUD reflects damaged companion HP")

	# Simulate downed companion
	paladin.health_component.is_downed = true
	hud._update_party_hud()
	runner.assert_true(hud._companion_ui_entries[0].status.text.contains("CAÍDO"), "COMP.27: HUD reflects downed companion status")

	runner.root.remove_child(paladin)
	paladin.free()

	# With 0 companions, HUD party box hides
	hud._update_party_hud()
	runner.assert_false(hud.party_vbox.visible, "COMP.28: PartyStatusContainer hidden when 0 companions exist")

	runner.root.remove_child(hud)
	hud.free()

func test_ruined_fortress_companion_spawning(runner: SceneTree) -> void:
	var FortressScript = load("res://scripts/dungeon/ruined_fortress.gd")
	var fortress = FortressScript.new()
	var GM = runner.root.get_node_or_null("GameManager")

	var dummy_roster: Array[Dictionary] = [
		{"id": "paladin_roland", "name": "Roland", "class_type": "paladin"},
		{"id": "rogue_silas", "name": "Silas", "class_type": "rogue"}
	]

	if GM != null and GM.has_method("set_active_party_roster"):
		GM.set_active_party_roster(dummy_roster)

	runner.root.add_child(fortress)

	var spawned_allies: Array = []
	for child in fortress.get_children():
		if child is CompanionBase:
			spawned_allies.append(child)

	runner.assert_eq(spawned_allies.size(), 2, "COMP.29: Ruined Fortress spawns exactly 2 companions from roster")
	if spawned_allies.size() >= 2:
		runner.assert_true(spawned_allies[0] is CompanionPaladin, "COMP.30: First companion is Paladin")
		runner.assert_true(spawned_allies[1] is CompanionRogue, "COMP.31: Second companion is Rogue")

	if GM != null and GM.has_method("set_active_party_roster"):
		GM.active_party_roster.clear()

	for a in spawned_allies:
		fortress.remove_child(a)
		a.free()

	runner.root.remove_child(fortress)
	fortress.free()
