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

var _is_game_over: bool = false

func _ready() -> void:
	EventBus.xp_collected.connect(_on_xp_collected)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.boss_died.connect(_on_boss_died)
	gacha_screen.card_chosen.connect(_on_gacha_card_chosen)

	if player != null and is_instance_valid(player):
		player.health_component.died.connect(_on_player_died)

	_setup_party_roster()

	hud.update_xp(_current_xp, _next_level_xp, _current_level)
	hud.update_health(player.health_component.current_health, player.health_component.max_health)
	hud.update_kills(_total_kills)

func _setup_party_roster() -> void:
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm == null or not ("active_party_roster" in gm):
		return

	var roster: Array = gm.get("active_party_roster")
	if roster.size() == 0:
		return

	var spawn_offsets: Array[Vector2] = [Vector2(-35, 30), Vector2(35, 30), Vector2(0, 45)]
	var tracker = get_tree().root.get_node_or_null("SilentAgencyTracker")
	for i in range(mini(roster.size(), spawn_offsets.size())):
		var merc_data: Dictionary = roster[i]
		if tracker != null and tracker.has_method("record_ally_deployed"):
			tracker.call("record_ally_deployed", merc_data)
		var merc_class: String = merc_data.get("class", "mage")
		var comp_node = null

		var scene_path = "res://scenes/entities/companion/companion_" + merc_class.to_lower() + ".tscn"
		if not ResourceLoader.exists(scene_path):
			scene_path = "res://scenes/entities/companion/companion.tscn"

		var CompanionScene = load(scene_path)
		if CompanionScene != null:
			comp_node = CompanionScene.instantiate()

		if comp_node != null:
			comp_node.name = "Companion_%d" % (i + 1)
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
		_spawn_timer = maxf(0.55, (spawn_interval * 0.75) - (_game_time * 0.01))

	# Spawn Demon Boss at 60 seconds (1 minuto de batalha)
	if _game_time >= 60.0 and not _boss_spawned:
		_spawn_boss()

func _spawn_wave() -> void:
	if enemy_scene == null or player == null or not is_instance_valid(player):
		return

	# Number of enemies per wave scales with time (increased density)
	var count := 4 + int(_game_time / 14.0)
	count = mini(count, 14)

	for i in range(count):
		var enemy := enemy_scene.instantiate() as Enemy
		if enemy == null:
			continue

		# Random position outside camera view (radius ~380-460)
		var angle := randf() * TAU
		var distance := randf_range(380.0, 460.0)
		var spawn_pos := player.global_position + Vector2(cos(angle), sin(angle)) * distance

		# Clamp within arena bounds
		spawn_pos.x = clampf(spawn_pos.x, -560.0, 560.0)
		spawn_pos.y = clampf(spawn_pos.y, -360.0, 360.0)

		enemy.global_position = spawn_pos

		# Pick enemy type based on elapsed time
		if _game_time < 25.0:
			enemy.set_type(Enemy.EnemyType.SLIME if randf() < 0.6 else Enemy.EnemyType.BAT)
		elif _game_time < 60.0:
			var roll := randf()
			if roll < 0.4:
				enemy.set_type(Enemy.EnemyType.SKELETON)
			elif roll < 0.7:
				enemy.set_type(Enemy.EnemyType.SLIME)
			else:
				enemy.set_type(Enemy.EnemyType.BAT)
		else:
			var roll := randf()
			if roll < 0.5:
				enemy.set_type(Enemy.EnemyType.SKELETON)
			elif roll < 0.8:
				enemy.set_type(Enemy.EnemyType.BAT)
			else:
				enemy.set_type(Enemy.EnemyType.SLIME)

		add_child(enemy)

func _spawn_boss() -> void:
	_boss_spawned = true
	var boss := enemy_scene.instantiate() as Enemy
	if boss != null:
		boss.set_type(Enemy.EnemyType.DEMON_BOSS)
		boss.global_position = player.global_position + Vector2(0, -380)
		add_child(boss)

func _on_xp_collected(amount: int) -> void:
	_current_xp += amount
	if _current_xp >= _next_level_xp:
		_current_xp -= _next_level_xp
		_current_level += 1
		_next_level_xp = int(float(_next_level_xp) * 1.35) + 4
		
		# Trigger Goddess Gacha Screen!
		gacha_screen.open_gacha(_current_level)

	hud.update_xp(_current_xp, _next_level_xp, _current_level)

func _on_enemy_died(_pos: Vector2, _xp: int) -> void:
	_total_kills += 1
	hud.update_kills(_total_kills)

func _on_boss_died(boss_name: String, _pos: Vector2) -> void:
	# Quando o Boss morre, pausa a ação e abre a tela de Roubo de Alma do Chefe!
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

func _buff_companion(prop_name: String, multiplier: float = 1.0, add_value: float = 0.0) -> void:
	# Coleta referências válidas e vivas de companheiros para aplicar melhorias com segurança
	var targets: Array = []

	var group_allies := get_tree().get_nodes_in_group("companions")
	for ally in group_allies:
		if ally != null and is_instance_valid(ally) and not targets.has(ally):
			targets.append(ally)

	for target in targets:
		if is_instance_valid(target) and prop_name in target:
			if multiplier != 1.0:
				target.set(prop_name, target.get(prop_name) * multiplier)
			if add_value != 0.0:
				target.set(prop_name, target.get(prop_name) + add_value)

func _on_gacha_card_chosen(card: Dictionary) -> void:
	var id: String = card.get("id", "")
	match id:
		# Cartas R
		"dmg_up":
			player.damage_mult += 0.25
		"spd_up":
			player.move_speed_mult += 0.20
		"mag_up":
			player.pickup_radius *= 1.6
			player._update_magnet_radius()
		"hp_up":
			player.health_component.max_health += 30.0
			player.health_component.current_health += 30.0
			hud.update_health(player.health_component.current_health, player.health_component.max_health)
		# Cartas SR
		"mage_multi":
			_buff_companion("projectiles_per_cast", 1.0, 1.0)
		"dash_cdr":
			player.dash_cooldown_mult *= 0.65
		"heal_full":
			player.health_component.max_health += 40.0
			player.health_component.current_health = player.health_component.max_health
			hud.update_health(player.health_component.current_health, player.health_component.max_health)
		"mage_haste":
			_buff_companion("cast_cooldown", 0.60)
		# Cartas SSR
		"lifesteal":
			player.lifesteal_on_kill += 2.5
		"atk_spd":
			player.attack_speed_mult += 0.50
		"mage_dmg":
			_buff_companion("projectile_damage", 1.60)
		"ssr_vampire":
			player.lifesteal_on_kill += 4.0
			player.attack_speed_mult += 0.40
		"ssr_storm":
			player.attack_speed_mult += 0.75
			player.move_speed_mult += 0.35
		# Cartas EX (Cheats Iniciais)
		"ex_abyss":
			player.abyssal_burst_unlocked = true
		"ex_god":
			player.damage_mult *= 2.0
			player.dash_cooldown_mult *= 0.40
		"ex_mage_wrath":
			_buff_companion("projectiles_per_cast", 1.0, 2.0)
			_buff_companion("projectile_damage", 2.0)
		# Cartas de Roubo de Chefe (Boss Theft)
		"boss_demon_heart":
			player.health_component.max_health += 100.0
			player.health_component.current_health = player.health_component.max_health
			player.fire_pulse_unlocked = true
			hud.update_health(player.health_component.current_health, player.health_component.max_health)
		"boss_executioner":
			player.executioner_unlocked = true
			player.damage_mult += 0.40
		"boss_meteor":
			_buff_companion("projectile_damage", 2.20)
			_buff_companion("projectiles_per_cast", 1.0, 1.0)
