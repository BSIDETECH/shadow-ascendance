import sys

def patch():
    with open('scripts/entities/enemy.gd', 'r') as f:
        content = f.read()

    # Apply Stun and Knockback first
    handle_process_orig = """	if _is_dying or health_component.is_downed:
		return

	if _stun_timer > 0.0:
		_stun_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return"""

    handle_process_new = """	if _is_dying or health_component.is_downed:
		return

	if _stun_timer > 0.0:
		_stun_timer -= delta

	if _stun_timer > 0.0:
		velocity = Vector2.ZERO
		# Let knockback decay if present
		if _knockback_velocity.length_squared() > 10.0:
			_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			velocity = _knockback_velocity
		move_and_slide()
		return"""

    content = content.replace(handle_process_orig, handle_process_new)

    with open('scripts/entities/enemy.gd', 'w') as f:
        f.write(content)

if __name__ == '__main__':
    patch()
