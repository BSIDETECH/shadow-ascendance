class_name Enemy
extends CharacterBody2D

enum EnemyType { SKELETON, SLIME, BAT, DEMON_BOSS, RANGED }

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
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0089.png")
			scale = Vector2.ONE
			modulate = Color.WHITE
		EnemyType.SLIME:
			base_speed = 52.0
			max_health = 25.0
			contact_damage = 8.0
			xp_reward = 1
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0093.png")
			scale = Vector2.ONE
			modulate = Color(0.6, 1.0, 0.6)
		EnemyType.BAT:
			base_speed = 115.0
			max_health = 16.0
			contact_damage = 6.0
			xp_reward = 1
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0092.png")
			scale = Vector2.ONE
			modulate = Color(0.9, 0.5, 0.9)
		EnemyType.DEMON_BOSS:
			base_speed = 65.0
			max_health = 320.0
			contact_damage = 25.0
			xp_reward = 15
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0108.png")
			scale = Vector2(1.8, 1.8)
			modulate = Color(1.0, 0.4, 0.4)
		EnemyType.RANGED:
			base_speed = 60.0
			max_health = 22.0
			contact_damage = 4.0
			xp_reward = 1
			sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0088.png")
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
	velocity = direction * _current_speed
	move_and_slide()

	# Flip sprite based on movement
	if direction.x != 0.0:
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

func _on_died() -> void:
	if _is_dying:
		return
	_is_dying = true
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
