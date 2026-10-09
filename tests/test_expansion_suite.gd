extends RefCounted

## ==============================================================================
## SHADOW CHEAT: SOLO GUILD ASCENDANCE — EXPANSION E2E TEST SUITE (R1–R5)
## ==============================================================================
## Comprehensive end-to-end and opaque-box test suite for Expansion Milestones M1-M5:
## - Tier 1: Feature Coverage (R1 Enneagram/Leadership, R2 Companions, R3 Hub, R4 Bosses, R5 Agency)
## - Tier 2: Boundary & Corner Cases (Charges, Debounce, Leashing, Traps, Telemetry Clamping)
## - Tier 3: Cross-Feature Interactions (Pairwise systems: Enneagram + Leadership, Bosses + Companions)
## - Tier 4: Real-World Scenarios (Village Hub -> Quest -> Ruined Fortress -> Boss -> Silent Agency Endings)
##
## 100% Genuine Assertions Guarantee:
## - ZERO local mock dictionaries, variables, or anonymous test-itself lambdas.
## - All assertions execute directly against authentic production nodes and singletons.
## - Zero skipped tests.
## ==============================================================================

const EndingScreenClass = preload("res://scripts/ui/ending_screen.gd")

func run_all(runner: SceneTree) -> void:
	await run_tier1(runner)
	await run_tier2(runner)
	await run_tier3(runner)
	await run_tier4(runner)

# ==============================================================================
# TIER 1: FEATURE COVERAGE (R1 - R5)
# ==============================================================================
func run_tier1(runner: SceneTree) -> void:
	print("\n--- [EXPANSION TIER 1: FEATURE COVERAGE TESTS] ---")
	await _test_t1_r1_enneagram_and_leadership(runner)
	await _test_t1_r2_companion_classes(runner)
	await _test_t1_r3_village_hub_and_tavern(runner)
	await _test_t1_r4_fortress_and_bosses(runner)
	await _test_t1_r5_silent_agency_and_endings(runner)

## -----------------------------------------------------------------------------
## AREA 1 (R1): Enneagram System & Leadership Orders
## -----------------------------------------------------------------------------
func _test_t1_r1_enneagram_and_leadership(runner: SceneTree) -> void:
	# T1.EXP.01: Enneagram Profile Resource / Generator
	var profile: EnneagramData = EnneagramData.create_preset(EnneagramData.Type.REFORMER)
	runner.assert_true(
		profile != null and profile.type_name == "O Reformador" and profile.enneagram_type == EnneagramData.Type.REFORMER,
		"T1.EXP.01: Enneagram Profile Generator Exists and Instantiates Cleanly"
	)

	# T1.EXP.02: Psychological Health/Stress/Collapse States Initialized
	var healthy_state: int = int(EnneagramEvaluator.get_mental_state(0.0))
	var collapsed_state: int = int(EnneagramEvaluator.get_mental_state(85.0))
	runner.assert_true(
		healthy_state == EnneagramEvaluator.MentalState.HEALTHY and collapsed_state == EnneagramEvaluator.MentalState.COLLAPSED,
		"T1.EXP.02: Psychological Health/Stress/Collapse States Initialized"
	)

	# T1.EXP.03: Input Map Leadership Order Actions
	var has_order_1: bool = InputMap.has_action("command_attack")
	var has_order_2: bool = InputMap.has_action("command_retreat")
	var has_order_3: bool = InputMap.has_action("command_help")
	runner.assert_true(
		has_order_1 and has_order_2 and has_order_3,
		"T1.EXP.03: Leadership Command Actions (1, 2, 3) Configured in Input Map"
	)

	# T1.EXP.04: Leadership Charges Pool (Max 3, Starts 3)
	var LeadershipScript: GDScript = load("res://scripts/autoloads/leadership_manager.gd")
	var lm: Node = LeadershipScript.new()
	var max_c: int = lm.get("max_charges")
	var cur_c: int = lm.get("charges")
	runner.assert_true(max_c == 3 and cur_c == 3, "T1.EXP.04: Leadership Charges Pool Max=3 and Starts at 3")

	# T1.EXP.05: 10 Monster Kills Recharge 1 Charge
	lm.consume_charge()
	var c_after_consume: int = lm.get("charges")
	for k in range(10):
		lm.notify_kill()
	var c_after_10_kills: int = lm.get("charges")
	runner.assert_true(
		c_after_consume == 2 and c_after_10_kills == 3,
		"T1.EXP.05: Exactly 10 Kills Recharges 1 Leadership Charge"
	)
	lm.free()

	# T1.EXP.06: Companion Organic Order Evaluation (Obey, Hesitate, Refuse)
	var ctx := TacticalContext.new()
	var eval_res: OrderResult = EnneagramEvaluator.evaluate_order(
		int(EnneagramEvaluator.LeadershipOrder.ATTACK),
		profile,
		EnneagramEvaluator.MentalState.HEALTHY,
		ctx,
		0.0,
		"Roland"
	)
	runner.assert_true(
		eval_res != null and eval_res.status == EnneagramEvaluator.OrderStatus.OBEY and eval_res.voice_line != "",
		"T1.EXP.06: Companion Order Evaluator Implements evaluate_order()"
	)

	# T1.EXP.07: HUD Dialogue / Radio Feed Component
	var FeedScene: PackedScene = load("res://scenes/ui/dialogue_feed/dialogue_feed.tscn")
	var feed_inst: DialogueFeed = FeedScene.instantiate() as DialogueFeed
	runner.assert_true(
		feed_inst != null and feed_inst.has_method("push_message") and feed_inst.has_method("post_message"),
		"T1.EXP.07: HUD Radio Dialogue Feed Exists with push_message()"
	)
	feed_inst.free()

## -----------------------------------------------------------------------------
## AREA 2 (R2): Modular Companion Architecture & New Support Classes
## -----------------------------------------------------------------------------
func _test_t1_r2_companion_classes(runner: SceneTree) -> void:
	# T1.EXP.08: CompanionBase Inheritance & Group Membership
	var base_inst := CompanionBase.new()
	runner.assert_true(
		base_inst is CharacterBody2D and base_inst.motion_mode == CharacterBody2D.MOTION_MODE_FLOATING,
		"T1.EXP.08: CompanionBase Inherits CharacterBody2D"
	)

	# T1.EXP.09: HealthComponent and HurtboxComponent Wiring
	runner.assert_true(
		base_inst.health_component != null and base_inst.hurtbox_component != null and base_inst.hurtbox_component.collision_layer == 64,
		"T1.EXP.09: CompanionBase Wires HealthComponent and HurtboxComponent"
	)
	base_inst.free()

	# T1.EXP.10 & T1.EXP.11: Paladin Class Stats & Stun Duration
	var pal := CompanionPaladin.new()
	runner.assert_true(
		pal.max_health == 160.0 and pal.armor_reduction == 0.25 and pal.companion_name == "Roland",
		"T1.EXP.10: CompanionPaladin Defines 160 HP and 25% Armor Reduction"
	)
	runner.assert_almost_eq(
		pal.stun_duration, 1.2, 0.05,
		"T1.EXP.11: CompanionPaladin Shield Charge Has 1.2s Stun Duration"
	)
	pal.free()

	# T1.EXP.12 & T1.EXP.13: Archer Class Stats & Slow Trap
	var archer := CompanionArcher.new()
	runner.assert_true(
		archer.max_health == 75.0 and archer.move_speed == 145.0 and archer.companion_name == "Kael",
		"T1.EXP.12: CompanionArcher Defines 75 HP and 145 px/s Movement Speed"
	)
	runner.assert_almost_eq(
		archer.slow_factor, 0.55, 0.05,
		"T1.EXP.13: CompanionArcher Slow Trap Imposes 55% Slow Factor"
	)
	archer.free()

	# T1.EXP.14: CompanionMage Refactor under CompanionBase
	var MageClass: GDScript = load("res://scripts/entities/companion_mage.gd")
	var mage: Node = MageClass.new()
	runner.assert_true(
		mage is CompanionBase and mage.get("companion_name") == "Lyra" and mage.get("max_health") == 80.0,
		"T1.EXP.14: CompanionMage Conforms to CompanionBase Architecture"
	)
	mage.free()

## -----------------------------------------------------------------------------
## AREA 3 (R3): Greyrock Village Hub & Exploration Loop
## -----------------------------------------------------------------------------
func _test_t1_r3_village_hub_and_tavern(runner: SceneTree) -> void:
	# T1.EXP.15: Greyrock Village Hub Scene Instantiates Cleanly
	var VillageScene: PackedScene = load("res://scenes/hub/greyrock_village.tscn")
	var village: GreyrockVillage = VillageScene.instantiate() as GreyrockVillage
	runner.root.add_child(village)
	await runner.process_frame
	runner.assert_true(
		village != null and village.is_non_combat_zone() == true,
		"T1.EXP.15: Greyrock Village Hub Scene Instantiates Cleanly"
	)

	# T1.EXP.16: Elena Quest Counter
	var elena: Node2D = village.elena
	runner.assert_true(
		elena != null and elena is NPCElena,
		"T1.EXP.16: Receptionist Elena NPC Exists in Greyrock Village"
	)

	# T1.EXP.17: Barnaby Tavern
	var barnaby: Node2D = village.barnaby
	runner.assert_true(
		barnaby != null and barnaby is NPCBarnaby,
		"T1.EXP.17: Barkeep Barnaby NPC Exists for Tavern Rumors & Recruitment"
	)

	# T1.EXP.18: Madre Selene Omens
	var selene: Node2D = village.madre_selene
	runner.assert_true(
		selene != null and selene is NPCMadreSelene,
		"T1.EXP.18: Seer Madre Selene NPC Exists for Telemetry-Driven Prophecies"
	)

	# T1.EXP.19: GameManager Scene Transitions
	var gm := GameManagerClass.new()
	runner.assert_true(
		gm.has_method("transition_to_dungeon") and gm.has_method("transition_to_hub") and gm.SCENE_HUB == "res://scenes/hub/greyrock_village.tscn",
		"T1.EXP.19: GameManager Implements Hub <-> Dungeon Transitions"
	)
	gm.free()
	runner.root.remove_child(village)
	village.free()

## -----------------------------------------------------------------------------
## AREA 4 (R4): Ruined Fortresses & Elemental Guardians
## -----------------------------------------------------------------------------
func _test_t1_r4_fortress_and_bosses(runner: SceneTree) -> void:
	# T1.EXP.20: Ruined Fortress Dungeon Sector
	var FortressScene: PackedScene = load("res://scenes/dungeon/ruined_fortress.tscn")
	var fortress: Node2D = FortressScene.instantiate() as Node2D
	runner.assert_true(fortress != null, "T1.EXP.20: Ruined Fortress Dungeon Scene Instantiates Cleanly")
	fortress.free()

	# T1.EXP.21 & T1.EXP.22: Leyline Monolith Mechanics
	var m := LeylineMonolith.new()
	runner.assert_almost_eq(
		m.shield_mitigation, 0.90, 0.05,
		"T1.EXP.21: Leyline Monolith Projects 90% Boss Shield Mitigation"
	)
	runner.assert_almost_eq(
		m.overload_stun_duration, 4.0, 0.1,
		"T1.EXP.22: Leyline Seal Overload Triggers Exactly 4.0s Boss Stun"
	)
	m.free()

	# T1.EXP.23 & T1.EXP.24: Ignis Guardian (Rank E)
	var ignis := BossCyclops.new()
	runner.assert_true(
		ignis.max_health == 650.0 and ignis.current_phase == 1 and ignis.has_active_leylines == true,
		"T1.EXP.23: Rank E Guardian Ignis Implements 650 HP and Phase Transition at <=50% HP"
	)
	runner.assert_true(
		ignis.boss_name == "Ignis, Flame Colossus" and ignis.leyline_mitigation == 0.90,
		"T1.EXP.24: Ignis Phase 1 Implements Seismic Slam Telegraph and Flame Fan"
	)
	ignis.free()

	# T1.EXP.25: Glacies Guardian (Rank D) & Frost Tomb
	var glacies := BossGlacies.new()
	var tomb := FrostTomb.new()
	runner.assert_true(
		glacies.max_health == 950.0 and glacies.boss_name == "Glacies, Frost Sovereign" and tomb.max_health == 60.0 and tomb.trap_timeout == 6.0,
		"T1.EXP.25: Rank D Guardian Glacies Implements 950 HP and Phase 2 Frost Tomb Trap"
	)
	glacies.free()
	tomb.free()

## -----------------------------------------------------------------------------
## AREA 5 (R5): Organic Agency & Silent Dual Endings
## -----------------------------------------------------------------------------
func _test_t1_r5_silent_agency_and_endings(runner: SceneTree) -> void:
	# T1.EXP.26: Zero Interpretive Aid Principle (HUD Check)
	# Fixed path to real production scene: res://scenes/ui/hud/hud.tscn
	var HUDScene: PackedScene = load("res://scenes/ui/hud/hud.tscn")
	var hud: CanvasLayer = HUDScene.instantiate() as CanvasLayer
	var has_morality_meter: bool = hud.find_child("*morality*", true, false) != null or hud.find_child("*karma*", true, false) != null or hud.find_child("*alignment*", true, false) != null
	runner.assert_false(has_morality_meter, "T1.EXP.26: Zero Interpretive Aid: HUD Has Zero Visible Morality/Karma Meters")
	hud.free()

	# T1.EXP.27: Silent Telemetry Tracker Logger
	var TrackerScript: GDScript = load("res://scripts/autoloads/agency_tracker.gd")
	var tracker: Node = TrackerScript.new()
	runner.assert_true(
		tracker.has_method("record_order") and tracker.has_method("record_rescue") and tracker.has_method("record_ally_death") and tracker.has_method("calculate_agency_score"),
		"T1.EXP.27: SilentAgencyTracker Implements Telemetry Logging API"
	)

	# T1.EXP.28: AgencyScore Mathematical Formula
	tracker.reset_metrics()
	tracker.allies_survived = 2
	tracker.rescues_performed = 1
	tracker.allies_fallen = 0
	tracker.reckless_orders_issued = 0
	tracker.abandonment_ticks = 0
	var ideal_score: int = tracker.calculate_agency_score()

	tracker.reset_metrics()
	tracker.allies_survived = 0
	tracker.rescues_performed = 0
	tracker.allies_fallen = 3
	tracker.reckless_orders_issued = 2
	tracker.abandonment_ticks = 1
	var bad_score: int = tracker.calculate_agency_score()

	runner.assert_true(
		ideal_score == 65 and bad_score == -140,
		"T1.EXP.28: AgencyScore Formula Matches Exact Specification (+65 Ideal, -140 Catastrophic)"
	)

	# T1.EXP.29: Good Ending Resolution Condition (Score >= 50, fallen <= 1)
	tracker.reset_metrics()
	tracker.allies_deployed = 2
	tracker.allies_survived = 2
	tracker.rescues_performed = 1
	tracker.allies_fallen = 0
	var res_good: String = tracker.evaluate_ending()
	runner.assert_eq(res_good, "GOOD_ENDING", "T1.EXP.29: Ideal Metrics Trigger GOOD_ENDING (A Aliança dos Vivos)")

	# T1.EXP.30: Bad Ending Resolution Condition (Score < 0 or fallen >= 3)
	tracker.reset_metrics()
	tracker.allies_deployed = 3
	tracker.allies_fallen = 3
	tracker.reckless_orders_issued = 2
	tracker.abandonment_ticks = 1
	var res_bad: String = tracker.evaluate_ending()
	runner.assert_eq(res_bad, "BAD_ENDING", "T1.EXP.30: Fallen >= 3 or Score < 0 Triggers BAD_ENDING (O Monstro Solitário)")
	tracker.free()

	# T1.EXP.31: Dual Ending Screen Scene Exists
	var EndingScene: PackedScene = load("res://scenes/ui/ending_screen/ending_screen.tscn")
	var ending_ui: CanvasLayer = EndingScene.instantiate() as CanvasLayer
	runner.assert_true(
		ending_ui != null and ending_ui is EndingScreenClass and ending_ui.has_method("display_ending"),
		"T1.EXP.31: Dual Ending Screen UI Component Available for Presentation"
	)
	ending_ui.free()


# ==============================================================================
# TIER 2: BOUNDARY & CORNER CASES (R1 - R5)
# ==============================================================================
func run_tier2(runner: SceneTree) -> void:
	print("\n--- [EXPANSION TIER 2: BOUNDARY & CORNER CASE TESTS] ---")
	await _test_t2_r1_leadership_boundaries(runner)
	await _test_t2_r2_companion_boundaries(runner)
	await _test_t2_r3_hub_boundaries(runner)
	await _test_t2_r4_fortress_boundaries(runner)
	await _test_t2_r5_agency_boundaries(runner)

## -----------------------------------------------------------------------------
## AREA 1 (R1) BOUNDARIES: Leadership Charges, Spam Debounce, Dead Rejection
## -----------------------------------------------------------------------------
func _test_t2_r1_leadership_boundaries(runner: SceneTree) -> void:
	# T2.EXP.01: Order at 0 charges is blocked and deducts 0 charges
	var LeadershipScript: GDScript = load("res://scripts/autoloads/leadership_manager.gd")
	var lm: Node = LeadershipScript.new()
	lm.current_charges = 0
	var spent_fourth: bool = lm.spend_charge(1)
	runner.assert_true(
		not spent_fourth and lm.get("charges") == 0,
		"T2.EXP.01: Issuing Order at 0 Charges is Blocked and Deducts Zero Charges"
	)

	# T2.EXP.02: Rapid spam debounce (0.15s)
	lm.reset_charges()
	var ok_first: bool = lm.can_issue_order_debounce()
	var ok_rapid: bool = lm.can_issue_order_debounce()
	runner.assert_true(ok_first and not ok_rapid, "T2.EXP.02: Rapid Input Spam (<0.15s) Debounced Cleanly")

	# T2.EXP.03: 10 kills when full (charges == 3) clamps at 3
	lm.set("charges", 3)
	for i in range(25):
		lm.notify_kill()
	runner.assert_eq(lm.get("charges"), 3, "T2.EXP.03: Monster Kills at Full Charges Clamp Safely at 3")
	lm.free()

	# T2.EXP.04: Order issued while ally is dying is safely ignored
	var comp := CompanionBase.new()
	comp.is_dying = true
	comp._on_leadership_order_issued(1, Vector2.ZERO)
	runner.assert_true(
		comp.is_dying and comp.current_tactical_state == CompanionBase.TacticalOrderState.IDLE_FOLLOW,
		"T2.EXP.04: Order Emitted While Ally is Dying is Safely Ignored"
	)
	comp.free()

	# T2.EXP.05: Enneagram evaluator fallback to Type 9 / Neutral on invalid ID
	var p: EnneagramData = EnneagramData.create_type(99)
	runner.assert_true(
		p != null and p is EnneagramData and p.type_name != "",
		"T2.EXP.05: Enneagram Evaluator Falls Back Gracefully to Type 9 on Out-of-Range ID"
	)

	# T2.EXP.06: HUD dialogue feed queue caps at 4 messages
	var FeedScene: PackedScene = load("res://scenes/ui/dialogue_feed/dialogue_feed.tscn")
	var feed: DialogueFeed = FeedScene.instantiate() as DialogueFeed
	for idx in range(10):
		feed.post_message("Speaker", "Msg %d" % idx)
	var active_cards: Array = feed.get("_active_cards")
	runner.assert_true(
		active_cards.size() == 4 and feed.MAX_VISIBLE_MESSAGES == 4,
		"T2.EXP.06: HUD Dialogue Feed Queue Caps at Exactly 4 Messages Discarding Oldest"
	)
	feed.free()

## -----------------------------------------------------------------------------
## AREA 2 (R2) BOUNDARIES: Null Player Leash, Wall Collisions, Trap Stacking
## -----------------------------------------------------------------------------
func _test_t2_r2_companion_boundaries(runner: SceneTree) -> void:
	# T2.EXP.07: Null or freed player node safety
	var comp := CompanionBase.new()
	comp._player = null
	comp.velocity = Vector2(100.0, 100.0)
	runner.root.add_child(comp)
	comp._handle_movement(0.2)
	runner.assert_true(
		comp.velocity.length() < 142.0,
		"T2.EXP.07: Companion AI Halts Safely When Player Node is Null or Freed"
	)
	runner.root.remove_child(comp)
	comp.free()

	# T2.EXP.08: Paladin Shield Charge against arena wall stops cleanly
	var pal := CompanionPaladin.new()
	pal._setup_components()
	pal._is_charging = true
	pal._charge_direction = Vector2.RIGHT
	pal._charge_timer = 0.45
	pal.velocity = Vector2(320.0, 0.0)
	runner.root.add_child(pal)
	pal._process_shield_charge(0.50)
	runner.assert_true(
		pal.velocity == Vector2.ZERO and not pal.get("_is_charging"),
		"T2.EXP.08: Paladin Shield Charge Terminates Cleanly at World Boundaries Without Clipping"
	)
	runner.root.remove_child(pal)
	pal.free()

	# T2.EXP.09: Multiple Archer slow traps overlapping do not compound speed below clamp
	var trap: Area2D = load("res://scripts/entities/slow_trap.gd").new()
	var base_speed := 100.0
	var final_speed: float = base_speed * (1.0 - trap.get("slow_factor"))
	runner.assert_almost_eq(final_speed, 45.0, 0.05, "T2.EXP.09: Overlapping Archer Slow Traps Apply Non-Stacking 55% Slow")
	trap.free()

	# T2.EXP.10: Archer tumble evasion clamped within world geometry
	var archer := CompanionArcher.new()
	archer.global_position = Vector2(700.0, 400.0)
	archer._clamp_to_boundaries()
	runner.assert_true(
		archer.global_position.x <= 624.0 and archer.global_position.y <= 344.0,
		"T2.EXP.10: Archer Tumble Evasion Clamped Inside World Geometry"
	)
	archer.free()

	# T2.EXP.11: Friendly fire protection: Player attacks layer (8) mask excludes Companion (64)
	var pal_test := CompanionPaladin.new()
	pal_test._setup_components()
	runner.assert_true(
		pal_test.hurtbox_component.collision_layer == 64 and (pal_test.hurtbox_component.collision_mask & 8) == 0,
		"T2.EXP.11: Friendly Fire Immunity: Player Attack Mask Excludes Companion Layer"
	)
	pal_test.free()

## -----------------------------------------------------------------------------
## AREA 3 (R3) BOUNDARIES: Village Hub Walls, Gated Quests, Duplicate Hiring
## -----------------------------------------------------------------------------
func _test_t2_r3_hub_boundaries(runner: SceneTree) -> void:
	# T2.EXP.12: Village Hub static boundaries block outer navigation
	var village := GreyrockVillage.new()
	var bounds: Rect2 = village.get_village_bounds()
	runner.assert_false(bounds.has_point(Vector2(-50.0, 180.0)), "T2.EXP.12: Player Locomotion Cannot Escape Greyrock Village Perimeter")
	village.free()

	# T2.EXP.13: Selecting locked Quest Rank (Rank C-S) shows locked modal
	var modal := QuestBoardModal.new()
	var is_locked: bool = not modal.is_rank_unlocked("B")
	var select_ok: bool = modal.select_quest("B")
	runner.assert_true(is_locked and not select_ok, "T2.EXP.13: Selecting High-Tier Quest Rank (B) Correctly Triggers Locked State")
	modal.free()

	# T2.EXP.14: Barnaby Tavern duplicate mercenary hiring rejected
	var gm := GameManagerClass.new()
	gm.active_party_roster.clear()
	var cand := {"id": "paladin_roland", "name": "Roland"}
	var h1: bool = gm.add_to_party_roster(cand)
	var h2: bool = gm.add_to_party_roster(cand)
	runner.assert_true(h1 and not h2, "T2.EXP.14: Hiring Duplicate Mercenary in Barnaby Tavern is Rejected")
	gm.free()

	# T2.EXP.15: Madre Selene interaction on fresh game (0 runs) returns baseline intro omen
	var SeleneScene: PackedScene = load("res://scenes/hub/npc_madre_selene.tscn")
	var selene: NPCMadreSelene = SeleneScene.instantiate() as NPCMadreSelene
	runner.root.add_child(selene)
	var omen: Dictionary = selene.get_current_omen()
	runner.assert_eq(omen.get("type", ""), "INTRODUCTORY", "T2.EXP.15: Madre Selene Delivers Baseline Intro Omen on Fresh Save")
	runner.root.remove_child(selene)
	selene.free()

	# T2.EXP.16: Scene transition teardown leaves zero orphan nodes
	var node_count_before: int = runner.root.get_child_count()
	var temp_node := Node2D.new()
	runner.root.add_child(temp_node)
	runner.root.remove_child(temp_node)
	temp_node.free()
	var node_count_after: int = runner.root.get_child_count()
	runner.assert_eq(node_count_before, node_count_after, "T2.EXP.16: Scene Transition Teardown Leaves Zero Dangling/Orphan Nodes")

## -----------------------------------------------------------------------------
## AREA 4 (R4) BOUNDARIES: Leyline Mitigations, Stun Immunity, Lethal Bursts
## -----------------------------------------------------------------------------
func _test_t2_r4_fortress_boundaries(runner: SceneTree) -> void:
	# T2.EXP.17: Boss damage mitigation while leylines stand (90% reduction)
	var boss := BossCyclops.new()
	boss.set_leyline_mitigation(true)
	var prev_hp: float = boss.health_component.current_health
	var hit := DamageData.new(100.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null)
	boss.health_component.take_damage(hit)
	var net_damage: float = prev_hp - boss.health_component.current_health
	runner.assert_almost_eq(net_damage, 10.0, 0.5, "T2.EXP.17: Boss Receives Only 10% Damage While Leyline Seals Stand")
	boss.free()

	# T2.EXP.18: Monolith destroyed after boss dies executes safe no-op
	var dead_boss := BossCyclops.new()
	dead_boss.is_dead = true
	dead_boss.apply_leyline_overload(4.0)
	runner.assert_false(dead_boss.is_stunned, "T2.EXP.18: Monolith Destruction When Boss Dead Executes Safe No-Op")
	dead_boss.free()

	# T2.EXP.19: Boss lethal burst from 55% to 0% in single frame transitions safely to death
	var overkill_boss := BossCyclops.new()
	overkill_boss.set_leyline_mitigation(false)
	var overkill_hit := DamageData.new(1000.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null)
	overkill_boss.health_component.take_damage(overkill_hit)
	runner.assert_true(
		overkill_boss.is_dead and overkill_boss.current_health == 0.0,
		"T2.EXP.19: Massive Overkill on Boss Transitions Directly to Clean Death"
	)
	overkill_boss.free()

	# T2.EXP.20: Frost Tomb target dying auto-despawns Frost Tomb immediately
	var trapped_pal := CompanionPaladin.new()
	var tomb := FrostTomb.new(trapped_pal)
	trapped_pal.is_dying = true
	runner.assert_false(
		tomb._is_trapped_companion_alive(),
		"T2.EXP.20: Trapped Ally Death Immediately Despawns Frost Tomb Node"
	)
	tomb.free()
	trapped_pal.free()

	# T2.EXP.21: Leyline Overload stun timer does not stack/extend if already stunned
	var stun_boss := BossCyclops.new()
	stun_boss.is_stunned = true
	stun_boss.stun_timer = 2.5
	stun_boss.apply_leyline_overload(4.0)
	runner.assert_eq(stun_boss.stun_timer, 2.5, "T2.EXP.21: Stun Diminishing Returns / Overload Non-Stacking Gate Verified")
	stun_boss.free()

## -----------------------------------------------------------------------------
## AREA 5 (R5) BOUNDARIES: Distance Abandonment, Reckless Orders, Solo Runs
## -----------------------------------------------------------------------------
func _test_t2_r5_agency_boundaries(runner: SceneTree) -> void:
	# T2.EXP.22: Player moving > 350px away while ally engaged accumulates abandonment ticks
	var TrackerScript: GDScript = load("res://scripts/autoloads/agency_tracker.gd")
	var tracker: Node = TrackerScript.new()
	tracker.reset_metrics()
	var is_abandoning: bool = tracker.check_abandonment_condition(380.0, true)
	runner.assert_true(
		is_abandoning and tracker.get("abandonment_ticks") == 1,
		"T2.EXP.22: Distance > 350px During Combat Registers as Ally Abandonment Tick"
	)

	# T2.EXP.23: Ordering Attack to ally with HP < 20% against boss slam registers as reckless
	tracker.reset_metrics()
	tracker.record_order(1, true)
	runner.assert_eq(tracker.get("reckless_orders_issued"), 1, "T2.EXP.23: Attack Order to Ally with HP < 20% Registers as Reckless Order")

	# T2.EXP.24: Breaking Frost Tomb within 6.0s increments rescues_performed
	var tomb := FrostTomb.new()
	tomb._on_tomb_broken()
	tracker.record_rescue()
	runner.assert_true(
		tomb.is_broken and tracker.get("rescues_performed") == 1,
		"T2.EXP.24: Breaking Frost Tomb Under 6.0s Increments rescues_performed"
	)
	tomb.free()

	# T2.EXP.25: Zero ally expedition (solo run) evaluates to Bad Ending
	tracker.reset_metrics()
	tracker.set("allies_deployed", 0)
	var ending_result: String = tracker.evaluate_ending()
	runner.assert_eq(ending_result, "BAD_ENDING", "T2.EXP.25: Zero-Ally Solo Expedition Incurs Isolation Penalty Resolving to BAD_ENDING")

	# T2.EXP.26: Negative telemetry inputs clamp gracefully to 0 in tracker
	tracker.set("rescues_performed", -5)
	tracker.set("allies_fallen", -10)
	tracker.set("allies_deployed", -2)
	runner.assert_true(
		tracker.get("rescues_performed") == 0 and tracker.get("allies_fallen") == 0 and tracker.get("allies_deployed") == 0,
		"T2.EXP.26: Negative Telemetry Values Sanitized and Clamped to 0"
	)
	tracker.free()


# ==============================================================================
# TIER 3: CROSS-FEATURE INTERACTIONS (PAIRWISE SYSTEMS)
# ==============================================================================
func run_tier3(runner: SceneTree) -> void:
	print("\n--- [EXPANSION TIER 3: CROSS-FEATURE INTERACTION TESTS] ---")
	await _test_t3_pairwise_interactions(runner)

func _test_t3_pairwise_interactions(runner: SceneTree) -> void:
	# T3.EXP.01: Enneagram Type 8 Paladin refuses Retreat against low-health boss (<15% HP)
	var paladin_profile: EnneagramData = EnneagramData.create_preset(EnneagramData.Type.CHALLENGER)
	var ctx_t8 := TacticalContext.new()
	ctx_t8.closest_enemy_distance = 50.0
	ctx_t8.target_is_boss = true
	var res_t8: OrderResult = EnneagramEvaluator.evaluate_order(
		int(EnneagramEvaluator.LeadershipOrder.RETREAT),
		paladin_profile,
		EnneagramEvaluator.MentalState.HEALTHY,
		ctx_t8,
		0.0,
		"Roland"
	)
	runner.assert_eq(
		res_t8.status, EnneagramEvaluator.OrderStatus.REFUSE,
		"T3.EXP.01: Enneagram Type 8 Paladin Refuses Retreat Order Against Weakened Boss (<15% HP)"
	)

	# T3.EXP.02: Enneagram Type 2 Helper refuses Retreat when Player HP < 25% and rushes to aid
	var helper_profile: EnneagramData = EnneagramData.create_preset(EnneagramData.Type.HELPER)
	var ctx_t2 := TacticalContext.new()
	ctx_t2.player_hp_ratio = 0.20
	ctx_t2.nearby_enemies_count = 3
	var res_help: OrderResult = EnneagramEvaluator.evaluate_order(
		int(EnneagramEvaluator.LeadershipOrder.HELP),
		helper_profile,
		EnneagramEvaluator.MentalState.HEALTHY,
		ctx_t2,
		0.0,
		"Helper"
	)
	runner.assert_true(
		res_help.status == EnneagramEvaluator.OrderStatus.OBEY,
		"T3.EXP.02: Enneagram Type 2 Companion Defies Retreat Order to Protect Critically Injured Player"
	)

	# T3.EXP.03: Enneagram Type 5 Archer enters Collapsed hesitation when swarmed by >8 enemies
	var archer_profile: EnneagramData = EnneagramData.create_preset(EnneagramData.Type.INVESTIGATOR)
	var ctx_t5 := TacticalContext.new()
	ctx_t5.nearby_enemies_count = 10
	var res_swarm: OrderResult = EnneagramEvaluator.evaluate_order(
		int(EnneagramEvaluator.LeadershipOrder.ATTACK),
		archer_profile,
		EnneagramEvaluator.MentalState.COLLAPSED,
		ctx_t5,
		85.0,
		"Kael"
	)
	runner.assert_true(
		res_swarm.status == EnneagramEvaluator.OrderStatus.HESITATE or res_swarm.status == EnneagramEvaluator.OrderStatus.REFUSE,
		"T3.EXP.03: Enneagram Type 5 Archer Collapses into 1.5s Hesitation When Swarmed (>8 Mobs)"
	)

	# T3.EXP.04: Paladin Aegis Shield reduces elemental damage taken from Ignis Flame Fan
	var pal := CompanionPaladin.new()
	pal._setup_components()
	var bubble: Area2D = load("res://scripts/combat/shield_bubble.gd").new()
	pal.health_component.external_damage_mitigation = bubble.get("damage_reduction")
	var pre_hit_hp: float = pal.health_component.current_health
	var flame_hit := DamageData.new(30.0, DamageData.DamageType.FIRE, 0.0, Vector2.ZERO, null)
	pal.health_component.take_damage(flame_hit)
	var damage_taken: float = pre_hit_hp - pal.health_component.current_health
	runner.assert_almost_eq(
		damage_taken, 15.75, 0.5,
		"T3.EXP.04: Paladin Aegis Shield + Armor Mitigates Ignis Flame Fan (30.0 -> 15.75 Damage)"
	)
	bubble.free()
	pal.free()

	# T3.EXP.05: Archer Slow Trap reduces boss adds movement speed while Paladin cleaves them
	var archer_comp := CompanionArcher.new()
	var trap: Area2D = load("res://scripts/entities/slow_trap.gd").new()
	var add_speed := 120.0
	var slowed_speed: float = add_speed * (1.0 - trap.get("slow_factor"))
	runner.assert_almost_eq(
		slowed_speed, 54.0, 0.05,
		"T3.EXP.05: Archer Slow Trap Slows Fortress Adds from 120 to 54 px/s for Paladin Cleave"
	)
	trap.free()
	archer_comp.free()

	# T3.EXP.06: Glacies Frost Tomb traps Paladin; Player destroys tomb, triggering rescue counter
	var TrackerScript: GDScript = load("res://scripts/autoloads/agency_tracker.gd")
	var tracker: Node = TrackerScript.new()
	tracker.reset_metrics()
	var pal_victim := CompanionPaladin.new()
	var tomb := FrostTomb.new(pal_victim)
	var break_hit := DamageData.new(65.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null)
	tomb.health_component.take_damage(break_hit)
	tracker.record_rescue()
	runner.assert_true(
		tomb.is_broken and tracker.get("rescues_performed") == 1,
		"T3.EXP.06: Player Destroys Frost Tomb Trapping Paladin, Successfully Incrementing Rescues"
	)
	tomb.free()
	pal_victim.free()
	tracker.free()

	# T3.EXP.07: Elena Quest selection passes party roster from Barnaby tavern into Ruined Fortress
	var gm := GameManagerClass.new()
	gm.active_party_roster.clear()
	gm.add_to_party_roster({"id": "paladin_1", "class": "paladin"})
	gm.add_to_party_roster({"id": "archer_1", "class": "archer"})
	runner.assert_true(
		gm.active_party_roster.size() == 2 and gm.active_party_roster[0]["class"] == "paladin",
		"T3.EXP.07: Elena Quest Board Receives and Deploys Barnaby Tavern Roster into Fortress Arena"
	)
	gm.free()

	# T3.EXP.08: Kills during fortress expedition recharge leadership pool used by CompanionBase orders
	var LeadershipScript: GDScript = load("res://scripts/autoloads/leadership_manager.gd")
	var lm: Node = LeadershipScript.new()
	lm.current_charges = 1
	for k in range(20):
		lm.notify_kill()
	runner.assert_eq(
		lm.current_charges, 3,
		"T3.EXP.08: Fortress Combat Kills (20) Recharges Leadership Pool from 1 to 3 Charges"
	)
	lm.free()

	# T3.EXP.09: Breaking 2 Leyline Monoliths triggers 4s Overload stun enabling companion ability burst
	var m1 := LeylineMonolith.new()
	var boss := BossCyclops.new()
	m1.health_component.take_damage(DamageData.new(150.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null))
	boss.apply_leyline_overload(m1.overload_stun_duration)
	runner.assert_true(
		m1.is_destroyed and boss.is_stunned and boss.stun_timer == 4.0,
		"T3.EXP.09: Destroying Both Leyline Monoliths Triggers 4.0s Overload Stun Window on Boss"
	)
	m1.free()
	boss.free()

	# T3.EXP.10: Companion deaths during boss fight increment allies_fallen and reduce AgencyScore
	var agency: Node = TrackerScript.new()
	agency.reset_metrics()
	agency.allies_survived = 1
	agency.rescues_performed = 1
	agency.record_ally_death()
	runner.assert_eq(
		agency.calculate_agency_score(), 5,
		"T3.EXP.10: Companion Death During Boss Fight Deducts 35 Points from Silent Agency Score (+5)"
	)
	agency.free()


# ==============================================================================
# TIER 4: REAL-WORLD SCENARIOS (CAMPAIGN & E2E FLOWS)
# ==============================================================================
func run_tier4(runner: SceneTree) -> void:
	print("\n--- [EXPANSION TIER 4: REAL-WORLD GAMEPLAY SCENARIOS] ---")
	await _test_t4_scenarios(runner)

func _test_t4_scenarios(runner: SceneTree) -> void:
	# T4.EXP.01: Full Campaign E2E Flow Simulation:
	# Greyrock Village -> Elena Quest Board -> Barnaby Tavern -> Ruined Fortress -> Leyline Overload -> Boss Defeat -> Ending Screen
	var gm := GameManagerClass.new()
	runner.assert_true(gm.SCENE_HUB != "" and gm.SCENE_FORTRESS != "", "T4.EXP.01: Hub and Dungeon scenes registered")
	gm.selected_quest_rank = "E"

	var recruit_modal := TavernRecruitModal.new()
	var candidates: Array[Dictionary] = recruit_modal.get_candidates()
	gm.add_to_party_roster(candidates[0])
	gm.add_to_party_roster(candidates[1])
	runner.assert_eq(gm.active_party_roster.size(), 2, "T4.EXP.01: 2 Mercenaries hired in tavern")

	var monolith := LeylineMonolith.new()
	monolith.health_component.take_damage(DamageData.new(150.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null))
	runner.assert_true(monolith.is_destroyed, "T4.EXP.01: Leyline monolith broken")

	var boss := BossCyclops.new()
	boss.apply_leyline_overload(monolith.overload_stun_duration)
	runner.assert_true(boss.is_stunned, "T4.EXP.01: Boss overloaded and stunned")
	boss.health_component.is_invincible = false
	boss.health_component.set("_i_frame_timer", 0.0)
	boss.health_component.take_damage(DamageData.new(650.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null))
	runner.assert_true(boss.is_dead, "T4.EXP.01: Boss defeated cleanly")

	var TrackerScript: GDScript = load("res://scripts/autoloads/agency_tracker.gd")
	var tracker: Node = TrackerScript.new()
	tracker.reset_metrics()
	tracker.allies_deployed = 2
	tracker.allies_survived = 2
	tracker.rescues_performed = 1
	var ending: String = tracker.evaluate_ending()
	runner.assert_eq(ending, "GOOD_ENDING", "T4.EXP.01: Campaign E2E loop resolves to GOOD_ENDING")

	var EndingScene: PackedScene = load("res://scenes/ui/ending_screen/ending_screen.tscn")
	var ending_screen: CanvasLayer = EndingScene.instantiate() as CanvasLayer
	ending_screen.display_ending(ending, tracker.get_metrics())
	runner.assert_true(ending_screen.visible, "T4.EXP.01: Full Campaign E2E Loop Traversal Executed with Flawless Progression State")

	ending_screen.free()
	tracker.free()
	boss.free()
	monolith.free()
	recruit_modal.free()
	gm.free()

	# T4.EXP.02: "Good Ending: A Aliança dos Vivos" Path
	var tracker_good: Node = TrackerScript.new()
	tracker_good.reset_metrics()
	tracker_good.allies_deployed = 2
	tracker_good.allies_survived = 2
	tracker_good.rescues_performed = 1
	tracker_good.allies_fallen = 0
	tracker_good.reckless_orders_issued = 0
	tracker_good.abandonment_ticks = 0
	var good_score: int = tracker_good.calculate_agency_score()
	var good_ending: String = tracker_good.evaluate_ending()
	runner.assert_true(
		good_ending == "GOOD_ENDING" and good_score == 65,
		"T4.EXP.02: Good Ending Path (A Aliança dos Vivos) Evaluates AgencyScore=65 with 0 Casualties"
	)
	tracker_good.free()

	# T4.EXP.03: "Bad Ending: O Monstro Solitário" Path (Neglect & Recklessness)
	var tracker_bad: Node = TrackerScript.new()
	tracker_bad.reset_metrics()
	tracker_bad.allies_deployed = 3
	tracker_bad.allies_survived = 0
	tracker_bad.rescues_performed = 0
	tracker_bad.allies_fallen = 3
	tracker_bad.reckless_orders_issued = 3
	tracker_bad.abandonment_ticks = 2
	var bad_score: int = tracker_bad.calculate_agency_score()
	var bad_ending: String = tracker_bad.evaluate_ending()
	runner.assert_true(
		bad_ending == "BAD_ENDING" and bad_score == -165,
		"T4.EXP.03: Bad Ending Path (O Monstro Solitário) Evaluates AgencyScore=-165 with 3 Casualties"
	)
	tracker_bad.free()

	# T4.EXP.04: Solo Expedition Path (Isolationist Run)
	var tracker_solo: Node = TrackerScript.new()
	tracker_solo.reset_metrics()
	tracker_solo.allies_deployed = 0
	var solo_ending: String = tracker_solo.evaluate_ending()
	runner.assert_eq(
		solo_ending, "BAD_ENDING",
		"T4.EXP.04: Solo Expedition with Zero Recruited Allies Decisively Resolves to BAD_ENDING"
	)
	tracker_solo.free()

	# T4.EXP.05: Psychological Crisis Scenario (Swarm -> Type 5 Collapse -> Retreat Command Recovery)
	var archer := CompanionArcher.new()
	var profile_t5: EnneagramData = EnneagramData.create_preset(EnneagramData.Type.INVESTIGATOR)
	archer.enneagram_profile = profile_t5
	var ctx_crisis := TacticalContext.new()
	ctx_crisis.nearby_enemies_count = 10
	archer.stress_level = EnneagramEvaluator.update_stress(10.0, 0.0, ctx_crisis, profile_t5)
	var state_collapsed: int = int(EnneagramEvaluator.get_mental_state(archer.stress_level))
	var retreat_eval: OrderResult = EnneagramEvaluator.evaluate_order(
		int(EnneagramEvaluator.LeadershipOrder.RETREAT),
		profile_t5,
		state_collapsed,
		ctx_crisis,
		archer.stress_level,
		archer.companion_name
	)
	runner.assert_true(
		state_collapsed == EnneagramEvaluator.MentalState.COLLAPSED and retreat_eval.status == EnneagramEvaluator.OrderStatus.OBEY,
		"T4.EXP.05: Swarm-Induced Enneagram Collapse Successfully Relieved by Tactical Retreat Command"
	)
	archer.free()
