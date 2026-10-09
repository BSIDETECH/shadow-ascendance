class_name PiercingArrow
extends Area2D

## Piercing Arrow projectile fired by CompanionArcher.
## Penetrates up to 3 enemies dealing 22 damage to each.

@export var speed: float = 290.0
@export var damage: float = 22.0
@export var max_pierce: int = 3
@export var lifetime: float = 2.5

var direction: Vector2 = Vector2.RIGHT
var pierce_count: int = 0
var _time_alive: float = 0.0
var _hit_targets: Array[Node] = []

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
		sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0119.png")
		sprite.scale = Vector2(0.85, 0.85)
		add_child(sprite)

	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = 5.0
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

	var target_entity: Node = hurtbox.owner if hurtbox.owner != null else hurtbox.get_parent()
	if _hit_targets.has(target_entity):
		return
	_hit_targets.append(target_entity)

	var kb_dir := direction.normalized()
	var data := DamageData.new(
		damage,
		DamageData.DamageType.PHYSICAL,
		60.0,
		kb_dir,
		self
	)
	hurtbox.receive_hit(data)

	pierce_count += 1
	_spawn_hit_spark()

	if pierce_count >= max_pierce:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# If arrow hits world wall (Layer 1) and not an enemy, terminate
	if not body.is_in_group("enemies"):
		queue_free()
		return

	if _hit_targets.has(body):
		return
	_hit_targets.append(body)

	var hurtbox := body.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox != null:
		var kb_dir := direction.normalized()
		var data := DamageData.new(
			damage,
			DamageData.DamageType.PHYSICAL,
			60.0,
			kb_dir,
			self
		)
		hurtbox.receive_hit(data)

	pierce_count += 1
	_spawn_hit_spark()

	if pierce_count >= max_pierce:
		queue_free()

func _spawn_hit_spark() -> void:
	if sprite != null:
		var tween := create_tween()
		if tween != null:
			tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 1.5), 0.04)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.04)
