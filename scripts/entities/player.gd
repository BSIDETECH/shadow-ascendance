class_name Player
extends CharacterBody2D

signal dashed(direction: Vector2)

@export var base_speed: float = 140.0
@export var dash_speed: float = 380.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.75
@export var attack_cooldown: float = 0.28
@export var base_damage: float = 22.0
@export var can_attack: bool = true
@export var combat_enabled: bool = true

# Upgradable modifiers via Gacha
var damage_mult: float = 1.0
var attack_speed_mult: float = 1.0
var move_speed_mult: float = 1.0
var dash_cooldown_mult: float = 1.0
var pickup_radius: float = 120.0
var lifesteal_on_kill: float = 0.0
var abyssal_burst_unlocked: bool = false
var fire_pulse_unlocked: bool = false
var _fire_pulse_timer: float = 0.0
var executioner_unlocked: bool = false
var kill_counter: int = 0
@export var weapon_unlocked: bool = false # Starts unarmed: single-target punch ("soquinho")

# Geometries for Punch (unarmed) vs Shadow Blades (weapon unlocked)
static var PUNCH_POLYGON := PackedVector2Array([
	Vector2(4, -5), Vector2(18, -4), Vector2(22, 0), Vector2(18, 4), Vector2(4, 5)
])
static var WEAPON_POLYGON := PackedVector2Array([
	Vector2(0, -16), Vector2(28, -22), Vector2(44, 0), Vector2(28, 22), Vector2(0, 16), Vector2(20, 0)
])

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cd_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _attack_timer: float = 0.0
var _last_move_dir: Vector2 = Vector2.RIGHT

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var slash_pivot: Node2D = $SlashPivot
@onready var slash_hitbox: HitboxComponent = $SlashPivot/SlashHitbox
@onready var slash_visual: Polygon2D = $SlashPivot/SlashVisual
@onready var slash_collision: CollisionPolygon2D = $SlashPivot/SlashHitbox/CollisionPolygon2D
@onready var magnet_area: Area2D = $MagnetArea

func _ready() -> void:
	add_to_group("player")
	
	health_component.max_health = 100.0
	health_component.current_health = 100.0
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	
	hurtbox_component.team_index = 0
	hurtbox_component.health_component = health_component
	
	slash_hitbox.team_index = 0
	slash_hitbox.damage_amount = base_damage
	slash_hitbox.damage_type = DamageData.DamageType.PHYSICAL if not weapon_unlocked else DamageData.DamageType.DARK
	slash_hitbox.monitoring = false
	slash_visual.visible = false
	_apply_weapon_mode()
	
	EventBus.enemy_died.connect(_on_enemy_killed)
	_update_magnet_radius()

func unlock_weapon() -> void:
	weapon_unlocked = true
	_apply_weapon_mode()

func _apply_weapon_mode() -> void:
	if slash_collision != null:
		slash_collision.polygon = WEAPON_POLYGON if weapon_unlocked else PUNCH_POLYGON
	if slash_visual != null:
		slash_visual.polygon = WEAPON_POLYGON if weapon_unlocked else PUNCH_POLYGON
	if slash_hitbox != null:
		slash_hitbox.damage_type = DamageData.DamageType.DARK if weapon_unlocked else DamageData.DamageType.PHYSICAL

func _physics_process(delta: float) -> void:
	_handle_timers(delta)
	_handle_aim()
	_handle_movement(delta)
	_handle_combat()
	_handle_fire_pulse(delta)
	_attract_nearby_gems()

func _handle_timers(delta: float) -> void:
	if _dash_cd_timer > 0.0:
		_dash_cd_timer -= delta
	if _attack_timer > 0.0:
		_attack_timer -= delta

	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_end_dash()

func _handle_aim() -> void:
	var mouse_pos := get_global_mouse_position()
	var aim_dir := (mouse_pos - global_position).normalized()
	slash_pivot.rotation = aim_dir.angle()

func _handle_movement(delta: float) -> void:
	if _is_dashing:
		velocity = _dash_direction * dash_speed
		move_and_slide()
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		_last_move_dir = input_vector.normalized()
		velocity = input_vector * (base_speed * move_speed_mult)
		sprite.flip_h = input_vector.x < 0.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)

	move_and_slide()

	# Dash execution
	if Input.is_action_just_pressed("dash") and _dash_cd_timer <= 0.0 and not _is_dashing:
		_start_dash()

func _start_dash() -> void:
	_is_dashing = true
	_dash_direction = _last_move_dir
	_dash_timer = dash_duration
	_dash_cd_timer = dash_cooldown * dash_cooldown_mult

	# I-frames during dash
	health_component.is_invincible = true
	EventBus.emit_player_dashed(_dash_direction)

	# Spawn shadow afterimage
	_spawn_shadow_ghost()

func _end_dash() -> void:
	_is_dashing = false
	health_component.is_invincible = false

func _spawn_shadow_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.global_position = global_position
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(0.3, 0.0, 0.6, 0.6) # Dark purple shadow aura
	get_parent().add_child(ghost)

	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)

func _handle_combat() -> void:
	if not can_attack or not combat_enabled:
		return
	if Input.is_action_pressed("attack") and _attack_timer <= 0.0:
		_execute_shadow_slash()

func _execute_shadow_slash() -> void:
	_attack_timer = attack_cooldown / attack_speed_mult
	var current_damage := base_damage * damage_mult
	if executioner_unlocked and randf() < 0.20:
		current_damage *= 3.0 # Dano triplo carrasco

	slash_hitbox.damage_amount = current_damage
	slash_hitbox.monitoring = true
	slash_visual.visible = true

	if not weapon_unlocked:
		# Unarmed Punch: Fast forward jab, small fist/impact burst
		slash_visual.scale = Vector2(0.5, 0.5)
		slash_visual.modulate = Color(1.5, 1.2, 0.8, 1.0) # White-golden punch flash
		var tween := create_tween()
		tween.tween_property(slash_visual, "scale", Vector2(1.1, 1.1), 0.05)
		tween.parallel().tween_property(slash_visual, "modulate:a", 0.0, 0.08)
		tween.tween_callback(func():
			slash_hitbox.monitoring = false
			slash_visual.visible = false
		)
	else:
		# Weapon Unlocked: Wide crescent shadow blade slash
		slash_visual.scale = Vector2(0.6, 0.6)
		slash_visual.modulate = Color(2.0, 0.3, 0.5, 1.0) if (executioner_unlocked and current_damage > base_damage * damage_mult) else Color(1.2, 0.4, 1.8, 1.0)
		var tween := create_tween()
		tween.tween_property(slash_visual, "scale", Vector2(1.2, 1.2), 0.08)
		tween.parallel().tween_property(slash_visual, "modulate:a", 0.0, 0.12)
		tween.tween_callback(func():
			slash_hitbox.monitoring = false
			slash_visual.visible = false
		)


func _attract_nearby_gems() -> void:
	var areas := magnet_area.get_overlapping_areas()
	for area in areas:
		if area is XPGem and is_instance_valid(area):
			(area as XPGem).attract_towards(self)

func _update_magnet_radius() -> void:
	var col := magnet_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null and col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = pickup_radius

func _on_enemy_killed(_pos: Vector2, _xp: int) -> void:
	kill_counter += 1
	if lifesteal_on_kill > 0.0:
		health_component.current_health = minf(health_component.max_health, health_component.current_health + lifesteal_on_kill)
		health_component.health_changed.emit(health_component.current_health, health_component.max_health)

	if abyssal_burst_unlocked and (kill_counter % 6 == 0):
		_trigger_abyssal_burst()

func _trigger_abyssal_burst() -> void:
	# Cheat tier: Shockwave around player obliterating nearby foes
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and is_instance_valid(e):
			var dist := global_position.distance_to((e as Node2D).global_position)
			if dist <= 120.0:
				var hurtbox := (e as Node2D).get_node_or_null("HurtboxComponent") as HurtboxComponent
				if hurtbox != null:
					var kb := ((e as Node2D).global_position - global_position).normalized()
					var data := DamageData.new(45.0, DamageData.DamageType.DARK, 200.0, kb, self)
					hurtbox.receive_hit(data)

func _handle_fire_pulse(delta: float) -> void:
	if not fire_pulse_unlocked or not combat_enabled:
		return
	_fire_pulse_timer -= delta
	if _fire_pulse_timer <= 0.0:
		_fire_pulse_timer = 3.0
		_trigger_fire_pulse()

func _trigger_fire_pulse() -> void:
	# Boss Theft Power: Expanding flame shockwave
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and is_instance_valid(e):
			var dist := global_position.distance_to((e as Node2D).global_position)
			if dist <= 140.0:
				var hurtbox := (e as Node2D).get_node_or_null("HurtboxComponent") as HurtboxComponent
				if hurtbox != null:
					var kb := ((e as Node2D).global_position - global_position).normalized()
					var data := DamageData.new(50.0, DamageData.DamageType.FIRE, 240.0, kb, self)
					hurtbox.receive_hit(data)


func _on_health_changed(current: float, max_hp: float) -> void:
	EventBus.emit_player_health_changed(current, max_hp)

var is_dead: bool = false


func _on_died() -> void:
	if is_dead:
		return
	is_dead = true
	can_attack = false
	combat_enabled = false
	set_physics_process(false)
	velocity = Vector2.ZERO

	# Efeito visual de morte/dissolução do protagonista
	var death_tween := create_tween()
	if death_tween != null:
		death_tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 0.0), 0.6)
		death_tween.parallel().tween_property(sprite, "scale", Vector2(1.4, 0.2), 0.6)

	EventBus.emit_entity_died(self, global_position)

