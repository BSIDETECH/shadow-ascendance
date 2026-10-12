import re

def main():
    filepath = "scripts/entities/player.gd"
    with open(filepath, "r") as f:
        content = f.read()

    # Fix 1: Spin Attack - Reset scale
    spin_func = """func _handle_spin(delta: float) -> void:
	if not spin_attack_unlocked:
		return

	if _is_spinning:
		_spin_timer -= delta
		if _spin_timer <= 0.0:
			_is_spinning = false
			_spin_timer = 8.0
			slash_visual.visible = false
			slash_hitbox.monitoring = false
			move_speed_mult /= 1.2
			slash_visual.scale = Vector2.ONE # FIX: Reset scale
		else:
			slash_visual.visible = true
			slash_visual.rotation += 10.0 * delta
			slash_hitbox.monitoring = true
			slash_hitbox.rotation += 10.0 * delta
			slash_hitbox.damage_amount = base_damage * damage_mult * 0.5
	else:
		_spin_timer -= delta
		if _spin_timer <= 0.0:
			_is_spinning = true
			_spin_timer = 2.0
			move_speed_mult *= 1.2
			slash_visual.scale = Vector2(1.5, 1.5)"""
    content = re.sub(r'func _handle_spin\(delta: float\) -> void:\n\tif not spin_attack_unlocked:\n\t\treturn\n\t\t\n\tif _is_spinning:\n\t\t_spin_timer -= delta\n\t\tif _spin_timer <= 0\.0:\n\t\t\t_is_spinning = false\n\t\t\t_spin_timer = 8\.0\n\t\t\tslash_visual\.visible = false\n\t\t\tslash_hitbox\.monitoring = false\n\t\t\tmove_speed_mult \/= 1\.2 # Reset from a hypothetical speed boost or ignore slow\n\t\telse:\n\t\t\tslash_visual\.visible = true\n\t\t\tslash_visual\.rotation \+= 10\.0 \* delta\n\t\t\tslash_hitbox\.monitoring = true\n\t\t\tslash_hitbox\.rotation \+= 10\.0 \* delta\n\t\t\tslash_hitbox\.damage_amount = base_damage \* damage_mult \* 0\.5\n\telse:\n\t\t_spin_timer -= delta\n\t\tif _spin_timer <= 0\.0:\n\t\t\t_is_spinning = true\n\t\t\t_spin_timer = 2\.0\n\t\t\tmove_speed_mult \*= 1\.2\n\t\t\tslash_visual\.scale = Vector2\(1\.5, 1\.5\)', spin_func, content)

    # Fix 2: Insatiable Hunger - Math issue + Companion buff
    hunger = """func _on_health_changed(current: float, max_hp: float) -> void:
	EventBus.emit_player_health_changed(current, max_hp)
	if insatiable_hunger_unlocked:
		if current <= max_hp * 0.5:
			if not has_meta("hunger_active"):
				set_meta("hunger_active", true)
				set_meta("old_lifesteal", lifesteal_on_kill)
				lifesteal_on_kill = (lifesteal_on_kill if lifesteal_on_kill > 0 else 2.0) * 3.0
				attack_speed_mult += 0.5
				var group_allies := get_tree().get_nodes_in_group("companions")
				for ally in group_allies:
					if ally != null and is_instance_valid(ally) and "cast_cooldown" in ally:
						ally.cast_cooldown *= 0.5 # 50% ASPD
		else:
			if has_meta("hunger_active"):
				remove_meta("hunger_active")
				if has_meta("old_lifesteal"):
					lifesteal_on_kill = get_meta("old_lifesteal")
				else:
					lifesteal_on_kill /= 3.0
				attack_speed_mult -= 0.5
				var group_allies := get_tree().get_nodes_in_group("companions")
				for ally in group_allies:
					if ally != null and is_instance_valid(ally) and "cast_cooldown" in ally:
						ally.cast_cooldown /= 0.5"""
    content = re.sub(r'func _on_health_changed\(current: float, max_hp: float\) -> void:\n\tEventBus\.emit_player_health_changed\(current, max_hp\)\n\tif insatiable_hunger_unlocked:\n\t\tif current <= max_hp \* 0\.5:\n\t\t\tif not has_meta\("hunger_active"\):\n\t\t\t\tset_meta\("hunger_active", true\)\n\t\t\t\tlifesteal_on_kill = \(lifesteal_on_kill if lifesteal_on_kill > 0 else 2\.0\) \* 3\.0\n\t\t\t\tattack_speed_mult \+= 0\.5\n\t\telse:\n\t\t\tif has_meta\("hunger_active"\):\n\t\t\t\tremove_meta\("hunger_active"\)\n\t\t\t\tlifesteal_on_kill \/= 3\.0\n\t\t\t\tattack_speed_mult -= 0\.5', hunger, content)

    with open(filepath, "w") as f:
        f.write(content)
    print("Done patching player review fixes")

if __name__ == "__main__":
    main()
