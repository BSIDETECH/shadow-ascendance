class_name Arena
extends Node2D

@export var spawn_interval: float = 2.0
@export var arena_width: float = 1200.0
@export var arena_height: float = 800.0

var _spawn_timer: float = 0.0
var _game_time: float = 0.0
var _current_level: int = 1
var _current_xp: int = 0
var _next_level_xp: int = 8
var _total_kills: int = 0
var _boss_spawned: bool = false

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var gacha_screen: GachaScreen = $GachaScreen

var enemy_scene: PackedScene = preload("res://scenes/entities/enemies/enemy_base.tscn")
var enemy_ranged_scene: PackedScene = preload("res://scenes/entities/enemies/enemy_ranged.tscn")

var _is_game_over: bool = false

func _ready() -> void:
	EventBus.xp_collected.connect(_on_xp_collected)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.boss_died.connect(_on_boss_died)
	gacha_screen.card_chosen.connect(_on_gacha_card_chosen)

	if player != null and is_instance_valid(player):
		player.health_component.died.connect(_on_player_died)

	_setup_party_roster()
	_setup_victory_portal()

	hud.update_xp(_current_xp, _next_level_xp, _current_level)
	hud.update_health(player.health_component.current_health, player.health_component.max_health)
	hud.update_kills(_total_kills)

	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("apply_gacha_card"):
		for card in gm.get("permanent_gacha_cards", []):
			gm.call("apply_gacha_card", card, player, hud, get_tree(), gacha_screen)

var victory_portal: Area2D = null

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

		# Visual portal aura
		var visual := Polygon2D.new()
		visual.name = "PortalVisual"
		visual.color = Color(0.3, 0.8, 1.0, 0.75)
		var pts: PackedVector2Array = []
		for p_idx in range(12):
			var a := (float(p_idx) / 12.0) * TAU
			pts.append(Vector2(cos(a) * 26.0, sin(a) * 26.0))
		visual.polygon = pts
		victory_portal.add_child(visual)

		add_child(victory_portal)

	victory_portal.visible = false
	victory_portal.monitoring = false
	if not victory_portal.body_entered.is_connected(_on_portal_entered):
		victory_portal.body_entered.connect(_on_portal_entered)

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
		if gm != null and gm.has_method("commit_gacha_cards"):
			gm.call("commit_gacha_cards")
		if gm != null and gm.has_method("trigger_ending"):
			gm.call("trigger_ending")
		elif gm != null and gm.has_method("transition_to_hub"):
			gm.call("transition_to_hub")

func _setup_party_roster() -> void:
	var gm = get_tree().root.get_node_or_null("GameManager")
	var roster: Array = []
	if gm != null and ("active_party_roster" in gm):
		roster = gm.get("active_party_roster")

	var spawn_offsets: Array[Vector2] = [Vector2(-35, 30), Vector2(35, 30), Vector2(0, 45)]
	var tracker = get_tree().root.get_node_or_null("SilentAgencyTracker")

	# If no roster configured from village hub, it's a true solo run. No default companions.
	if roster.size() == 0:
		return

	for i in range(mini(roster.size(), spawn_offsets.size())):
		var merc_data: Dictionary = roster[i]
		if tracker != null and tracker.has_method("record_ally_deployed"):
			tracker.call("record_ally_deployed", merc_data)
		var merc_class: String = merc_data.get("class_type", merc_data.get("class", "mage"))
		var comp_node = null

		var scene_path = "res://scenes/entities/companion/companion_" + merc_class.to_lower() + ".tscn"
		if merc_class.to_lower() == "rogue":
			scene_path = "res://scenes/entities/companion/companion_rogue.tscn"

		if not ResourceLoader.exists(scene_path):
			scene_path = "res://scenes/entities/companion/companion.tscn"

		var CompanionScene = load(scene_path)
		if CompanionScene != null:
			comp_node = CompanionScene.instantiate()

		if comp_node != null:
			comp_node.name = "Companion" if i == 0 else ("Companion_%d" % (i + 1))
			var base_pos: Vector2 = player.global_position if (player != null and is_instance_valid(player)) else Vector2(0, 0)
			comp_node.global_position = base_pos + spawn_offsets[i]
			add_child(comp_node)
			if EventBus != null and comp_node.has_method("_on_leadership_order_issued"):
				if not EventBus.leadership_order_issued.is_connected(Callable(comp_node, "_on_leadership_order_issued")):
					EventBus.leadership_order_issued.connect(Callable(comp_node, "_on_leadership_order_issued"))

func _physics_process(delta: float) -> void:
	if _is_game_over:
		return

	# Fail-safe arena boundary clamp for player and companions
	if player != null and is_instance_valid(player):
		player.global_position.x = clampf(player.global_position.x, -586.0, 586.0)
		player.global_position.y = clampf(player.global_position.y, -386.0, 386.0)
	var group_allies := get_tree().get_nodes_in_group("companions")
	for ally in group_allies:
		if ally != null and is_instance_valid(ally):
			ally.global_position.x = clampf(ally.global_position.x, -586.0, 586.0)
			ally.global_position.y = clampf(ally.global_position.y, -386.0, 386.0)

	_game_time += delta
	_spawn_timer -= delta

	if _spawn_timer <= 0.0:
		_spawn_wave()
		# Spawn interval tightens as time goes on (more aggressive pacing)
		_spawn_timer = maxf(0.8, spawn_interval - (_game_time * 0.008))

	# Spawn Demon Boss at 60 seconds (1 minuto de batalha)
	if _game_time >= 60.0 and not _boss_spawned:
		_spawn_boss()

func _spawn_wave() -> void:
	if enemy_scene == null or player == null or not is_instance_valid(player):
		return

	# Performance guard: cap total active enemies on screen to avoid lag/freeze
	var active_enemies := get_tree().get_nodes_in_group("enemies")
	if active_enemies.size() >= 35:
		return

	# Number of enemies per wave scales with time:
	# t=0: 2 enemies | t=25: 3 enemies | t=60: 5 enemies | t=180: max 8 enemies
	var count := 2 + int(_game_time / 20.0)
	count = mini(count, 8)

	for i in range(count):
		# Determine type before instantiation
		var type = Enemy.EnemyType.SKELETON
		if _game_time < 25.0:
			type = Enemy.EnemyType.SLIME if randf() < 0.6 else Enemy.EnemyType.BAT
		elif _game_time < 60.0:
			var roll := randf()
			if roll < 0.35:
				type = Enemy.EnemyType.SKELETON
			elif roll < 0.55:
				type = Enemy.EnemyType.SLIME
			elif roll < 0.75:
				type = Enemy.EnemyType.BAT
			elif roll < 0.90:
				type = Enemy.EnemyType.RANGED
			else:
				type = Enemy.EnemyType.MIMIC
		else:
			var roll := randf()
			if roll < 0.35:
				type = Enemy.EnemyType.SKELETON
			elif roll < 0.60:
				type = Enemy.EnemyType.BAT
			elif roll < 0.75:
				type = Enemy.EnemyType.SLIME
			elif roll < 0.90:
				type = Enemy.EnemyType.RANGED
			else:
				type = Enemy.EnemyType.MIMIC

		var enemy = null
		if type == Enemy.EnemyType.RANGED and enemy_ranged_scene != null:
			enemy = enemy_ranged_scene.instantiate() as Enemy
		else:
			enemy = enemy_scene.instantiate() as Enemy

		if enemy == null:
			continue

		enemy.set_type(type)

		# Random position outside camera view (radius ~380-460)
		var angle := randf() * TAU
		var distance := randf_range(380.0, 460.0)
		var spawn_pos := player.global_position + Vector2(cos(angle), sin(angle)) * distance

		# Clamp within arena bounds
		spawn_pos.x = clampf(spawn_pos.x, -560.0, 560.0)
		spawn_pos.y = clampf(spawn_pos.y, -360.0, 360.0)

		enemy.global_position = spawn_pos
		add_child(enemy)

func _spawn_boss() -> void:
	_boss_spawned = true
	var boss := enemy_scene.instantiate() as Enemy
	if boss != null:
		boss.set_type(Enemy.EnemyType.DEMON_BOSS)
		boss.global_position = player.global_position + Vector2(0, -380)

		if player != null and is_instance_valid(player) and player.has_meta("realm_of_death_unlocked") and player.get_meta("realm_of_death_unlocked"):
			boss.max_health *= 0.85
			boss.contact_damage *= 0.85
			boss.health_component.max_health = boss.max_health
			boss.health_component.current_health = boss.max_health
			boss.hitbox_component.damage_amount = boss.contact_damage

			player.damage_mult += 0.15
			player.health_component.max_health += player.health_component.max_health * 0.15
			player.health_component.current_health += player.health_component.max_health * 0.15
			hud.update_health(player.health_component.current_health, player.health_component.max_health)

		add_child(boss)

func _on_xp_collected(amount: int) -> void:
	_current_xp += amount
	if _current_xp >= _next_level_xp:
		_current_xp -= _next_level_xp
		_current_level += 1
		_next_level_xp = int(float(_next_level_xp) * 1.5) + 6
		
		# Trigger Goddess Gacha Screen!
		gacha_screen.open_gacha(_current_level)

	hud.update_xp(_current_xp, _next_level_xp, _current_level)

func _on_enemy_died(_pos: Vector2, _xp: int) -> void:
	_total_kills += 1
	hud.update_kills(_total_kills)

func _on_boss_died(boss_name: String, _pos: Vector2) -> void:
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

	# Clean up leftover mobs
	var mobs = get_tree().get_nodes_in_group("enemies")
	for m in mobs:
		if is_instance_valid(m) and m != self:
			m.queue_free()

	# Activate Victory Portal at arena center
	if victory_portal != null:
		victory_portal.visible = true
		victory_portal.set_deferred("monitoring", true)
		victory_portal.global_position = Vector2(0, 0)

	# Quando o Boss morre, abre a tela de Roubo de Alma do Chefe
	get_tree().create_timer(0.4).timeout.connect(func():
		gacha_screen.open_boss_theft(boss_name)
	)

func _on_player_died() -> void:
	if _is_game_over:
		return
	_is_game_over = true

	# Pausa spawns e aguarda dissolução do jogador para abrir tela de desfecho
	get_tree().create_timer(1.0).timeout.connect(func():
		_show_game_over()
	)

func _show_game_over() -> void:
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("clear_gacha_cards"):
		gm.call("clear_gacha_cards")
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


func _on_gacha_card_chosen(card: Dictionary) -> void:
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm != null:
		if gm.has_method("add_pending_gacha_card"):
			gm.call("add_pending_gacha_card", card)
		if gm.has_method("apply_gacha_card"):
			gm.call("apply_gacha_card", card, player, hud, get_tree(), gacha_screen)
