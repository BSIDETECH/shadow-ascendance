class_name XPGem
extends Area2D

@export var xp_value: int = 1
@export var magnet_speed: float = 340.0

var _target: Node2D = null
var _velocity: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("drops")
	collision_layer = 32 # Layer 6: Drops
	collision_mask = 2   # Layer 2: Player
	body_entered.connect(_on_body_entered)

	# Gentle floating animation
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -3.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 3.0, 0.6).set_trans(Tween.TRANS_SINE)

func attract_towards(target: Node2D) -> void:
	_target = target

func _physics_process(delta: float) -> void:
	if _target != null and is_instance_valid(_target):
		var dir := (_target.global_position - global_position).normalized()
		var dist := global_position.distance_to(_target.global_position)
		var target_speed := magnet_speed + clampf(350.0 - dist, 0.0, 300.0)
		_velocity = _velocity.move_toward(dir * target_speed, 1600.0 * delta)
		global_position += _velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		EventBus.emit_xp_collected(xp_value)
		
		# Quick pop animation before freeing
		set_physics_process(false)
		collision_layer = 0
		collision_mask = 0
		var pop_tween := create_tween()
		pop_tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.08)
		pop_tween.tween_property(self, "modulate:a", 0.0, 0.08)
		pop_tween.tween_callback(queue_free)
