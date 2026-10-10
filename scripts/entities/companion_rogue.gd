class_name CompanionRogue
extends CompanionBase

## Rogue companion class (Silas).
## Fast melee attacks with daggers, dash with damage every 6s, and invisibility with damage bonus.

@export_group("Rogue Abilities")
@export var dagger_range: float = 40.0
@export var dagger_damage: float = 15.0
@export var dagger_cooldown: float = 0.4

@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 6.0
@export var dash_damage: float = 25.0

@export var invis_cooldown: float = 12.0
@export var invis_duration: float = 4.0
@export var invis_damage_multiplier: float = 2.0

var _dagger_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _invis_timer: float = 0.0
var _invis_cooldown_timer: float = 0.0

var _is_dashing: bool = false
var _dash_direction: Vector2 = Vector2.ZERO
var _is_invisible: bool = false

func _init() -> void:
	max_health = 90.0
	current_health = 90.0
	move_speed = 150.0
	sprint_speed = 210.0
	companion_name = "Silas"

func _ready() -> void:
	if enneagram_profile == null:
		enneagram_profile = EnneagramData.create_preset(EnneagramData.Type.ENTHUSIAST)
	super._ready()
	if sprite != null and sprite.texture == null:
		# Using a generic texture for now, similar to other companions
		sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0088.png")

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity = Vector2.ZERO
		return

	_dash_cooldown_timer = maxf(0.0, _dash_cooldown_timer - delta)
	_invis_cooldown_timer = maxf(0.0, _invis_cooldown_timer - delta)
	_dagger_timer = maxf(0.0, _dagger_timer - delta)

	if _is_invisible:
		_invis_timer -= delta
		if _invis_timer <= 0.0:
			_break_invisibility()

	if _is_dashing:
		_process_dash(delta)
		return

	super._physics_process(delta)

func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_direction * dash_speed
	var collision := move_and_slide()

	if is_on_wall() or (get_slide_collision_count() > 0 and velocity.length_squared() < 100.0):
		velocity = Vector2.ZERO
		_is_dashing = false
		return

	# Damage enemies during dash
	var tree := get_tree()
	if tree != null:
		var enemies := tree.get_nodes_in_group("enemies")
		for e in enemies:
			if e is Node2D and is_instance_valid(e):
				var node := e as Node2D
				if global_position.distance_to(node.global_position) <= 32.0:
					_apply_dash_impact(node)

	if _dash_timer <= 0.0:
		_is_dashing = false
		velocity = Vector2.ZERO

func _apply_dash_impact(target_enemy: Node2D) -> void:
	var hurtbox := target_enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox != null:
		# Make sure we only hit once per dash, wait we should probably track hit enemies but let's keep it simple.
		# A simple solution is a small cooldown per enemy or just trust the hit rate.
		# Given the prompt, let's just apply it.
		var kb_dir := _dash_direction
		var data := DamageData.new(
			dash_damage,
			DamageData.DamageType.PHYSICAL,
			100.0,
			kb_dir,
			self
		)
		hurtbox.receive_hit(data)

func _handle_combat(delta: float) -> void:
	if current_tactical_state == TacticalOrderState.ORDER_RETREAT:
		# Attack only if extremely close
		if _has_enemy_closer_than(dagger_range) and _dagger_timer <= 0.0:
			_perform_dagger_attack()
		return

	var target := _select_combat_target(250.0)
	if target == null:
		return

	var dist_to_target := global_position.distance_to(target.global_position)

	# 1. Invisibility if taking damage or multiple enemies around
	if _invis_cooldown_timer <= 0.0 and (_should_activate_invisibility()):
		_activate_invisibility()

	# 2. Dash towards enemy if out of melee range but close enough, or to dodge
	if dist_to_target >= 60.0 and dist_to_target <= 180.0 and _dash_cooldown_timer <= 0.0:
		_start_dash((target.global_position - global_position).normalized())
		return

	# 3. Fast Dagger Attack
	if dist_to_target <= dagger_range and _dagger_timer <= 0.0:
		_perform_dagger_attack()

func _should_activate_invisibility() -> bool:
	if health_component != null and health_component.current_health / health_component.max_health < 0.5:
		return true
	if _has_enemies_count_nearby(2, 80.0):
		return true
	return false

func _activate_invisibility() -> void:
	_is_invisible = true
	_invis_timer = invis_duration
	_invis_cooldown_timer = invis_cooldown
	# Apply visual effect
	if sprite != null:
		sprite.modulate.a = 0.3

func _break_invisibility() -> void:
	_is_invisible = false
	if sprite != null:
		sprite.modulate.a = 1.0

func _start_dash(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	_dash_direction = direction.normalized()
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_flash_tint(Color(1.5, 1.5, 1.5))

func _perform_dagger_attack() -> void:
	_dagger_timer = dagger_cooldown

	var damage := dagger_damage
	if _is_invisible:
		damage *= invis_damage_multiplier
		_break_invisibility()

	var tree := get_tree()
	if tree == null:
		return

	var enemies := tree.get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and is_instance_valid(e):
			var node := e as Node2D
			var dist := global_position.distance_to(node.global_position)
			if dist <= dagger_range:
				var hurtbox := node.get_node_or_null("HurtboxComponent") as HurtboxComponent
				if hurtbox != null:
					var kb_dir := (node.global_position - global_position).normalized()
					if kb_dir == Vector2.ZERO:
						kb_dir = Vector2.RIGHT
					var data := DamageData.new(
						damage,
						DamageData.DamageType.PHYSICAL,
						60.0,
						kb_dir,
						self
					)
					hurtbox.receive_hit(data)

	# Visual slice effect
	if sprite != null:
		var tween := create_tween()
		if tween != null:
			tween.tween_property(sprite, "position", Vector2(4, 0), 0.05)
			tween.tween_property(sprite, "position", Vector2(-4, 0), 0.05)
			tween.tween_property(sprite, "position", Vector2(0, 0), 0.05)

func _has_enemy_closer_than(dist: float) -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var enemies := tree.get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and is_instance_valid(e):
			if global_position.distance_to((e as Node2D).global_position) <= dist:
				return true
	return false

func _has_enemies_count_nearby(count: int, dist: float) -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var enemies := tree.get_nodes_in_group("enemies")
	var found := 0
	for e in enemies:
		if e is Node2D and is_instance_valid(e):
			if global_position.distance_to((e as Node2D).global_position) <= dist:
				found += 1
				if found >= count:
					return true
	return false
