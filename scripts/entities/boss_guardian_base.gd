class_name BossGuardianBase
extends CharacterBody2D

## Base class for Elemental Guardian Bosses in "Shadow Cheat: Solo Guild Ascendance".
## Features a 2-phase combat FSM, Leyline shield mitigation (90% reduction),
## visual attack telegraphing system, and Leyline Overload stun interruption.

signal phase_changed(new_phase: int)
signal stunned(duration: float)
signal attack_started(attack_name: String)
signal attack_finished(attack_name: String)
signal boss_defeated(boss_name: String)

enum BossState {
	IDLE,
	CHASE,
	TELEGRAPH,
	ATTACK,
	STUNNED,
	PHASE_TRANSITION,
	DEAD
}

@export_group("Boss Profile")
@export var boss_name: String = "Guardian Boss"
@export var max_health: float = 650.0
@export var current_health: float = 650.0
@export var base_speed: float = 55.0
@export var phase_2_speed_multiplier: float = 1.3
@export var contact_damage: float = 20.0
@export var attack_range: float = 140.0
@export var attack_cooldown: float = 3.0

@export_group("Leyline Shield")
@export var has_active_leylines: bool = true
@export var leyline_mitigation: float = 0.90

var current_phase: int = 1
var current_state: BossState = BossState.IDLE
var is_stunned: bool = false
var is_dead: bool = false
var stun_timer: float = 0.0
var state_timer: float = 0.0
var attack_cooldown_timer: float = 1.5

var target: Node2D = null
var current_attack_name: String = ""

var health_component: HealthComponent = null
var hurtbox_component: HurtboxComponent = null
var hitbox_component: HitboxComponent = null
var sprite: Sprite2D = null
var collision_shape: CollisionShape2D = null
var telegraph_node: Node2D = null

func _init() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_setup_components()

func _ready() -> void:
	collision_layer = 4 # Layer 3: Enemies
	collision_mask = 7  # Layer 1 (World) | Layer 2 (Player) | Layer 3 (Enemies)
	add_to_group("enemies")
	add_to_group("bosses")

	var tree := get_tree()
	if tree != null and tree.root != null:
		var gm = tree.root.get_node_or_null("GameManager")
		if gm != null:
			max_health *= gm.boss_health_mult
			current_health = max_health
			contact_damage *= gm.boss_damage_mult
			base_speed *= 1.10
			attack_cooldown = maxf(1.8, attack_cooldown * 0.85)

	_setup_components()
	set_leyline_mitigation(has_active_leylines)
	_find_target()

func _setup_components() -> void:
	if health_component == null:
		health_component = get_node_or_null("HealthComponent") as HealthComponent
	if health_component == null:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		add_child(health_component)

	health_component.max_health = max_health
	health_component.current_health = max_health
	current_health = max_health
	health_component.external_damage_mitigation = leyline_mitigation if has_active_leylines else 0.0

	if not health_component.took_damage.is_connected(_on_took_damage):
		health_component.took_damage.connect(_on_took_damage)
	if not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)

	if hurtbox_component == null:
		hurtbox_component = get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox_component == null:
		hurtbox_component = HurtboxComponent.new()
		hurtbox_component.name = "HurtboxComponent"
		hurtbox_component.collision_layer = 4 # Enemies
		hurtbox_component.collision_mask = 8  # PlayerAttacks
		hurtbox_component.team_index = 1
		var hurt_shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		hurt_shape.shape = circle
		hurtbox_component.add_child(hurt_shape)
		add_child(hurtbox_component)

	hurtbox_component.health_component = health_component
	hurtbox_component.team_index = 1

	if hitbox_component == null:
		hitbox_component = get_node_or_null("HitboxComponent") as HitboxComponent
	if hitbox_component == null:
		hitbox_component = HitboxComponent.new()
		hitbox_component.name = "HitboxComponent"
		hitbox_component.collision_layer = 16 # EnemyAttacks
		hitbox_component.collision_mask = 66  # Player (2) | Companion (64)
		hitbox_component.damage_amount = contact_damage
		hitbox_component.team_index = 1
		hitbox_component.periodic_damage = true
		hitbox_component.tick_interval = 0.4
		var hit_shape := CollisionShape2D.new()
		var hit_circle := CircleShape2D.new()
		hit_circle.radius = 14.0
		hit_shape.shape = hit_circle
		hitbox_component.add_child(hit_shape)
		add_child(hitbox_component)

	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var body_shape := CircleShape2D.new()
		body_shape.radius = 12.0
		collision_shape.shape = body_shape
		add_child(collision_shape)

	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)

func set_leyline_mitigation(active: bool) -> void:
	has_active_leylines = active
	if health_component != null:
		health_component.external_damage_mitigation = leyline_mitigation if active else 0.0

func apply_leyline_overload(duration: float = 4.0) -> void:
	# If boss is already dead, cleanly no-ops without error (T2.EXP.18)
	if is_dead or (health_component != null and not health_component.is_alive()):
		return

	# Break leyline shield mitigation
	set_leyline_mitigation(false)

	# If already stunned, do not stack/extend stun timer (T2.EXP.21)
	if is_stunned:
		return

	# Interrupt current attack and cancel telegraphs
	_cancel_telegraph()

	# Apply 100 direct overload damage (ignoring mitigation and i-frames)
	if health_component != null:
		health_component.is_invincible = false
		health_component.set("_i_frame_timer", 0.0)
		var prev_mit := health_component.external_damage_mitigation
		health_component.external_damage_mitigation = 0.0
		var overload_data := DamageData.new(100.0, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null)
		health_component.take_damage(overload_data)
		current_health = health_component.current_health
		health_component.external_damage_mitigation = 0.0

	# If this burst kills the boss, transition immediately to death
	if current_health <= 0.0 or is_dead:
		return

	# Enter stunned state
	is_stunned = true
	stun_timer = duration
	velocity = Vector2.ZERO
	_change_state(BossState.STUNNED)
	stunned.emit(duration)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_target_tracking()

	match current_state:
		BossState.IDLE:
			_process_idle(delta)
		BossState.CHASE:
			_process_chase(delta)
		BossState.TELEGRAPH:
			_process_telegraph(delta)
		BossState.ATTACK:
			_process_attack(delta)
		BossState.STUNNED:
			_process_stunned(delta)
		BossState.PHASE_TRANSITION:
			_process_phase_transition(delta)
		BossState.DEAD:
			pass

	move_and_slide()

func _process_idle(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	attack_cooldown_timer -= delta
	if target != null and is_instance_valid(target):
		_change_state(BossState.CHASE)

func _process_chase(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_find_target()
		if target == null:
			_change_state(BossState.IDLE)
			return

	var dist_to_target := global_position.distance_to(target.global_position)
	var dir := (target.global_position - global_position).normalized()
	
	var effective_speed := base_speed * (phase_2_speed_multiplier if current_phase == 2 else 1.0)
	velocity = dir * effective_speed

	if sprite != null and dir.x != 0.0:
		sprite.flip_h = dir.x < 0.0

	attack_cooldown_timer -= delta
	if dist_to_target <= attack_range and attack_cooldown_timer <= 0.0:
		_select_and_start_attack()

func _process_telegraph(delta: float) -> void:
	velocity = Vector2.ZERO
	state_timer -= delta

	if telegraph_node != null and telegraph_node.has_method("set_progress"):
		var total_dur: float = telegraph_node.get("total_duration") if telegraph_node.get("total_duration") != null else 1.0
		var progress: float = 1.0 - clampf(state_timer / maxf(total_dur, 0.001), 0.0, 1.0)
		telegraph_node.call("set_progress", progress)

	if state_timer <= 0.0:
		_execute_attack()

func _process_attack(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_finish_attack()

func _process_stunned(delta: float) -> void:
	velocity = Vector2.ZERO
	stun_timer -= delta
	if stun_timer <= 0.0:
		is_stunned = false
		stun_timer = 0.0
		_change_state(BossState.CHASE)

func _process_phase_transition(delta: float) -> void:
	velocity = Vector2.ZERO
	state_timer -= delta
	if state_timer <= 0.0:
		current_phase = 2
		phase_changed.emit(2)
		_on_phase_2_entered()
		_change_state(BossState.CHASE)

func _change_state(new_state: BossState) -> void:
	current_state = new_state

func _select_and_start_attack() -> void:
	# Virtual method overridden by child boss classes (Ignis, Glacies)
	pass

func _start_telegraph(attack_name: String, duration: float, indicator_node: Node2D) -> void:
	current_attack_name = attack_name
	state_timer = duration
	_cancel_telegraph()
	telegraph_node = indicator_node
	if telegraph_node != null:
		add_child(telegraph_node)
	_change_state(BossState.TELEGRAPH)
	attack_started.emit(attack_name)

func _cancel_telegraph() -> void:
	if telegraph_node != null and is_instance_valid(telegraph_node):
		telegraph_node.queue_free()
		telegraph_node = null

func _execute_attack() -> void:
	_cancel_telegraph()
	_change_state(BossState.ATTACK)
	# Virtual method implemented in subclasses

func _finish_attack() -> void:
	attack_cooldown_timer = attack_cooldown * (0.8 if current_phase == 2 else 1.0)
	attack_finished.emit(current_attack_name)
	current_attack_name = ""
	_change_state(BossState.CHASE)

func _start_phase_transition() -> void:
	_cancel_telegraph()
	current_state = BossState.PHASE_TRANSITION
	state_timer = 1.2 # Dramatic transition pause

	# Visual transition flash / flare
	if sprite != null and is_inside_tree():
		var orig_mod := sprite.modulate
		sprite.modulate = Color(2.0, 1.2, 0.4, 1.0)
		var tree := get_tree()
		if tree != null:
			var tween := tree.create_tween()
			if tween != null:
				tween.tween_property(sprite, "modulate", orig_mod, 1.2)

func _on_phase_2_entered() -> void:
	# Subclasses customize Phase 2 enrage buffs / behaviors
	pass

func _on_took_damage(data: DamageData) -> void:
	if is_dead:
		return

	current_health = health_component.current_health

	# Massive overkill check (T2.EXP.19): Transitions directly to clean death
	if current_health <= 0.0:
		_die()
		return

	# Phase 2 transition trigger at <= 50% HP
	if current_phase == 1 and current_health <= (max_health * 0.50):
		_start_phase_transition()

	# Hit flash
	if sprite != null and is_inside_tree():
		var orig_color := sprite.modulate
		sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
		var tree := get_tree()
		if tree != null:
			var tween := tree.create_tween()
			if tween != null:
				tween.tween_property(sprite, "modulate", orig_color, 0.1)

func _on_died() -> void:
	_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	current_health = 0.0
	_change_state(BossState.DEAD)
	_cancel_telegraph()

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if hitbox_component != null:
		hitbox_component.set_deferred("monitoring", false)
		hitbox_component.set_deferred("monitorable", false)
	if hurtbox_component != null:
		hurtbox_component.set_deferred("monitoring", false)
		hurtbox_component.set_deferred("monitorable", false)

	boss_defeated.emit(boss_name)
	var tree := get_tree() if is_inside_tree() else Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var eb = tree.root.get_node_or_null("EventBus")
		if eb != null and eb.has_method("emit_boss_died"):
			eb.emit_boss_died(boss_name, global_position)

	# Death fade out
	if sprite != null and is_inside_tree():
		var tree_inst := get_tree()
		if tree_inst != null:
			var tween := tree_inst.create_tween()
			if tween != null:
				tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
				tween.tween_callback(queue_free)
				return
	queue_free()

func _find_target() -> void:
	var tree := get_tree() if is_inside_tree() else Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var players := tree.get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0] as Node2D
		return
	var allies := tree.get_nodes_in_group("allies")
	if allies.size() > 0:
		target = allies[0] as Node2D

func _update_target_tracking() -> void:
	if target == null or not is_instance_valid(target):
		_find_target()

## Telegraph Indicator helper class for geometric warnings
class TelegraphVisual extends Node2D:
	enum Type { CIRCLE, RECTANGLE, CONE }
	var shape_type: Type = Type.CIRCLE
	var total_duration: float = 1.0
	var progress: float = 0.0
	var radius: float = 65.0
	var rect_size: Vector2 = Vector2(240.0, 24.0)
	var cone_angle: float = deg_to_rad(60.0)
	var target_direction: Vector2 = Vector2.RIGHT

	func _init(p_type: Type = Type.CIRCLE, p_duration: float = 1.0) -> void:
		shape_type = p_type
		total_duration = p_duration

	func set_progress(p_val: float) -> void:
		progress = clampf(p_val, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var border_color := Color(1.0, 0.15, 0.15, 0.5)
		var fill_color := Color(1.0, 0.2, 0.2, 0.15 + (0.4 * progress))

		match shape_type:
			Type.CIRCLE:
				draw_circle(Vector2.ZERO, radius, fill_color)
				draw_arc(Vector2.ZERO, radius, 0, TAU, 32, border_color, 2.0)
				# Inner charging expanding wave
				draw_circle(Vector2.ZERO, radius * progress, Color(1.0, 0.3, 0.1, 0.35))

			Type.RECTANGLE:
				var half_w := rect_size.x
				var half_h := rect_size.y * 0.5
				var rect := Rect2(0, -half_h, half_w, rect_size.y)
				draw_rect(rect, fill_color)
				draw_rect(rect, border_color, false, 2.0)
				# Charging fill bar
				var charge_rect := Rect2(0, -half_h, half_w * progress, rect_size.y)
				draw_rect(charge_rect, Color(1.0, 0.3, 0.1, 0.4))

			Type.CONE:
				var points: PackedVector2Array = [Vector2.ZERO]
				var num_segments := 16
				var start_ang := -cone_angle * 0.5
				for i in range(num_segments + 1):
					var ang := start_ang + (cone_angle * (float(i) / float(num_segments)))
					points.append(Vector2(cos(ang), sin(ang)) * radius)
				draw_colored_polygon(points, fill_color)
				for i in range(1, points.size()):
					draw_line(points[i - 1], points[i], border_color, 2.0)
				draw_line(points[points.size() - 1], Vector2.ZERO, border_color, 2.0)
