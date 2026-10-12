class_name EnemyProjectile
extends Area2D

@export var speed: float = 450.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0

func _init() -> void:
	collision_layer = 16 # Layer 5: EnemyAttacks
	collision_mask = 66  # Layer 2: PlayerHurtbox (2) + Layer 7: AllyHurtbox (64) = 66

func _ready() -> void:
	collision_layer = 16
	collision_mask = 66
	rotation = direction.angle()

	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox != null and hurtbox.team_index == 0:
		var kb_dir := direction.normalized()
		var data := DamageData.new(
			damage,
			DamageData.DamageType.PHYSICAL,
			80.0,
			kb_dir,
			self
		)
		hurtbox.receive_hit(data)
		queue_free()
