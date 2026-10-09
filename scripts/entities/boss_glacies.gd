class_name BossGlacies
extends "res://scripts/entities/boss_guardian_base.gd"

## Rank D Elemental Guardian: Glacies (Frost Sovereign).
## 950 Max HP.
## Phase 1: Ice Lance (linear telegraphed beam 24px x 240px, 1.0s charge, 50 dmg),
##          Blizzard Pulse (radial expanding wave, 40% slow for 3.0s).
## Phase 2: Frost Tomb (encases companion in 6.0s breakable ice tomb),
##          Polar Shift (teleport repositioning + localized blizzard vortex).

const BOSS_TEXTURE: String = "res://assets/kenney_tiny_dungeon/Tiles/tile_0122.png"

var ice_lance_aim_dir: Vector2 = Vector2.RIGHT

func _init() -> void:
	boss_name = "Glacies, Frost Sovereign"
	max_health = 950.0
	current_health = 950.0
	base_speed = 50.0
	attack_range = 150.0
	attack_cooldown = 3.0
	super._init()

func _ready() -> void:
	super._ready()
	if sprite != null and ResourceLoader.exists(BOSS_TEXTURE):
		sprite.texture = load(BOSS_TEXTURE)
		sprite.modulate = Color(0.6, 0.9, 1.4, 1.0) # Glacial Sovereign cyan/white
		sprite.scale = Vector2(1.5, 1.5)

func _select_and_start_attack() -> void:
	if target == null:
		return

	var roll := randf()

	if current_phase == 1:
		if roll < 0.55:
			_start_ice_lance()
		else:
			_start_blizzard_pulse()
	else:
		# Phase 2 includes Frost Tomb and Polar Shift
		if roll < 0.35:
			_start_frost_tomb()
		elif roll < 0.65:
			_start_polar_shift()
		elif roll < 0.85:
			_start_ice_lance()
		else:
			_start_blizzard_pulse()

# --- Attack 1: Ice Lance ---
func _start_ice_lance() -> void:
	if target != null and is_instance_valid(target):
		ice_lance_aim_dir = (target.global_position - global_position).normalized()
	else:
		ice_lance_aim_dir = Vector2.RIGHT

	var indicator := TelegraphVisual.new(TelegraphVisual.Type.RECTANGLE, 1.0)
	indicator.rect_size = Vector2(240.0, 24.0)
	indicator.rotation = ice_lance_aim_dir.angle()
	_start_telegraph("ice_lance", 1.0, indicator)

func _execute_ice_lance() -> void:
	_change_state(BossState.ATTACK)
	state_timer = 0.3

	var parent_node := get_parent() if get_parent() != null else self
	var lance := GlaciesIceLanceShard.new(global_position, ice_lance_aim_dir, 50.0)
	parent_node.add_child(lance)

# --- Attack 2: Blizzard Pulse ---
func _start_blizzard_pulse() -> void:
	var indicator := TelegraphVisual.new(TelegraphVisual.Type.CIRCLE, 1.1)
	indicator.radius = 120.0
	_start_telegraph("blizzard_pulse", 1.1, indicator)

func _execute_blizzard_pulse() -> void:
	_change_state(BossState.ATTACK)
	state_timer = 0.4

	# Visual wave
	_spawn_pulse_visual()

	var tree := get_tree()
	if tree != null:
		var radius := 120.0
		var damage_val := 20.0
		# Hit player
		for p in tree.get_nodes_in_group("player"):
			var player_node := p as Node2D
			if player_node != null and global_position.distance_to(player_node.global_position) <= radius:
				var hurt := player_node.get_node_or_null("HurtboxComponent") as HurtboxComponent
				var data := DamageData.new(damage_val, DamageData.DamageType.ICE, 80.0, (player_node.global_position - global_position).normalized(), self)
				if hurt != null:
					hurt.receive_hit(data)
				_apply_target_slow(player_node, 0.40, 3.0)

		# Hit companions
		for ally in tree.get_nodes_in_group("allies"):
			var ally_node := ally as Node2D
			if ally_node != null and global_position.distance_to(ally_node.global_position) <= radius:
				var hurt := ally_node.get_node_or_null("HurtboxComponent") as HurtboxComponent
				var data := DamageData.new(damage_val, DamageData.DamageType.ICE, 80.0, (ally_node.global_position - global_position).normalized(), self)
				if hurt != null:
					hurt.receive_hit(data)
				_apply_target_slow(ally_node, 0.40, 3.0)

func _apply_target_slow(target_node: Node2D, slow_pct: float, duration: float) -> void:
	if target_node == null:
		return
	if target_node.has_method("apply_slow"):
		target_node.call("apply_slow", slow_pct, duration)
	elif target_node.get("move_speed_mult") != null:
		var prev_spd: float = target_node.get("move_speed_mult")
		target_node.set("move_speed_mult", prev_spd * (1.0 - slow_pct))
		var tree := get_tree()
		if tree != null:
			tree.create_timer(duration).timeout.connect(func():
				if is_instance_valid(target_node):
					target_node.set("move_speed_mult", prev_spd)
			)

# --- Attack 3: Frost Tomb (Phase 2) ---
func _start_frost_tomb() -> void:
	# Select a companion to encase
	var companion_target := _find_companion_target()
	if companion_target != null:
		var indicator := TelegraphVisual.new(TelegraphVisual.Type.CIRCLE, 0.9)
		indicator.radius = 35.0
		indicator.global_position = companion_target.global_position
		_start_telegraph("frost_tomb", 0.9, indicator)
	else:
		# If no companion active, fallback to Ice Lance
		_start_ice_lance()

func _execute_frost_tomb() -> void:
	_change_state(BossState.ATTACK)
	state_timer = 0.3

	var companion_target := _find_companion_target()
	if companion_target != null:
		var parent_node := get_parent() if get_parent() != null else self
		var tomb := FrostTomb.new(companion_target)
		parent_node.add_child(tomb)

func _find_companion_target() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var allies := tree.get_nodes_in_group("companions")
	for ally in allies:
		var ally_node := ally as Node2D
		if ally_node != null and is_instance_valid(ally_node):
			var hp := ally_node.get_node_or_null("HealthComponent") as HealthComponent
			if hp != null and hp.is_alive() and not ally_node.is_in_group("frost_tombs"):
				return ally_node
	return null

# --- Attack 4: Polar Shift (Phase 2) ---
func _start_polar_shift() -> void:
	var indicator := TelegraphVisual.new(TelegraphVisual.Type.CIRCLE, 0.7)
	indicator.radius = 45.0
	_start_telegraph("polar_shift", 0.7, indicator)

func _execute_polar_shift() -> void:
	_change_state(BossState.ATTACK)
	state_timer = 0.4

	# Leave localized blizzard vortex at previous location
	var parent_node := get_parent() if get_parent() != null else self
	var vortex := GlaciesBlizzardVortex.new(global_position, 3.0)
	parent_node.add_child(vortex)

	# Teleport reposition (approx 140px away, clamped)
	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * 140.0
	global_position += offset

func _execute_attack() -> void:
	super._execute_attack()
	match current_attack_name:
		"ice_lance":
			_execute_ice_lance()
		"blizzard_pulse":
			_execute_blizzard_pulse()
		"frost_tomb":
			_execute_frost_tomb()
		"polar_shift":
			_execute_polar_shift()
		_:
			_change_state(BossState.CHASE)

func _spawn_pulse_visual() -> void:
	var pulse_fx := Node2D.new()
	pulse_fx.global_position = global_position
	pulse_fx.z_index = -1
	var parent_node := get_parent() if get_parent() != null else self
	parent_node.add_child(pulse_fx)

	var tween := pulse_fx.create_tween()
	if tween != null:
		var mat_draw := func():
			pulse_fx.draw_circle(Vector2.ZERO, 120.0, Color(0.3, 0.7, 1.0, 0.35))
			pulse_fx.draw_arc(Vector2.ZERO, 120.0, 0, TAU, 32, Color(0.7, 0.9, 1.2, 0.8), 2.5)
		pulse_fx.draw.connect(mat_draw)
		pulse_fx.queue_redraw()
		tween.tween_property(pulse_fx, "modulate:a", 0.0, 0.4)
		tween.tween_callback(pulse_fx.queue_free)
	else:
		pulse_fx.queue_free()

## Helper class for Ice Lance Projectile
class GlaciesIceLanceShard extends Area2D:
	var velocity: Vector2 = Vector2.ZERO
	var damage: float = 50.0
	var speed: float = 380.0
	var lifetime: float = 1.2
	var hit_targets: Array[Node] = []

	func _init(start_pos: Vector2, dir: Vector2, dmg: float) -> void:
		global_position = start_pos
		velocity = dir.normalized() * speed
		damage = dmg
		collision_layer = 16
		collision_mask = 66
		monitoring = true

	func _ready() -> void:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(24.0, 10.0)
		shape.shape = box
		shape.rotation = velocity.angle()
		add_child(shape)
		area_entered.connect(_on_area_entered)

	func _physics_process(delta: float) -> void:
		global_position += velocity * delta
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()

	func _on_area_entered(area: Area2D) -> void:
		var hurt := area as HurtboxComponent
		if hurt != null and hurt.team_index == 0 and not hit_targets.has(hurt):
			hit_targets.append(hurt)
			var data := DamageData.new(damage, DamageData.DamageType.ICE, 120.0, velocity.normalized(), null)
			hurt.receive_hit(data)

	func _draw() -> void:
		var dir_norm := velocity.normalized()
		var p1 := -dir_norm * 12.0
		var p2 := dir_norm * 12.0
		draw_line(p1, p2, Color(0.8, 0.95, 1.5, 1.0), 4.0)

## Helper class for Localized Blizzard Vortex
class GlaciesBlizzardVortex extends Area2D:
	var lifetime: float = 3.0
	var tick_timer: float = 0.0
	var radius: float = 40.0

	func _init(pos: Vector2, dur: float) -> void:
		global_position = pos
		lifetime = dur
		collision_layer = 16
		collision_mask = 66
		monitoring = true

	func _ready() -> void:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		add_child(shape)

	func _physics_process(delta: float) -> void:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()
			return

		tick_timer -= delta
		if tick_timer <= 0.0:
			tick_timer = 0.5
			for area in get_overlapping_areas():
				var hurt := area as HurtboxComponent
				if hurt != null and hurt.team_index == 0:
					var data := DamageData.new(5.0, DamageData.DamageType.ICE, 0.0, Vector2.ZERO, null)
					hurt.receive_hit(data)
		queue_redraw()

	func _draw() -> void:
		var alpha := clampf(lifetime / 3.0, 0.0, 0.8)
		draw_circle(Vector2.ZERO, radius, Color(0.4, 0.8, 1.2, 0.3 * alpha))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 16, Color(0.7, 0.9, 1.0, 0.6 * alpha), 1.5)
