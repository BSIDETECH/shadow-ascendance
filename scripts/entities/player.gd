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

# New Gacha Flags
var vorpal_sword_unlocked: bool = false
var alpha_strike_unlocked: bool = false
var wind_momentum_unlocked: bool = false
var spin_attack_unlocked: bool = false
var insatiable_hunger_unlocked: bool = false
var cosmic_rupture_unlocked: bool = false
var void_feast_unlocked: bool = false
var noxian_guillotine_unlocked: bool = false
var ancestral_resurrect_unlocked: bool = false

var _wind_distance: float = 0.0
var _spin_timer: float = 0.0
var _is_spinning: bool = false
var _ancestral_used: bool = false
var void_feast_stacks: int = 0

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
	
	if GameManager != null and "blacksmith_bonus_damage" in GameManager: # Checa se o AutoLoad tá de pé
		base_damage += GameManager.blacksmith_bonus_damage
		health_component.max_health += GameManager.blacksmith_bonus_health
		health_component.current_health += GameManager.blacksmith_bonus_health
		base_speed += GameManager.blacksmith_bonus_speed

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
		if vorpal_sword_unlocked:
			slash_hitbox.scale = Vector2(1.25, 1.25)
		else:
			slash_hitbox.scale = Vector2.ONE

func _physics_process(delta: float) -> void:
	_handle_timers(delta)
	_handle_aim()
	_handle_movement(delta)
	_handle_combat()
	_handle_fire_pulse(delta)
	_handle_spin(delta)
	_attract_nearby_gems()

func _handle_spin(delta: float) -> void:
	if not spin_attack_unlocked:
		return

	if _is_spinning:
		_spin_timer -= delta
		if _spin_timer <= 0.0:
			_is_spinning = false
			_spin_timer = 8.0
			slash_visual.visible = false
			slash_hitbox.monitoring = false
			move_speed_mult /= 1.2
			slash_visual.scale = Vector2.ONE # FIX: Reset scale
		else:
			slash_visual.visible = true
			slash_visual.rotation += 10.0 * delta
			slash_hitbox.monitoring = true
			slash_hitbox.rotation += 10.0 * delta
			slash_hitbox.damage_amount = base_damage * damage_mult * 0.5
	else:
		_spin_timer -= delta
		if _spin_timer <= 0.0:
			_is_spinning = true
			_spin_timer = 2.0
			move_speed_mult *= 1.2
			slash_visual.scale = Vector2(1.5, 1.5)

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
		if alpha_strike_unlocked:
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) < 45.0:
					var hurtbox = e.get_node_or_null("HurtboxComponent")
					if hurtbox:
						var dmg = DamageData.new(base_damage * damage_mult, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, self)
						hurtbox.receive_hit(dmg)
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		_last_move_dir = input_vector.normalized()
		velocity = input_vector * (base_speed * move_speed_mult)
		sprite.flip_h = input_vector.x < 0.0

		if wind_momentum_unlocked:
			_wind_distance += velocity.length() * delta
			if _wind_distance >= 500.0:
				_wind_distance = 0.0
				health_component.external_damage_mitigation = 0.5
				var tw = create_tween()
				tw.tween_property(health_component, "external_damage_mitigation", 0.0, 2.0)
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
	if alpha_strike_unlocked:
		health_component.is_invincible = true # Alpha strike garantee invincibility
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

	# Immediate hit detection for Vorpal, Noxian, and Solar Flare
	await get_tree().physics_frame # ensure physics state is updated
	var enemies = slash_hitbox.get_overlapping_areas()
	for area in enemies:
		if area is HurtboxComponent and area.team_index != 0:
			var target = area.owner if area.owner else area.get_parent()
			if is_instance_valid(target):
				var extra_dmg = 0.0
				if target.has_meta("marked_by_solar") and target.get_meta("marked_by_solar"):
					extra_dmg += 40.0 * damage_mult
					target.set_meta("marked_by_solar", false)
				if vorpal_sword_unlocked:
					var target_health = target.get_node_or_null("HealthComponent")
					if target_health:
						extra_dmg += target_health.max_health * 0.05
				if noxian_guillotine_unlocked:
					var target_health = target.get_node_or_null("HealthComponent")
					if target_health and target_health.current_health < target_health.max_health * 0.3:
						extra_dmg += 9999.0
						# Fear
						var all_enemies = get_tree().get_nodes_in_group("enemies")
						for e in all_enemies:
							if e != target and is_instance_valid(e) and global_position.distance_to(e.global_position) < 150.0:
								if e.has_method("apply_stun"): e.apply_stun(1.5)
				if extra_dmg > 0.0:
					var kb_dir = (target.global_position - global_position).normalized()
					var data = DamageData.new(extra_dmg, DamageData.DamageType.DARK, 50.0, kb_dir, self)
					area.receive_hit(data)

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

	if cosmic_rupture_unlocked and (kill_counter % 20 == 0):
		var mouse_dir = (get_global_mouse_position() - global_position).normalized()
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e):
				var e_dir = (e.global_position - global_position).normalized()
				if e_dir.dot(mouse_dir) > 0.9: # Narrow angle cone / laser
					var hurtbox = e.get_node_or_null("HurtboxComponent")
					if hurtbox:
						var data = DamageData.new(80.0 * damage_mult, DamageData.DamageType.DARK, 100.0, mouse_dir, self)
						hurtbox.receive_hit(data)

	if void_feast_unlocked and _xp >= 10 and void_feast_stacks < 10:
		void_feast_stacks += 1
		health_component.max_health += 20.0
		health_component.current_health += 20.0
		sprite.scale *= 1.05
		damage_mult += 0.05
		health_component.health_changed.emit(health_component.current_health, health_component.max_health)

func _trigger_abyssal_burst() -> void:
	# Cheat tier: Shockwave around player obliterating nearby foes
	var space_state := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 120.0

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = global_transform
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := space_state.intersect_shape(query, 100)
	var hit_nodes := {}
	for res in results:
		var collider = res.collider
		if not hit_nodes.has(collider):
			hit_nodes[collider] = true
			if collider.is_in_group("enemies"):
				var hurtbox := collider.get_node_or_null("HurtboxComponent") as HurtboxComponent
				if hurtbox != null:
					var kb := (collider.global_position - global_position).normalized()
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
	var space_state := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 140.0

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = global_transform
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := space_state.intersect_shape(query, 100)
	var hit_nodes := {}
	for res in results:
		var collider = res.collider
		if not hit_nodes.has(collider):
			hit_nodes[collider] = true
			if collider.is_in_group("enemies"):
				var hurtbox := collider.get_node_or_null("HurtboxComponent") as HurtboxComponent
				if hurtbox != null:
					var kb := (collider.global_position - global_position).normalized()
					var data := DamageData.new(50.0, DamageData.DamageType.FIRE, 240.0, kb, self)
					hurtbox.receive_hit(data)


func _on_health_changed(current: float, max_hp: float) -> void:
	EventBus.emit_player_health_changed(current, max_hp)
	if insatiable_hunger_unlocked:
		if current <= max_hp * 0.5:
			if not has_meta("hunger_active"):
				set_meta("hunger_active", true)
				set_meta("old_lifesteal", lifesteal_on_kill)
				lifesteal_on_kill = (lifesteal_on_kill if lifesteal_on_kill > 0 else 2.0) * 3.0
				attack_speed_mult += 0.5
				var group_allies := get_tree().get_nodes_in_group("companions")
				for ally in group_allies:
					if ally != null and is_instance_valid(ally) and "cast_cooldown" in ally:
						ally.cast_cooldown *= 0.5 # 50% ASPD
		else:
			if has_meta("hunger_active"):
				remove_meta("hunger_active")
				if has_meta("old_lifesteal"):
					lifesteal_on_kill = get_meta("old_lifesteal")
				else:
					lifesteal_on_kill /= 3.0
				attack_speed_mult -= 0.5
				var group_allies := get_tree().get_nodes_in_group("companions")
				for ally in group_allies:
					if ally != null and is_instance_valid(ally) and "cast_cooldown" in ally:
						ally.cast_cooldown /= 0.5

var is_dead: bool = false


func _on_died() -> void:
	if ancestral_resurrect_unlocked and not _ancestral_used:
		_ancestral_used = true
		health_component.current_health = health_component.max_health * 0.5
		health_component.health_changed.emit(health_component.current_health, health_component.max_health)
		# Stasis logic (pause for 2s)
		can_attack = false
		combat_enabled = false
		var tw = create_tween()
		tw.tween_callback(func():
			can_attack = true
			combat_enabled = true
			health_component.is_invincible = false
		).set_delay(2.0)
		health_component.is_invincible = true
		return

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

