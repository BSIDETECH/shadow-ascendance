class_name IceSpike
extends Area2D

## Ice Spikes projectile cast by CompanionMage.
## Deals ICE damage and slows affected enemies.

@export var speed: float = 240.0
@export var damage: float = 18.0
@export var slow_factor: float = 0.45
@export var slow_duration: float = 2.5
@export var lifetime: float = 2.5

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0

var sprite: Sprite2D = null
var collision_shape: CollisionShape2D = null

func _init() -> void:
	collision_layer = 8 # Layer 4: PlayerAttacks
	collision_mask = 5  # Layer 1: World walls, Layer 3: Enemies

func _ready() -> void:
	collision_layer = 8 # Layer 4: PlayerAttacks
	collision_mask = 5  # Layer 1: World walls, Layer 3: Enemies

	_setup_nodes()
	rotation = direction.angle()

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _setup_nodes() -> void:
	sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0114.png")
		sprite.modulate = Color(0.5, 0.9, 1.8, 1.0)
		sprite.scale = Vector2(0.9, 0.9)
		add_child(sprite)

	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = 6.0
		collision_shape.shape = circle
		add_child(collision_shape)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox == null or hurtbox.team_index == 0:
		return

	var kb_dir := direction.normalized()
	var data := DamageData.new(
		damage,
		DamageData.DamageType.ICE,
		45.0,
		kb_dir,
		self
	)
	hurtbox.receive_hit(data)

	var target_entity: Node = hurtbox.owner if hurtbox.owner != null else hurtbox.get_parent()
	if target_entity != null:
		_apply_ice_slow(target_entity)

	_shatter()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		_shatter()
		return

	var hurtbox := body.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox != null:
		var kb_dir := direction.normalized()
		var data := DamageData.new(
			damage,
			DamageData.DamageType.ICE,
			45.0,
			kb_dir,
			self
		)
		hurtbox.receive_hit(data)

	_apply_ice_slow(body)
	_shatter()

func _apply_ice_slow(entity: Node) -> void:
	if entity.has_method("apply_slow"):
		entity.apply_slow(slow_factor, slow_duration)
	elif entity.get("_slow_timer") != null and entity.get("_slow_factor") != null:
		entity.set("_slow_factor", maxf(float(entity.get("_slow_factor")), slow_factor))
		entity.set("_slow_timer", maxf(float(entity.get("_slow_timer")), slow_duration))

func _shatter() -> void:
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	var tween := create_tween()
	if tween != null:
		tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.06)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.08)
		tween.tween_callback(queue_free)
	else:
		queue_free()
