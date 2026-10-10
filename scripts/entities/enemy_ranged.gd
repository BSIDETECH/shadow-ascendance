class_name EnemyRanged
extends Enemy

var _attack_timer: float = 0.0
var _shoot_cooldown: float = 2.5
var enemy_projectile_scene: PackedScene = preload("res://scenes/entities/projectile/enemy_projectile.tscn")

func _ready() -> void:
	enemy_type = EnemyType.RANGED
	super._ready()

func _physics_process(delta: float) -> void:
	if _is_dying:
		return

	# Handle stun
	if _stun_timer > 0.0:
		_stun_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Handle slow decay
	if _slow_timer > 0.0:
		_slow_timer -= delta
		_current_speed = base_speed * (1.0 - _slow_factor)
	else:
		_slow_factor = 0.0
		_current_speed = base_speed

	# Decay knockback
	if _knockback_velocity.length_squared() > 10.0:
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		velocity = _knockback_velocity
		move_and_slide()
		return

	if _target == null or not is_instance_valid(_target):
		_find_target()
		return

	var distance := global_position.distance_to(_target.global_position)
	var direction := (_target.global_position - global_position).normalized()

	if distance < 120.0:
		# Kite away
		velocity = -direction * _current_speed
		_attack_timer = maxf(0.0, _attack_timer - delta)
	elif distance <= 200.0:
		# Stop or strafe slowly, and shoot
		velocity = Vector2.ZERO
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_shoot()
	else:
		# Move towards target
		velocity = direction * _current_speed
		_attack_timer = maxf(0.0, _attack_timer - delta)

	move_and_slide()

	# Flip sprite based on movement or target position
	if velocity.length_squared() > 1.0:
		if velocity.x != 0.0:
			sprite.flip_h = velocity.x < 0.0
	elif direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0

func _shoot() -> void:
	_attack_timer = _shoot_cooldown
	if _target == null or not is_instance_valid(_target):
		return

	var dir := (_target.global_position - global_position).normalized()

	if enemy_projectile_scene != null:
		var proj := enemy_projectile_scene.instantiate() as EnemyProjectile
		if proj != null:
			proj.global_position = global_position
			proj.direction = dir

			var parent := get_parent()
			if parent != null:
				parent.add_child(proj)
			else:
				get_tree().root.add_child(proj)

	# Small visual feedback when shooting
	var tween := create_tween()
	if tween != null and sprite != null:
		tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.05)
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)
