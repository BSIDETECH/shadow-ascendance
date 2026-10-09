class_name LeylineMonolith
extends StaticBody2D

## Leyline Monolith altar node for Ruined Fortress dungeon sector.
## Projects 90% shield mitigation onto linked elemental guardian boss.
## When destroyed, emits monolith_destroyed signal. Breaking both monoliths
## triggers a Leyline Overload on the boss (100 direct damage + 4.0s stun).

signal monolith_destroyed(monolith: Node)
signal monolith_damaged(current_hp: float, max_hp: float)

@export var shield_mitigation: float = 0.90
@export var overload_stun_duration: float = 4.0
@export var max_health: float = 150.0
@export var current_health: float = 150.0
@export var monolith_name: String = "Leyline Monolith"

var is_destroyed: bool = false

var health_component: HealthComponent = null
var hurtbox_component: HurtboxComponent = null
var sprite: Sprite2D = null
var aura_sprite: Sprite2D = null
var collision_shape: CollisionShape2D = null

const TEXTURE_ACTIVE: String = "res://assets/kenney_tiny_dungeon/Tiles/tile_0018.png"
const TEXTURE_ALTAR: String = "res://assets/kenney_tiny_dungeon/Tiles/tile_0019.png"

func _init() -> void:
	_setup_components()

func _ready() -> void:
	# Layer 1 = World (blocks characters)
	collision_layer = 1
	collision_mask = 0
	add_to_group("monoliths")
	add_to_group("leylines")
	_setup_components()
	_update_visuals()

func _setup_components() -> void:
	if health_component == null:
		health_component = get_node_or_null("HealthComponent") as HealthComponent
	if health_component == null:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		add_child(health_component)

	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.i_frame_duration = 0.0
	current_health = max_health
	if not health_component.took_damage.is_connected(_on_took_damage):
		health_component.took_damage.connect(_on_took_damage)
	if not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)

	if hurtbox_component == null:
		hurtbox_component = get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox_component == null:
		hurtbox_component = HurtboxComponent.new()
		hurtbox_component.name = "HurtboxComponent"
		hurtbox_component.collision_layer = 4 # Layer 3: Enemies
		hurtbox_component.collision_mask = 8  # Layer 4: PlayerAttacks
		hurtbox_component.team_index = 1     # Enemy/Targetable team
		var hurt_shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(20.0, 24.0)
		hurt_shape.shape = box
		hurtbox_component.add_child(hurt_shape)
		add_child(hurtbox_component)

	hurtbox_component.health_component = health_component
	hurtbox_component.team_index = 1

	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var body_box := RectangleShape2D.new()
		body_box.size = Vector2(16.0, 16.0)
		collision_shape.shape = body_box
		add_child(collision_shape)

	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		if ResourceLoader.exists(TEXTURE_ACTIVE):
			sprite.texture = load(TEXTURE_ACTIVE)
		sprite.modulate = Color(0.4, 0.9, 1.2, 1.0) # Ethereal cyan glow
		add_child(sprite)

func _update_visuals() -> void:
	if sprite != null:
		if is_destroyed:
			sprite.modulate = Color(0.3, 0.3, 0.35, 0.6) # Crumbled / dimmed
			if ResourceLoader.exists(TEXTURE_ALTAR):
				sprite.texture = load(TEXTURE_ALTAR)
		else:
			sprite.modulate = Color(0.4, 0.9, 1.2, 1.0)

func _on_took_damage(data: DamageData) -> void:
	if is_destroyed:
		return
	current_health = health_component.current_health
	monolith_damaged.emit(current_health, max_health)
	
	# Hit flash effect
	if sprite != null and is_inside_tree():
		var orig_mod := sprite.modulate
		sprite.modulate = Color(1.5, 1.5, 2.0, 1.0)
		var tree := get_tree()
		if tree != null:
			var tween := tree.create_tween()
			if tween != null:
				tween.tween_property(sprite, "modulate", orig_mod, 0.12)

func _on_died() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	current_health = 0.0

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if hurtbox_component != null:
		hurtbox_component.set_deferred("monitoring", false)
		hurtbox_component.set_deferred("monitorable", false)

	_update_visuals()
	monolith_destroyed.emit(self)

func take_damage(data_or_amount: Variant) -> void:
	if is_destroyed:
		return
	if data_or_amount is DamageData:
		health_component.take_damage(data_or_amount)
	elif data_or_amount is float or data_or_amount is int:
		var data := DamageData.new(float(data_or_amount), DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, null)
		health_component.take_damage(data)
