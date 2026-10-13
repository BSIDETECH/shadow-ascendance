class_name Fireball
extends Area2D

@export var speed: float = 260.0
@export var damage: float = 24.0
@export var aoe_radius: float = 36.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_layer = 8 # Layer 4: PlayerAttacks
	collision_mask = 4  # Layer 3: Enemies
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent and (area as HurtboxComponent).team_index != 0:
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_explode()

func _explode() -> void:
	if not is_inside_tree():
		return

	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0

	# Deal AoE damage and compute Spread Shot using a single unified spatial query
	var space := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = max(aoe_radius, 200.0) # Check up to max spread shot bounce distance

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := space.intersect_shape(query, 256)
	var processed_enemies := {}

	var p = get_tree().get_first_node_in_group("player")
	var spread_active = p != null and p.has_meta("spread_shot_unlocked") and p.get_meta("spread_shot_unlocked") and not has_meta("is_bounced")
	var nearest_spread_target: Node2D = null
	var min_spread_dist = 99999.0

	for res in results:
		var collider = res.collider
		var target: Node2D = null
		var hurtbox: HurtboxComponent = null

		if collider is HurtboxComponent:
			hurtbox = collider as HurtboxComponent
			target = hurtbox.owner if hurtbox.owner is Node2D else hurtbox.get_parent() as Node2D
		elif collider is Node2D and collider.is_in_group("enemies"):
			target = collider as Node2D
			hurtbox = target.get_node_or_null("HurtboxComponent") as HurtboxComponent

		if target != null and is_instance_valid(target) and target.is_in_group("enemies") and not processed_enemies.has(target):
			processed_enemies[target] = true
			var dist := global_position.distance_to(target.global_position)

			if dist <= aoe_radius:
				if hurtbox != null:
					var kb_dir := (target.global_position - global_position).normalized()
					var data := DamageData.new(
						damage,
						DamageData.DamageType.FIRE,
						90.0,
						kb_dir,
						self
					)
					hurtbox.receive_hit(data)
			elif spread_active and dist < min_spread_dist and dist < 200.0:
				min_spread_dist = dist
				nearest_spread_target = target

	# Spread Shot bounce logic
	if spread_active and nearest_spread_target != null:
		var new_fb = load("res://scenes/entities/projectile/fireball.tscn").instantiate()
		new_fb.global_position = global_position
		new_fb.direction = (nearest_spread_target.global_position - global_position).normalized()
		new_fb.damage = damage
		new_fb.set_meta("is_bounced", true)
		get_parent().add_child(new_fb)

	# Explosion visual pop
	var tween := create_tween()
	sprite.modulate = Color(1.5, 0.8, 0.2, 1.0) # Bright fire flash
	tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.1)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
