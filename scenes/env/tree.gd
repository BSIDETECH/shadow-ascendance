class_name DestructibleTree
extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var health_component: HealthComponent = $HealthComponent

var on_fire: bool = false
var fire_timer: float = 0.0

func _ready() -> void:
	# Add to tree group so we can query them
	add_to_group("tree")

	if health_component:
		health_component.died.connect(_on_died)
		health_component.health_changed.connect(_on_health_changed)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)
		hurtbox.team_index = 2 # Neutral/Environment team

	# Adjust collision layers
	# Layer 1 = World (blocks movement/projectiles)
	# Hurtbox layer = Custom for environment so it doesn't soak all attacks, maybe?
	# Let's look at HurtboxComponent masks/layers.
	# Fireball uses mask 4 (layer 3 - Enemies) and checks if team_index != 0.
	# EnemyProjectile uses mask 66 (Player and Ally hurtboxes) and checks team_index == 0.
	# We want both fireballs and enemy projectiles to hit the tree.
	# So hurtbox should probably be on layer 3 (value 4) and layer 2 (value 2)?
	# Wait, Area2D collisions: if a fireball has mask=4, it collides with layers containing 4.
	# EnemyProjectile has mask=66, collides with layers 2 and 64.
	# Let's set tree hurtbox to layer 2, 4, and 64 so everything hits it.
	hurtbox.collision_layer = 2 | 4 | 64
	hurtbox.collision_mask = 0

func _on_hit_received(data: DamageData) -> void:
	if data.has_type(DamageData.DamageType.FIRE):
		catch_fire()

func catch_fire() -> void:
	if not on_fire:
		on_fire = true
		sprite.modulate = Color(1.5, 0.5, 0.2) # Make it look burning
		fire_timer = 2.0

func _process(delta: float) -> void:
	if on_fire:
		fire_timer -= delta
		if fire_timer <= 0:
			if health_component:
				health_component.take_damage(DamageData.new(5.0, DamageData.DamageType.FIRE))
			fire_timer = 1.0

func _on_health_changed(_current: float, _max_health: float) -> void:
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate:v", 2.0, 0.1)
	flash_tween.tween_property(sprite, "modulate:v", 1.0, 0.1)

func _on_died() -> void:
	queue_free()
