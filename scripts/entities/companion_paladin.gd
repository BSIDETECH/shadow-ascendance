class_name CompanionPaladin
extends CompanionBase

## Paladin / Guardian companion class.
## Melee tank with 160 HP, 25% physical armor reduction, Melee Cleave (50px, 32 dmg),
## Shield Charge (320 px/s, 1.2s stun), and Aegis Shield dome (30% ally dmg reduction).

@export_group("Paladin Abilities")
@export var stun_duration: float = 1.2
@export var cleave_range: float = 50.0
@export var cleave_damage: float = 32.0
@export var cleave_cooldown: float = 1.1
@export var charge_speed: float = 320.0
@export var charge_duration: float = 0.45
@export var charge_cooldown: float = 4.5
@export var aegis_cooldown: float = 8.0

var _cleave_timer: float = 0.0
var _charge_cooldown_timer: float = 0.0
var _aegis_cooldown_timer: float = 0.0
var _is_charging: bool = false
var _charge_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.RIGHT

var shield_bubble_script: GDScript = preload("res://scripts/combat/shield_bubble.gd")

func _init() -> void:
	max_health = 160.0
	current_health = 160.0
	armor_reduction = 0.25
	companion_name = "Roland"
	move_speed = 125.0
	sprint_speed = 190.0

func _ready() -> void:
	if enneagram_profile == null:
		enneagram_profile = EnneagramData.create_preset(EnneagramData.Type.CHALLENGER)
	super._ready()
	if sprite != null and sprite.texture == null:
		sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0087.png")

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity = Vector2.ZERO
		return

	_charge_cooldown_timer = maxf(0.0, _charge_cooldown_timer - delta)
	_cleave_timer = maxf(0.0, _cleave_timer - delta)
	_aegis_cooldown_timer = maxf(0.0, _aegis_cooldown_timer - delta)

	if _is_charging:
		_process_shield_charge(delta)
		return

	super._physics_process(delta)

func _process_shield_charge(delta: float) -> void:
	_charge_timer -= delta
	velocity = _charge_direction * charge_speed
	var collision := move_and_slide()

	# Stop charge cleanly at world boundaries / walls without clipping
	if is_on_wall() or (get_slide_collision_count() > 0 and velocity.length_squared() < 100.0):
		velocity = Vector2.ZERO
		_is_charging = false
		return

	# Hit and stun enemies during charge
	if is_inside_tree():
		var world := get_world_2d()
		if world != null:
			var space_state := world.direct_space_state
			if space_state != null:
				var shape := CircleShape2D.new()
				shape.radius = 32.0

				var query := PhysicsShapeQueryParameters2D.new()
				query.shape = shape
				query.transform = Transform2D(0, global_position)
				query.collide_with_areas = true
				query.collide_with_bodies = true

				var results := space_state.intersect_shape(query, 32)
				var processed_enemies := {}
				for res in results:
					var node := res.collider as Node2D
					if node != null and node.is_in_group("enemies") and not processed_enemies.has(node):
						processed_enemies[node] = true
						_apply_charge_impact(node)

	if _charge_timer <= 0.0:
		_is_charging = false
		velocity = Vector2.ZERO

func _apply_charge_impact(target_enemy: Node2D) -> void:
	if target_enemy.has_method("apply_stun"):
		target_enemy.apply_stun(stun_duration)
	elif target_enemy.get("_stun_timer") != null:
		target_enemy.set("_stun_timer", stun_duration)

	var hurtbox := target_enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox != null:
		var kb_dir := _charge_direction
		var data := DamageData.new(
			18.0,
			DamageData.DamageType.PHYSICAL,
			140.0,
			kb_dir,
			self
		)
		hurtbox.receive_hit(data)

func _handle_combat(delta: float) -> void:
	if current_tactical_state == TacticalOrderState.ORDER_RETREAT:
		# In retreat, only cleave enemies that are right in face
		if _has_enemy_closer_than(cleave_range):
			_perform_cleave()
		return

	var target := _select_combat_target(220.0)
	if target == null:
		return

	var dist_to_target := global_position.distance_to(target.global_position)

	# 1. Trigger Shield Charge if target is at mid-range
	if dist_to_target >= 55.0 and dist_to_target <= 180.0 and _charge_cooldown_timer <= 0.0:
		start_shield_charge((target.global_position - global_position).normalized())
		return

	# 2. Trigger Melee Cleave if in close quarters
	if dist_to_target <= cleave_range and _cleave_timer <= 0.0:
		_perform_cleave()

	# 3. Trigger Aegis Shield when surrounded or protecting allies
	if _aegis_cooldown_timer <= 0.0 and _should_activate_aegis():
		deploy_aegis_shield()

func start_shield_charge(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	_charge_direction = direction.normalized()
	_is_charging = true
	_charge_timer = charge_duration
	_charge_cooldown_timer = charge_cooldown
	_flash_tint(Color(1.8, 1.8, 0.6))

func _perform_cleave() -> void:
	_cleave_timer = cleave_cooldown

	if not is_inside_tree():
		return
	var world := get_world_2d()
	if world == null:
		return
	var space_state := world.direct_space_state
	if space_state == null:
		return

	var shape := CircleShape2D.new()
	shape.radius = cleave_range

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := space_state.intersect_shape(query, 32)
	var processed_enemies := {}
	var hit_count := 0

	for res in results:
		var node := res.collider as Node2D
		if node != null and node.is_in_group("enemies") and not processed_enemies.has(node):
			processed_enemies[node] = true
			var hurtbox := node.get_node_or_null("HurtboxComponent") as HurtboxComponent
			if hurtbox != null:
				var kb_dir := (node.global_position - global_position).normalized()
				if kb_dir == Vector2.ZERO:
					kb_dir = Vector2.RIGHT
				var data := DamageData.new(
					cleave_damage,
					DamageData.DamageType.PHYSICAL,
					90.0,
					kb_dir,
					self
				)
				hurtbox.receive_hit(data)
				hit_count += 1

	# Visual Cleave sweep arc
	if sprite != null:
		var tween := create_tween()
		if tween != null:
			tween.tween_property(sprite, "rotation", 0.4, 0.06)
			tween.tween_property(sprite, "rotation", -0.4, 0.08)
			tween.tween_property(sprite, "rotation", 0.0, 0.05)

func _should_activate_aegis() -> bool:
	# Activate if health is low or multiple enemies nearby
	if health_component != null and health_component.current_health / health_component.max_health < 0.6:
		return true
	if _has_enemies_count_nearby(3, 100.0):
		return true
	if current_tactical_state == TacticalOrderState.ORDER_HELP:
		return true
	return false

func deploy_aegis_shield() -> void:
	_aegis_cooldown_timer = aegis_cooldown
	if shield_bubble_script == null:
		return

	var bubble := shield_bubble_script.new() as ShieldBubble
	if bubble != null:
		bubble.global_position = global_position
		bubble.damage_reduction = 0.30
		bubble.radius = 60.0
		bubble.lifetime = 4.5
		var parent := get_parent()
		if parent != null:
			parent.add_child(bubble)
		_flash_tint(Color(1.0, 1.2, 2.0))

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

func _has_enemies_count_nearby(count: int, dist: float) -> bool:
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
	var processed_enemies := {}
	var found := 0

	for res in results:
		var col := res.collider as Node
		if col != null and col.is_in_group("enemies") and not processed_enemies.has(col):
			processed_enemies[col] = true
			found += 1
			if found >= count:
				return true

	return false
