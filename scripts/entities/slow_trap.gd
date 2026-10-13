class_name SlowTrap
extends Area2D

## Tactical slowing trap deployed by CompanionArcher.
## Slows enemies within 40px radius by 55% for 3.5s. Non-stacking.

@export var slow_factor: float = 0.55
@export var slow_radius: float = 40.0
@export var slow_duration: float = 3.5
@export var arm_delay: float = 0.25
@export var trap_lifetime: float = 15.0

var _is_armed: bool = false
var _is_triggered: bool = false
var _time_alive: float = 0.0

var collision_shape: CollisionShape2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4 # Layer 3: Enemies
	monitoring = true
	monitorable = false

	_setup_collision()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _setup_collision() -> void:
	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = slow_radius
		collision_shape.shape = circle
		add_child(collision_shape)
	elif collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = slow_radius

func _physics_process(delta: float) -> void:
	_time_alive += delta

	if not _is_armed and _time_alive >= arm_delay:
		_is_armed = true
		_check_initial_overlaps()

	if _time_alive >= trap_lifetime:
		_disarm_and_free()

func _check_initial_overlaps() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies"):
			trigger_trap()
			return

func _on_body_entered(body: Node2D) -> void:
	if not _is_armed or _is_triggered:
		return
	if body.is_in_group("enemies"):
		trigger_trap()

func _on_area_entered(area: Area2D) -> void:
	if not _is_armed or _is_triggered:
		return
	var hurtbox := area as HurtboxComponent
	if hurtbox != null and hurtbox.team_index != 0:
		trigger_trap()

func trigger_trap() -> void:
	if _is_triggered:
		return
	_is_triggered = true

	# Apply slow to all enemies within radius
	if not is_inside_tree(): return
	var world := get_world_2d()
	if world == null: return
	var space_state := world.direct_space_state
	if space_state == null: return
	var shape := CircleShape2D.new()
	shape.radius = slow_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var results := space_state.intersect_shape(query, 32)
	var processed_enemies := {}
	for res in results:
		var e = res.collider as Node
		if e != null and e.is_in_group("enemies") and not processed_enemies.has(e):
			processed_enemies[e] = true
			if e is Node2D and is_instance_valid(e):
				var node := e as Node2D
				if global_position.distance_to(node.global_position) <= slow_radius:
					_apply_slow_to_enemy(node)

	# Visual explosion pop & fade
	queue_redraw()
	var tween := create_tween()
	if tween != null:
		tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _apply_slow_to_enemy(enemy: Node2D) -> void:
	if enemy.has_method("apply_slow"):
		enemy.apply_slow(slow_factor, slow_duration)
	elif enemy.get("_slow_timer") != null and enemy.get("_slow_factor") != null:
		enemy.set("_slow_factor", maxf(float(enemy.get("_slow_factor")), slow_factor))
		enemy.set("_slow_timer", maxf(float(enemy.get("_slow_timer")), slow_duration))

	# Small visual frost tint on affected target
	var sprite_node := enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite_node != null:
		var orig_mod: Color = sprite_node.modulate
		var tween := create_tween()
		if tween != null:
			tween.tween_property(sprite_node, "modulate", Color(0.4, 0.7, 1.4), 0.08)
			tween.tween_property(sprite_node, "modulate", orig_mod, 0.15)

func _disarm_and_free() -> void:
	set_physics_process(false)
	var tween := create_tween()
	if tween != null:
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _draw() -> void:
	if _is_triggered:
		# Frost flash circle on trigger
		draw_circle(Vector2.ZERO, slow_radius, Color(0.4, 0.8, 1.2, 0.45))
		draw_arc(Vector2.ZERO, slow_radius, 0.0, TAU, 32, Color(0.7, 0.9, 1.5, 0.9), 2.0)
	else:
		# Armed ground trap rune
		var color := Color(0.3, 0.7, 1.0, 0.35) if _is_armed else Color(0.5, 0.5, 0.5, 0.2)
		draw_circle(Vector2.ZERO, 10.0, color)
		draw_arc(Vector2.ZERO, slow_radius * 0.4, 0.0, TAU, 16, Color(0.4, 0.7, 1.0, 0.6), 1.0)
		draw_line(Vector2(-8, 0), Vector2(8, 0), Color(0.5, 0.8, 1.0, 0.8), 1.5)
		draw_line(Vector2(0, -8), Vector2(0, 8), Color(0.5, 0.8, 1.0, 0.8), 1.5)
