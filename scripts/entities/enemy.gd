class_name Enemy
extends CharacterBody2D

enum EnemyType { SKELETON, SLIME, BAT, DEMON_BOSS, RANGED, MIMIC }

@export var enemy_type: EnemyType = EnemyType.SKELETON
@export var base_speed: float = 70.0
@export var max_health: float = 30.0
@export var contact_damage: float = 10.0
@export var xp_reward: int = 1

var _current_speed: float = 70.0
var _target: Node2D = null
var _knockback_velocity: Vector2 = Vector2.ZERO
var _is_dying: bool = false
var _stun_timer: float = 0.0
var _slow_timer: float = 0.0
var _slow_factor: float = 0.0
var _slime_jump_timer: float = 0.0

# Attack variables
enum AttackState { IDLE, TELEGRAPH, ATTACKING, COOLDOWN }
var _attack_state: AttackState = AttackState.IDLE
var _attack_timer: float = 0.0
var _mimic_awake: bool = false

# Behavior & Monster Dialect states
enum BehaviorState { ADVANCING, ATTACKING, RETREATING_FOR_HELP, FRENZY }
var behavior_state: BehaviorState = BehaviorState.ADVANCING
var _frenzy_timer: float = 0.0
var _original_modulate: Color = Color.WHITE

const DIALECTS_PANIC: Array[String] = [
	"*SKRR-KZZT! Ghol'mak!*",
	"*URK-GRAA! MASH'DAR!*",
	"*KREEE! NOK-ZHOR!*",
	"*SSHHH-KLIK! VHO'TOR!*"
]

const DIALECTS_FRENZY: Array[String] = [
	"*VHOR-KASH!*",
	"*DRAK-ZUL!*",
	"*THOR'GAT!*",
	"*GRAAAGH-ZOR!*"
]

const DIALECTS_TACTICAL: Array[String] = [
	"*Tzk-tzk... Zhor'el!*",
	"*Kzzz-kzzz!*",
	"*Mor'gath!*"
]

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent

var xp_gem_scene: PackedScene = preload("res://scenes/entities/xp_gem/xp_gem.tscn")

func _ready() -> void:
	add_to_group("enemies")
	_setup_type_attributes()
	_current_speed = base_speed

	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.took_damage.connect(_on_took_damage)
	health_component.died.connect(_on_died)

	hitbox_component.damage_amount = contact_damage
	hitbox_component.damage_type = DamageData.DamageType.PHYSICAL
	hitbox_component.team_index = 1 # Enemy team
	hitbox_component.periodic_damage = true
	hitbox_component.tick_interval = 0.4
	hitbox_component.set_deferred("monitoring", false)

	hurtbox_component.team_index = 1
	hurtbox_component.health_component = health_component

	_find_target()

func set_type(type: EnemyType) -> void:
	enemy_type = type
	if is_node_ready():
		_setup_type_attributes()

func apply_stun(duration: float) -> void:
	_stun_timer = maxf(_stun_timer, duration)
	velocity = Vector2.ZERO

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = maxf(_slow_factor, factor)
	_slow_timer = maxf(_slow_timer, duration)

func _setup_type_attributes() -> void:
	match enemy_type:
		EnemyType.SKELETON:
			base_speed = 70.0
			max_health = 35.0
			contact_damage = 10.0
			xp_reward = 1
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0087.png")
			scale = Vector2.ONE
			modulate = Color.WHITE
		EnemyType.SLIME:
			base_speed = 52.0
			max_health = 25.0
			contact_damage = 8.0
			xp_reward = 1
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0108.png")
			scale = Vector2.ONE
			modulate = Color(0.6, 1.0, 0.6)
		EnemyType.BAT:
			base_speed = 115.0
			max_health = 16.0
			contact_damage = 6.0
			xp_reward = 1
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0120.png")
			scale = Vector2.ONE
			modulate = Color(0.9, 0.5, 0.9)
		EnemyType.DEMON_BOSS:
			base_speed = 65.0
			max_health = 320.0
			contact_damage = 25.0
			xp_reward = 15
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0111.png")
			scale = Vector2(1.8, 1.8)
			modulate = Color(1.0, 0.4, 0.4)
		EnemyType.RANGED:
			base_speed = 60.0
			max_health = 22.0
			contact_damage = 4.0
			xp_reward = 1
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0093.png")
			scale = Vector2.ONE
			modulate = Color.WHITE
		EnemyType.MIMIC:
			base_speed = 100.0
			max_health = 45.0
			contact_damage = 15.0
			xp_reward = 3
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0089.png")
			scale = Vector2.ONE
			modulate = Color.WHITE

	var tree := get_tree()
	if tree != null and tree.root != null:
		var gm = tree.root.get_node_or_null("GameManager")
		if gm != null:
			var hp_mult: float = gm.boss_health_mult if enemy_type == EnemyType.DEMON_BOSS else gm.enemy_health_mult
			var dmg_mult: float = gm.boss_damage_mult if enemy_type == EnemyType.DEMON_BOSS else gm.enemy_damage_mult
			var spd_mult: float = gm.enemy_speed_mult
			max_health *= hp_mult
			contact_damage *= dmg_mult
			base_speed *= spd_mult

	_current_speed = base_speed
	if health_component != null:
		health_component.max_health = max_health
		health_component.current_health = max_health
	if hitbox_component != null:
		hitbox_component.damage_amount = contact_damage
		if enemy_type == EnemyType.SLIME or enemy_type == EnemyType.DEMON_BOSS or enemy_type == EnemyType.RANGED:
			hitbox_component.set_deferred("monitoring", true)
		else:
			hitbox_component.set_deferred("monitoring", false)
	_original_modulate = modulate

func speak_dialect(text: String, bubble_color: Color = Color(1.0, 0.4, 0.4)) -> void:
	if not is_inside_tree():
		return
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", bubble_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.position = Vector2(-50, -28)
	label.custom_minimum_size = Vector2(100, 16)
	label.z_index = 25
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 14.0, 1.1)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.1).set_delay(0.4)
	tween.tween_callback(label.queue_free)

	var is_flee = (behavior_state == BehaviorState.RETREATING_FOR_HELP)
	if EventBus != null and EventBus.has_signal("monster_shriek"):
		EventBus.emit_monster_shriek(global_position, text, is_flee)

func trigger_frenzy() -> void:
	if _is_dying or enemy_type == EnemyType.DEMON_BOSS or behavior_state == BehaviorState.RETREATING_FOR_HELP:
		return
	behavior_state = BehaviorState.FRENZY
	_frenzy_timer = 3.5
	modulate = Color(1.4, 0.5, 0.5)
	speak_dialect(DIALECTS_FRENZY[randi() % DIALECTS_FRENZY.size()], Color(1.0, 0.3, 0.3))

func trigger_retreat_for_help() -> void:
	if _is_dying or enemy_type == EnemyType.DEMON_BOSS or behavior_state == BehaviorState.RETREATING_FOR_HELP:
		return
	behavior_state = BehaviorState.RETREATING_FOR_HELP
	modulate = Color(0.7, 0.9, 1.3)
	speak_dialect(DIALECTS_PANIC[randi() % DIALECTS_PANIC.size()], Color(0.4, 0.9, 1.0))

func _find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0] as Node2D

func _has_line_of_sight(target_node: Node2D) -> bool:
	if not is_inside_tree():
		return false
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target_node.global_position)
	query.collision_mask = 1 # World layer
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func _physics_process(delta: float) -> void:
	if _is_dying:
		return

	# Handle stun
	if _stun_timer > 0.0:
		_stun_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Handle slow decay
	if _slow_timer > 0.0:
		_slow_timer -= delta
		_current_speed = base_speed * (1.0 - _slow_factor)
	else:
		_slow_factor = 0.0
		_current_speed = base_speed

	# Decay knockback
	if _knockback_velocity.length_squared() > 10.0:
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		velocity = _knockback_velocity
		move_and_slide()
		return

	if _target == null or not is_instance_valid(_target):
		_find_target()
		return

	var direction := (_target.global_position - global_position).normalized()
	var distance := global_position.distance_to(_target.global_position)

	# Flee state: run away from target and try to escape to call the boss!
	if behavior_state == BehaviorState.RETREATING_FOR_HELP:
		var retreat_dir := -direction
		velocity = retreat_dir * (_current_speed * 1.35)
		move_and_slide()
		if retreat_dir.x != 0.0:
			sprite.flip_h = retreat_dir.x < 0.0

		# Check if escaped off the arena bounds to call boss
		if abs(global_position.x) >= 540.0 or abs(global_position.y) >= 350.0:
			if EventBus != null and EventBus.has_signal("enemy_escaped_calling_boss"):
				EventBus.emit_enemy_escaped_calling_boss(global_position)
			set_physics_process(false)
			var esc_tween := create_tween()
			esc_tween.tween_property(self, "modulate:a", 0.0, 0.2)
			esc_tween.tween_callback(queue_free)
			return
		return

	# Frenzy state duration decay & speed boost
	if behavior_state == BehaviorState.FRENZY:
		_frenzy_timer -= delta
		_current_speed = base_speed * 1.25
		if _frenzy_timer <= 0.0:
			behavior_state = BehaviorState.ADVANCING
			modulate = _original_modulate
			_current_speed = base_speed

	if enemy_type == EnemyType.SLIME or enemy_type == EnemyType.DEMON_BOSS:
		if enemy_type == EnemyType.SLIME:
			_slime_jump_timer -= delta
			if _slime_jump_timer <= 0.0:
				_knockback_velocity = direction * (_current_speed * 4.0)
				_slime_jump_timer = 1.5
			velocity = Vector2.ZERO
		else:
			velocity = direction * _current_speed
		move_and_slide()
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		return

	# State machine for attackers (SKELETON, BAT, MIMIC)
	if enemy_type == EnemyType.RANGED:
		# Ranged has its own class extending Enemy and overriding physics process
		pass
	else:
		match _attack_state:
			AttackState.IDLE:
				if enemy_type == EnemyType.MIMIC and not _mimic_awake:
					velocity = Vector2.ZERO
					if distance < 60.0:
						_mimic_awake = true
						sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0091.png")
						_attack_state = AttackState.TELEGRAPH
						_attack_timer = 0.4
				elif distance < 45.0 and (enemy_type == EnemyType.SKELETON or enemy_type == EnemyType.MIMIC):
					velocity = Vector2.ZERO
					_attack_state = AttackState.TELEGRAPH
					_attack_timer = 0.5
				elif distance < 80.0 and enemy_type == EnemyType.BAT:
					velocity = Vector2.ZERO
					_attack_state = AttackState.TELEGRAPH
					_attack_timer = 0.6
				else:
					if enemy_type == EnemyType.MIMIC and not _mimic_awake:
						velocity = Vector2.ZERO
					else:
						velocity = direction * _current_speed
			AttackState.TELEGRAPH:
				velocity = Vector2.ZERO
				_attack_timer -= delta

				# Telegraphing visuals
				if enemy_type == EnemyType.BAT:
					sprite.rotation = sin(Time.get_ticks_msec() * 0.05) * 0.2
				elif enemy_type == EnemyType.SKELETON or enemy_type == EnemyType.MIMIC:
					sprite.position.y = -2.0 if int(Time.get_ticks_msec() * 0.01) % 2 == 0 else 0.0

				if _attack_timer <= 0.0:
					_attack_state = AttackState.ATTACKING
					sprite.rotation = 0.0
					sprite.position.y = 0.0
					hitbox_component.set_deferred("monitoring", true)

					if enemy_type == EnemyType.BAT or enemy_type == EnemyType.MIMIC:
						_knockback_velocity = direction * (_current_speed * (5.0 if enemy_type == EnemyType.BAT else 6.0))
						_attack_timer = 0.3
					else:
						# SKELETON LUNGE
						_knockback_velocity = direction * (_current_speed * 2.0)
						_attack_timer = 0.2

					var tween := create_tween()
					tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.05)
					tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)

			AttackState.ATTACKING:
				_attack_timer -= delta
				if _attack_timer <= 0.0:
					hitbox_component.set_deferred("monitoring", false)
					_attack_state = AttackState.COOLDOWN
					_attack_timer = 1.0 if enemy_type == EnemyType.SKELETON else 1.5

			AttackState.COOLDOWN:
				_attack_timer -= delta
				if enemy_type == EnemyType.MIMIC and not _mimic_awake:
					velocity = Vector2.ZERO
				else:
					velocity = direction * (_current_speed * 0.5) # Move slower during cooldown
				if _attack_timer <= 0.0:
					_attack_state = AttackState.IDLE

	move_and_slide()

	if direction.x != 0.0 and _attack_state != AttackState.TELEGRAPH:
		sprite.flip_h = direction.x < 0.0

func _on_took_damage(data: DamageData) -> void:
	if _is_dying:
		return

	# Apply knockback
	if data != null:
		_knockback_velocity = data.get_knockback_velocity()

	# Hit flash effect (instance uniform)
	sprite.set_instance_shader_parameter("flash_modifier", 1.0)
	get_tree().create_timer(0.08).timeout.connect(func():
		if is_instance_valid(sprite):
			sprite.set_instance_shader_parameter("flash_modifier", 0.0)
	)

	# Squish punch animation
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.05)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.08)

	# Dynamic Retreat/Panic trigger if HP gets critical (< 38%)
	if not _is_dying and enemy_type != EnemyType.DEMON_BOSS and behavior_state != BehaviorState.RETREATING_FOR_HELP:
		if health_component.current_health <= max_health * 0.38:
			if randf() < 0.50:
				trigger_retreat_for_help()

func _on_died() -> void:
	if _is_dying:
		return
	_is_dying = true

	# Nearby allies chain reaction (frenzy or panic)
	var tree := get_tree()
	if tree != null:
		var allies := tree.get_nodes_in_group("enemies")
		for ally in allies:
			if ally != self and is_instance_valid(ally) and ally is Enemy and not ally._is_dying:
				if ally.global_position.distance_to(global_position) <= 130.0:
					if ally.health_component.current_health <= ally.max_health * 0.35:
						if randf() < 0.45:
							ally.trigger_retreat_for_help()
					elif ally.behavior_state == BehaviorState.ADVANCING:
						if randf() < 0.35:
							ally.trigger_frenzy()

	# Intercepted bonus if minion was running away to call boss!
	if behavior_state == BehaviorState.RETREATING_FOR_HELP:
		xp_reward += 2
		if tree != null and tree.root != null:
			var gm = tree.root.get_node_or_null("GameManager")
			if gm != null and gm.has_method("add_gold"):
				gm.call("add_gold", 4)

	if enemy_type == EnemyType.DEMON_BOSS:
		EventBus.emit_boss_died("Demônio Abissal", global_position)

	EventBus.emit_enemy_died(global_position, xp_reward)
	EventBus.emit_entity_died(self, global_position)


	# Drop XP gem
	if xp_gem_scene != null:
		var gem := xp_gem_scene.instantiate() as XPGem
		if gem != null:
			gem.xp_value = xp_reward
			gem.global_position = global_position
			get_parent().call_deferred("add_child", gem)

	# Death dissolve tween
	set_physics_process(false)
	hitbox_component.set_deferred("monitoring", false)
	hitbox_component.set_deferred("monitorable", false)
	hurtbox_component.set_deferred("monitorable", false)

	var death_tween := create_tween()
	death_tween.tween_property(self, "scale", Vector2(1.4, 0.2), 0.12)
	death_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	death_tween.tween_callback(queue_free)
