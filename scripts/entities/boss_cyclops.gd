class_name BossCyclops
extends "res://scripts/entities/boss_guardian_base.gd"

## Rank E Elemental Guardian: Ignis (Flame Colossus).
## 650 Max HP.
## Phase 1: Seismic Slam (radius ~65px, 1.2s charge, 45 dmg + knockback), Flame Fan (5 projectiles, 60-degree cone).
## Phase 2: Magma Trails (4.0s duration burning pools while moving), Major Eruption (pulsing shockwaves).

const BOSS_TEXTURE: String = "res://assets/kenney_tiny_dungeon/Tiles/tile_0109.png"

var magma_pool_timer: float = 0.0
const MAGMA_INTERVAL: float = 0.55

func _init() -> void:
	boss_name = "Ignis, Flame Colossus"
	max_health = 650.0
	current_health = 650.0
	base_speed = 55.0
	attack_range = 130.0
	attack_cooldown = 2.8
	super._init()

func _ready() -> void:
	super._ready()
	if sprite != null and ResourceLoader.exists(BOSS_TEXTURE):
		sprite.texture = load(BOSS_TEXTURE)
		sprite.modulate = Color(1.3, 0.6, 0.4, 1.0) # Fiery colossus tint
		sprite.scale = Vector2(1.5, 1.5)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Phase 2 Passive: Magma Trails while moving in CHASE state
	if current_phase == 2 and current_state == BossState.CHASE and not is_stunned and not is_dead:
		magma_pool_timer -= delta
		if magma_pool_timer <= 0.0:
			magma_pool_timer = MAGMA_INTERVAL
			_spawn_magma_pool()

func _select_and_start_attack() -> void:
	if target == null:
		return

	var dist := global_position.distance_to(target.global_position)
	var roll := randf()

	if current_phase == 1:
		if dist <= 80.0 or roll < 0.55:
			_start_seismic_slam()
		else:
			_start_flame_fan()
	else:
		# Phase 2 includes Major Eruption
		if roll < 0.40:
			_start_major_eruption()
		elif roll < 0.70:
			_start_seismic_slam()
		else:
			_start_flame_fan()

# --- Attack 1: Seismic Slam ---
func _start_seismic_slam() -> void:
	var indicator := TelegraphVisual.new(TelegraphVisual.Type.CIRCLE, 1.2)
	indicator.radius = 65.0
	_start_telegraph("seismic_slam", 1.2, indicator)

func _execute_seismic_slam() -> void:
	_change_state(BossState.ATTACK)
	state_timer = 0.4 # Slam impact recovery

	# Impact visual
	_spawn_slam_visual()

	# Deal damage and knockback to overlapping targets within 65px radius
	var tree := get_tree()
	if tree != null:
		var radius := 65.0
		var slam_damage := 45.0
		# Hit player
		for p in tree.get_nodes_in_group("player"):
			var player_node := p as Node2D
			if player_node != null and global_position.distance_to(player_node.global_position) <= radius:
				var hurt := player_node.get_node_or_null("HurtboxComponent") as HurtboxComponent
				var kb_dir := (player_node.global_position - global_position).normalized()
				var data := DamageData.new(slam_damage, DamageData.DamageType.PHYSICAL, 220.0, kb_dir, self)
				if hurt != null:
					hurt.receive_hit(data)
				elif player_node.has_method("take_damage"):
					player_node.call("take_damage", data)

		# Hit allies/companions
		for ally in tree.get_nodes_in_group("allies"):
			var ally_node := ally as Node2D
			if ally_node != null and global_position.distance_to(ally_node.global_position) <= radius:
				var hurt := ally_node.get_node_or_null("HurtboxComponent") as HurtboxComponent
				var kb_dir := (ally_node.global_position - global_position).normalized()
				var data := DamageData.new(slam_damage, DamageData.DamageType.PHYSICAL, 200.0, kb_dir, self)
				if hurt != null:
					hurt.receive_hit(data)

# --- Attack 2: Flame Fan ---
func _start_flame_fan() -> void:
	var aim_dir := Vector2.RIGHT
	if target != null and is_instance_valid(target):
		aim_dir = (target.global_position - global_position).normalized()

	var indicator := TelegraphVisual.new(TelegraphVisual.Type.CONE, 1.0)
	indicator.radius = 160.0
	indicator.cone_angle = deg_to_rad(60.0)
	indicator.rotation = aim_dir.angle()
	_start_telegraph("flame_fan", 1.0, indicator)

func _execute_flame_fan() -> void:
	_change_state(BossState.ATTACK)
	state_timer = 0.3

	var aim_dir := Vector2.RIGHT
	if target != null and is_instance_valid(target):
		aim_dir = (target.global_position - global_position).normalized()

	# Spread 5 fire projectiles in a 60-degree cone
	var count := 5
	var total_spread := deg_to_rad(60.0)
	var start_angle := aim_dir.angle() - (total_spread * 0.5)
	var step := total_spread / float(count - 1)

	var parent_node := get_parent() if get_parent() != null else self
	for i in range(count):
		var angle := start_angle + (step * float(i))
		var dir := Vector2(cos(angle), sin(angle))
		var proj := IgnisFlameProjectile.new(global_position, dir, 18.0)
		parent_node.add_child(proj)

# --- Attack 3: Major Eruption (Phase 2) ---
func _start_major_eruption() -> void:
	var indicator := TelegraphVisual.new(TelegraphVisual.Type.CIRCLE, 1.4)
	indicator.radius = 180.0
	_start_telegraph("major_eruption", 1.4, indicator)

func _execute_major_eruption() -> void:
	_change_state(BossState.ATTACK)
	state_timer = 0.8 # Eruption duration

	var parent_node := get_parent() if get_parent() != null else self
	# Launch 2 expanding shockwave rings
	for wave_idx in range(2):
		var shockwave := IgnisShockwaveRing.new(global_position, 35.0, wave_idx * 0.2)
		parent_node.add_child(shockwave)

func _execute_attack() -> void:
	super._execute_attack()
	match current_attack_name:
		"seismic_slam":
			_execute_seismic_slam()
		"flame_fan":
			_execute_flame_fan()
		"major_eruption":
			_execute_major_eruption()
		_:
			_change_state(BossState.CHASE)

func _spawn_slam_visual() -> void:
	var slam_fx := Node2D.new()
	slam_fx.global_position = global_position
	slam_fx.z_index = -1
	var parent_node := get_parent() if get_parent() != null else self
	parent_node.add_child(slam_fx)

	# Quick expanding dust ring
	var tween := slam_fx.create_tween()
	if tween != null:
		var mat_draw := func():
			slam_fx.draw_circle(Vector2.ZERO, 65.0, Color(0.8, 0.4, 0.1, 0.4))
			slam_fx.draw_arc(Vector2.ZERO, 65.0, 0, TAU, 32, Color(1.0, 0.6, 0.2, 0.8), 3.0)
		slam_fx.draw.connect(mat_draw)
		slam_fx.queue_redraw()
		tween.tween_property(slam_fx, "modulate:a", 0.0, 0.35)
		tween.tween_callback(slam_fx.queue_free)
	else:
		slam_fx.queue_free()

func _spawn_magma_pool() -> void:
	var parent_node := get_parent() if get_parent() != null else self
	var pool := IgnisMagmaPool.new(global_position)
	parent_node.add_child(pool)

## Helper class for Magma Trails (Phase 2)
class IgnisMagmaPool extends Area2D:
	var lifetime: float = 4.0
	var tick_timer: float = 0.0
	var dps: float = 12.0
	var pool_radius: float = 24.0

	func _init(pos: Vector2) -> void:
		global_position = pos
		collision_layer = 16 # EnemyAttacks
		collision_mask = 66  # Player (2) | Companion (64)
		monitoring = true

	func _ready() -> void:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = pool_radius
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
			_apply_tick()

	func _apply_tick() -> void:
		for area in get_overlapping_areas():
			var hurt := area as HurtboxComponent
			if hurt != null and (hurt.team_index == 0 or hurt.collision_layer == 2 or hurt.collision_layer == 64):
				var data := DamageData.new(dps * 0.5, DamageData.DamageType.FIRE, 0.0, Vector2.ZERO, null)
				hurt.receive_hit(data)

	func _draw() -> void:
		draw_circle(Vector2.ZERO, pool_radius, Color(0.9, 0.3, 0.05, 0.45 * clampf(lifetime, 0.0, 1.0)))
		draw_arc(Vector2.ZERO, pool_radius, 0, TAU, 16, Color(1.0, 0.6, 0.1, 0.6 * clampf(lifetime, 0.0, 1.0)), 2.0)

## Helper class for Flame Fan Projectiles
class IgnisFlameProjectile extends Area2D:
	var velocity: Vector2 = Vector2.ZERO
	var damage: float = 18.0
	var lifetime: float = 2.5
	var speed: float = 220.0

	func _init(start_pos: Vector2, dir: Vector2, dmg: float) -> void:
		global_position = start_pos
		velocity = dir.normalized() * speed
		damage = dmg
		collision_layer = 16 # EnemyAttacks
		collision_mask = 66  # Player (2) | Companion (64)
		monitoring = true

	func _ready() -> void:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 7.0
		shape.shape = circle
		add_child(shape)
		area_entered.connect(_on_area_entered)

	func _physics_process(delta: float) -> void:
		global_position += velocity * delta
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()

	func _on_area_entered(area: Area2D) -> void:
		var hurt := area as HurtboxComponent
		if hurt != null and hurt.team_index == 0:
			var data := DamageData.new(damage, DamageData.DamageType.FIRE, 60.0, velocity.normalized(), null)
			hurt.receive_hit(data)
			queue_free()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.4, 0.1, 0.9))
		draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.2, 1.0))

## Helper class for Major Eruption Shockwave Rings
class IgnisShockwaveRing extends Area2D:
	var damage: float = 35.0
	var delay: float = 0.0
	var current_radius: float = 10.0
	var max_radius: float = 220.0
	var expand_speed: float = 180.0
	var hit_targets: Array[Node] = []

	func _init(pos: Vector2, dmg: float, p_delay: float) -> void:
		global_position = pos
		damage = dmg
		delay = p_delay
		collision_layer = 16
		collision_mask = 66
		monitoring = true

	func _ready() -> void:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 15.0
		shape.shape = circle
		add_child(shape)
		area_entered.connect(_on_area_entered)

	func _physics_process(delta: float) -> void:
		if delay > 0.0:
			delay -= delta
			return

		current_radius += expand_speed * delta
		var col_shape := get_child(0) as CollisionShape2D
		if col_shape != null and col_shape.shape is CircleShape2D:
			(col_shape.shape as CircleShape2D).radius = current_radius

		queue_redraw()

		if current_radius >= max_radius:
			queue_free()

	func _on_area_entered(area: Area2D) -> void:
		if delay > 0.0:
			return
		var hurt := area as HurtboxComponent
		if hurt != null and hurt.team_index == 0 and not hit_targets.has(hurt):
			hit_targets.append(hurt)
			var kb_dir := (hurt.global_position - global_position).normalized()
			var data := DamageData.new(damage, DamageData.DamageType.FIRE, 140.0, kb_dir, null)
			hurt.receive_hit(data)

	func _draw() -> void:
		if delay <= 0.0:
			var alpha: float = 1.0 - (current_radius / max_radius)
			draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, Color(1.0, 0.35, 0.1, alpha), 4.0)
