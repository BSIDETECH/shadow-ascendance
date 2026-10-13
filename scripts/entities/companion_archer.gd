class_name CompanionArcher
extends CompanionBase

## Archer / Rogue companion class.
## Ranged support with 75 HP, 145 px/s speed, Piercing Arrow (up to 3 targets, 22 dmg),
## Slow Trap (40px, 55% slow for 3.5s), and Tumble Evasion (260 px/s for 0.15s).

@export_group("Archer Abilities")
@export var arrow_damage: float = 22.0
@export var arrow_speed: float = 290.0
@export var arrow_cooldown: float = 1.15
@export var slow_factor: float = 0.55
@export var trap_cooldown: float = 5.0
@export var tumble_proximity: float = 45.0
@export var tumble_speed: float = 260.0
@export var tumble_duration: float = 0.15
@export var tumble_cooldown: float = 2.0
@export var boundary_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(640, 360))

var _arrow_timer: float = 0.0
var _trap_timer: float = 0.0
var _tumble_timer: float = 0.0
var _tumble_cooldown_timer: float = 0.0
var _is_tumbling: bool = false
var _tumble_direction: Vector2 = Vector2.ZERO

var arrow_script: GDScript = preload("res://scripts/entities/piercing_arrow.gd")
var trap_script: GDScript = preload("res://scripts/entities/slow_trap.gd")

func _init() -> void:
	max_health = 75.0
	current_health = 75.0
	move_speed = 145.0
	sprint_speed = 190.0
	companion_name = "Kael"

func _ready() -> void:
	if enneagram_profile == null:
		enneagram_profile = EnneagramData.create_preset(EnneagramData.Type.INVESTIGATOR)
	super._ready()
	if sprite != null and sprite.texture == null:
		sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0088.png")

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity = Vector2.ZERO
		return

	_tumble_cooldown_timer = maxf(0.0, _tumble_cooldown_timer - delta)
	_arrow_timer = maxf(0.0, _arrow_timer - delta)
	_trap_timer = maxf(0.0, _trap_timer - delta)

	if _is_tumbling:
		_process_tumble(delta)
		return

	# Check for tumble evasion trigger
	if _tumble_cooldown_timer <= 0.0 and _check_proximity_threat():
		_trigger_tumble_evasion()
		return

	super._physics_process(delta)

func _check_proximity_threat() -> bool:
	if not is_inside_tree():
		return false
	var world := get_world_2d()
	if world == null:
		return false
	var space_state := world.direct_space_state
	if space_state == null:
		return false

	var shape := CircleShape2D.new()
	shape.radius = tumble_proximity

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := space_state.intersect_shape(query, 32)
	for res in results:
		var col := res.collider as Node
		if col != null and col.is_in_group("enemies"):
			return true
	return false

func _trigger_tumble_evasion() -> void:
	if not is_inside_tree():
		return
	var world := get_world_2d()
	if world == null:
		return
	var space_state := world.direct_space_state
	if space_state == null:
		return

	var shape := CircleShape2D.new()
	shape.radius = tumble_proximity

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := space_state.intersect_shape(query, 32)
	var evade_vector := Vector2.ZERO
	var processed_enemies := {}

	for res in results:
		var col := res.collider as Node2D
		if col != null and col.is_in_group("enemies") and not processed_enemies.has(col):
			processed_enemies[col] = true
			var dist := global_position.distance_to(col.global_position)
			if dist <= tumble_proximity and dist > 0.001:
				evade_vector += (global_position - col.global_position).normalized()

	if evade_vector == Vector2.ZERO:
		evade_vector = -velocity.normalized() if velocity != Vector2.ZERO else Vector2.LEFT

	_tumble_direction = evade_vector.normalized()
	_is_tumbling = true
	_tumble_timer = tumble_duration
	_tumble_cooldown_timer = tumble_cooldown
	_flash_tint(Color(0.8, 1.5, 1.8))

func _process_tumble(delta: float) -> void:
	_tumble_timer -= delta
	velocity = _tumble_direction * tumble_speed
	move_and_slide()

	# Clamp inside world geometry
	_clamp_to_boundaries()

	if _tumble_timer <= 0.0:
		_is_tumbling = false
		velocity = Vector2.ZERO

func _clamp_to_boundaries() -> void:
	global_position.x = clampf(global_position.x, boundary_rect.position.x + 16.0, boundary_rect.end.x - 16.0)
	global_position.y = clampf(global_position.y, boundary_rect.position.y + 16.0, boundary_rect.end.y - 16.0)

func _handle_combat(delta: float) -> void:
	if current_tactical_state == TacticalOrderState.ORDER_RETREAT:
		# Retreating archer only fires if threat is very close
		if _has_enemy_closer_than(60.0) and _arrow_timer <= 0.0:
			_shoot_piercing_arrow()
		return

	var target := _select_combat_target(320.0)
	if target == null:
		return

	var dist_to_target := global_position.distance_to(target.global_position)

	# 1. Place Slow Trap if enemy is approaching or within trap zone
	if _trap_timer <= 0.0 and dist_to_target <= 120.0:
		_place_slow_trap()

	# 2. Shoot Piercing Arrow
	if _arrow_timer <= 0.0:
		_shoot_piercing_arrow()

func _shoot_piercing_arrow() -> void:
	_arrow_timer = arrow_cooldown
	var target := _select_combat_target(320.0)
	if target == null or arrow_script == null:
		return

	var dir := (target.global_position - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT

	var arrow := arrow_script.new() as PiercingArrow
	if arrow != null:
		arrow.global_position = global_position
		arrow.direction = dir
		arrow.damage = arrow_damage
		arrow.speed = arrow_speed
		arrow.max_pierce = 3
		var parent := get_parent()
		if parent != null:
			parent.add_child(arrow)

	if sprite != null:
		var tween := create_tween()
		if tween != null:
			tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.05)
			tween.tween_property(sprite, "scale", Vector2.ONE, 0.08)

func _place_slow_trap() -> void:
	_trap_timer = trap_cooldown
	if trap_script == null:
		return

	var trap := trap_script.new() as SlowTrap
	if trap != null:
		trap.global_position = global_position
		trap.slow_factor = slow_factor
		trap.slow_radius = 40.0
		trap.slow_duration = 3.5
		var parent := get_parent()
		if parent != null:
			parent.add_child(trap)

func _has_enemy_closer_than(dist: float) -> bool:
	if not is_inside_tree():
		return false
	var world := get_world_2d()
	if world == null:
		return false
	var space_state := world.direct_space_state
	if space_state == null:
		return false

	var shape := CircleShape2D.new()
	shape.radius = dist

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := space_state.intersect_shape(query, 32)
	for res in results:
		var col := res.collider as Node
		if col != null and col.is_in_group("enemies"):
			return true

	return false
