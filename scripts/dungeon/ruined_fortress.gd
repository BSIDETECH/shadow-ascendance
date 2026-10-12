class_name RuinedFortress
extends Node2D

## Ruined Fortress Dungeon Sector for "Shadow Cheat: Solo Guild Ascendance".
## Features 2 Leyline Monoliths, Elemental Guardian boss encounter (Ignis or Glacies),
## mob add spawners, perimeter colliders, and a victory portal upon guardian defeat.

signal boss_defeated(boss_name: String)
signal victory_portal_activated()

@export var arena_width: float = 900.0
@export var arena_height: float = 600.0
@export var add_spawn_interval: float = 9.0
@export var max_adds_alive: int = 6

const MonolithScript = preload("res://scripts/dungeon/leyline_monolith.gd")
const BossGuardianScript = preload("res://scripts/entities/boss_guardian_base.gd")
const BossCyclopsScript = preload("res://scripts/entities/boss_cyclops.gd")
const BossGlaciesScript = preload("res://scripts/entities/boss_glacies.gd")

var _add_timer: float = 4.0
var _active_adds: Array[Node] = []
var _monoliths_destroyed_count: int = 0
var _boss_is_defeated: bool = false
var _is_game_over: bool = false

@onready var monolith_left: Node = $MonolithLeft if has_node("MonolithLeft") else null
@onready var monolith_right: Node = $MonolithRight if has_node("MonolithRight") else null
@onready var player: Node = $Player if has_node("Player") else null
@onready var boss_node: Node = $Boss if has_node("Boss") else null
@onready var victory_portal: Area2D = $VictoryPortal if has_node("VictoryPortal") else null
@onready var hud: GameHUD = $HUD if has_node("HUD") else null

var enemy_scene: PackedScene = preload("res://scenes/entities/enemies/enemy_base.tscn")

func _ready() -> void:
	_setup_monoliths()
	_setup_boss()
	_setup_victory_portal()
	_setup_party_roster()

	if player != null:
		var player_health = player.get_node_or_null("HealthComponent")
		if player_health != null and not player_health.died.is_connected(_on_player_died):
			player_health.died.connect(_on_player_died)

	var eb := get_tree().root.get_node_or_null("EventBus")
	if eb != null and not eb.boss_died.is_connected(_on_boss_died):
		eb.boss_died.connect(_on_boss_died)

func _setup_monoliths() -> void:
	if monolith_left != null and monolith_left.has_signal("monolith_destroyed"):
		monolith_left.connect("monolith_destroyed", _on_monolith_destroyed)
	if monolith_right != null and monolith_right.has_signal("monolith_destroyed"):
		monolith_right.connect("monolith_destroyed", _on_monolith_destroyed)

func _setup_boss() -> void:
	# If boss not preset in scene tree, spawn according to quest rank
	if boss_node == null:
		var gm = get_tree().root.get_node_or_null("GameManager")
		var quest_rank: String = gm.get_selected_quest_rank() if gm != null and gm.has_method("get_selected_quest_rank") else "E"

		if quest_rank == "D":
			boss_node = BossGlaciesScript.new()
		else:
			boss_node = BossCyclopsScript.new()

		boss_node.name = "Boss"
		boss_node.global_position = Vector2(0, -160)
		add_child(boss_node)

	if boss_node != null and not boss_node.boss_defeated.is_connected(_on_guardian_defeated):
		boss_node.boss_defeated.connect(_on_guardian_defeated)

func _setup_victory_portal() -> void:
	if victory_portal == null:
		victory_portal = Area2D.new()
		victory_portal.name = "VictoryPortal"
		victory_portal.collision_layer = 0
		victory_portal.collision_mask = 2 # Player
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 28.0
		shape.shape = circle
		victory_portal.add_child(shape)
		add_child(victory_portal)

	victory_portal.visible = false
	victory_portal.monitoring = false
	if not victory_portal.body_entered.is_connected(_on_portal_entered):
		victory_portal.body_entered.connect(_on_portal_entered)

func _setup_party_roster() -> void:
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm == null or not gm.has_method("get_active_party_roster"):
		return

	var roster: Array = gm.call("get_active_party_roster")
	if roster.size() == 0:
		return

	# Spawn companions from roster around player spawn point
	var spawn_offsets: Array[Vector2] = [Vector2(-35, 30), Vector2(35, 30), Vector2(0, 45)]
	var tracker = get_tree().root.get_node_or_null("SilentAgencyTracker")
	for i in range(mini(roster.size(), spawn_offsets.size())):
		var merc_data: Dictionary = roster[i]
		if tracker != null and tracker.has_method("record_ally_deployed"):
			tracker.call("record_ally_deployed", merc_data)
		var merc_class: String = merc_data.get("class", "mage")
		var comp_node: Node2D = null

		match merc_class.to_lower():
			"paladin":
				var PaladinClass = load("res://scripts/entities/companion_paladin.gd")
				if PaladinClass != null:
					comp_node = PaladinClass.new()
			"archer":
				var ArcherClass = load("res://scripts/entities/companion_archer.gd")
				if ArcherClass != null:
					comp_node = ArcherClass.new()
			"rogue":
				var RogueClass = load("res://scripts/entities/companion_rogue.gd")
				if RogueClass != null:
					comp_node = RogueClass.new()
			_:
				var MageClass = load("res://scripts/entities/companion_mage.gd")
				if MageClass != null:
					comp_node = MageClass.new()

		if comp_node != null:
			comp_node.name = "Companion_%d" % (i + 1)
			var base_pos: Vector2 = player.global_position if (player != null and player is Node2D) else Vector2(0, 160)
			comp_node.global_position = base_pos + spawn_offsets[i]
			add_child(comp_node)

func _physics_process(delta: float) -> void:
	if _boss_is_defeated or _is_game_over:
		return

	_add_timer -= delta
	if _add_timer <= 0.0:
		_add_timer = add_spawn_interval
		_spawn_mob_adds()

func _spawn_mob_adds() -> void:
	if enemy_scene == null or _boss_is_defeated:
		return

	# Clean dead adds from tracking array
	_active_adds = _active_adds.filter(func(a): return is_instance_valid(a))
	if _active_adds.size() >= max_adds_alive:
		return

	# Spawn 4 adds at arena flanks and top/bottom
	var spawn_points: Array[Vector2] = [
		Vector2(-arena_width * 0.42, randf_range(-120, 120)),
		Vector2(arena_width * 0.42, randf_range(-120, 120)),
		Vector2(randf_range(-180, 180), -arena_height * 0.38),
		Vector2(randf_range(-180, 180), arena_height * 0.38)
	]

	for pos in spawn_points:
		if _active_adds.size() >= max_adds_alive:
			break
		var enemy = enemy_scene.instantiate() as CharacterBody2D
		if enemy != null:
			enemy.global_position = pos
			add_child(enemy)
			_active_adds.append(enemy)

func _on_monolith_destroyed(monolith: Node) -> void:
	_monoliths_destroyed_count += 1

	# When both monoliths are broken, trigger Leyline Overload on boss
	if _monoliths_destroyed_count >= 2:
		if boss_node != null and is_instance_valid(boss_node):
			# If boss is already dead, cleanly no-ops without error (T2.EXP.18)
			boss_node.apply_leyline_overload(4.0)

func _on_guardian_defeated(b_name: String) -> void:
	_handle_boss_death(b_name)

func _on_boss_died(b_name: String, _pos: Vector2) -> void:
	_handle_boss_death(b_name)

func _handle_boss_death(b_name: String) -> void:
	if _boss_is_defeated:
		return
	_boss_is_defeated = true

	# Clean up remaining add mobs
	for a in _active_adds:
		if is_instance_valid(a):
			a.queue_free()
	_active_adds.clear()

	# Activate Victory Portal at arena center
	if victory_portal != null:
		victory_portal.visible = true
		victory_portal.monitoring = true
		victory_portal.global_position = Vector2(0, 0)

	boss_defeated.emit(b_name)
	victory_portal_activated.emit()

func _on_portal_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		if victory_portal != null:
			victory_portal.set_deferred("monitoring", false)
		
		# Record surviving allies
		var tracker = get_tree().root.get_node_or_null("SilentAgencyTracker")
		if tracker != null and tracker.has_method("record_ally_survived"):
			var companions = get_tree().get_nodes_in_group("companions")
			for comp in companions:
				if is_instance_valid(comp) and not comp.get("is_dying"):
					tracker.call("record_ally_survived")


		var gm = get_tree().root.get_node_or_null("GameManager")
		if gm != null:
			var rank = gm.get("selected_quest_rank")
			if rank == null and gm.has_method("get_selected_quest_rank"):
				rank = gm.get_selected_quest_rank()

			var reward = 0
			if rank == "F": reward = 100
			elif rank == "E": reward = 350
			elif rank == "D": reward = 800

			if reward > 0 and gm.has_method("add_gold"):
				gm.add_gold(reward)

		if gm != null and gm.has_method("trigger_ending"):

			gm.call("trigger_ending")
		elif gm != null and gm.has_method("transition_to_hub"):
			gm.call("transition_to_hub")

func _on_player_died() -> void:
	if _is_game_over:
		return
	_is_game_over = true

	get_tree().create_timer(1.0).timeout.connect(func():
		_show_game_over()
	)

func _show_game_over() -> void:
	var ending_scene: PackedScene = load("res://scenes/ui/ending_screen/ending_screen.tscn")
	if ending_scene != null:
		var ending_node = ending_scene.instantiate()
		add_child(ending_node)
		if ending_node.has_method("display_ending"):
			ending_node.display_ending("BAD_ENDING", {
				"allies_survived": 0,
				"rescues_performed": 0,
				"allies_fallen": 1,
				"reckless_orders_issued": 0,
				"abandonment_ticks": 0,
				"agency_score": -35
			})
