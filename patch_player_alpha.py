import re

def main():
    filepath = "scripts/entities/player.gd"
    with open(filepath, "r") as f:
        content = f.read()

    alpha = """func _start_dash() -> void:
	_is_dashing = true
	_dash_direction = _last_move_dir
	_dash_timer = dash_duration
	_dash_cd_timer = dash_cooldown * dash_cooldown_mult

	# I-frames during dash
	health_component.is_invincible = true
	if alpha_strike_unlocked:
		health_component.is_invincible = true # Alpha strike garantee invincibility
	EventBus.emit_player_dashed(_dash_direction)"""
    content = content.replace('func _start_dash() -> void:\n\t_is_dashing = true\n\t_dash_direction = _last_move_dir\n\t_dash_timer = dash_duration\n\t_dash_cd_timer = dash_cooldown * dash_cooldown_mult\n\n\t# I-frames during dash\n\thealth_component.is_invincible = true\n\tEventBus.emit_player_dashed(_dash_direction)', alpha)
    with open(filepath, "w") as f:
        f.write(content)

if __name__ == "__main__":
    main()
