import re

def main():
    filepath = "scripts/entities/player.gd"
    with open(filepath, "r") as f:
        content = f.read()

    # _physics_process
    phys_process = """func _physics_process(delta: float) -> void:
	_handle_timers(delta)
	_handle_aim()
	_handle_movement(delta)
	_handle_combat()
	_handle_fire_pulse(delta)
	_handle_spin(delta)
	_attract_nearby_gems()"""
    content = content.replace("func _physics_process(delta: float) -> void:\n\t_handle_timers(delta)\n\t_handle_aim()\n\t_handle_movement(delta)\n\t_handle_combat()\n\t_handle_fire_pulse(delta)\n\t_attract_nearby_gems()", phys_process)

    # _handle_spin
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
			move_speed_mult /= 1.2 # Reset from a hypothetical speed boost or ignore slow
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
    content = content.replace("func _handle_timers(delta: float) -> void:", spin_func + "\n\nfunc _handle_timers(delta: float) -> void:")

    # _handle_movement (wind momentum & alpha strike)
    handle_mov = """func _handle_movement(delta: float) -> void:
	if _is_dashing:
		velocity = _dash_direction * dash_speed
		move_and_slide()
		if alpha_strike_unlocked:
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) < 45.0:
					var hurtbox = e.get_node_or_null("HurtboxComponent")
					if hurtbox:
						var dmg = DamageData.new(base_damage * damage_mult, DamageData.DamageType.PHYSICAL, 0.0, Vector2.ZERO, self)
						hurtbox.receive_hit(dmg)
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		_last_move_dir = input_vector.normalized()
		velocity = input_vector * (base_speed * move_speed_mult)
		sprite.flip_h = input_vector.x < 0.0

		if wind_momentum_unlocked:
			_wind_distance += velocity.length() * delta
			if _wind_distance >= 500.0:
				_wind_distance = 0.0
				health_component.external_damage_mitigation = 0.5
				var tw = create_tween()
				tw.tween_property(health_component, "external_damage_mitigation", 0.0, 2.0)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)"""
    content = re.sub(r'func _handle_movement\(delta: float\) -> void:\n\tif _is_dashing:\n\t\tvelocity = _dash_direction \* dash_speed\n\t\tmove_and_slide\(\)\n\t\treturn\n\n\tvar input_vector := Input\.get_vector\("move_left", "move_right", "move_up", "move_down"\)\n\tif input_vector != Vector2\.ZERO:\n\t\t_last_move_dir = input_vector\.normalized\(\)\n\t\tvelocity = input_vector \* \(base_speed \* move_speed_mult\)\n\t\tsprite\.flip_h = input_vector\.x < 0\.0\n\telse:\n\t\tvelocity = velocity\.move_toward\(Vector2\.ZERO, 900\.0 \* delta\)', handle_mov, content)

    # _execute_shadow_slash (vorpal sword & noxian guillotine & solar flare)
    execute_slash = """func _execute_shadow_slash() -> void:
	_attack_timer = attack_cooldown / attack_speed_mult
	var current_damage := base_damage * damage_mult
	if executioner_unlocked and randf() < 0.20:
		current_damage *= 3.0 # Dano triplo carrasco

	slash_hitbox.damage_amount = current_damage
	slash_hitbox.monitoring = true
	slash_visual.visible = true

	# Immediate hit detection for Vorpal, Noxian, and Solar Flare
	await get_tree().physics_frame # ensure physics state is updated
	var enemies = slash_hitbox.get_overlapping_areas()
	for area in enemies:
		if area is HurtboxComponent and area.team_index != 0:
			var target = area.owner if area.owner else area.get_parent()
			if is_instance_valid(target):
				var extra_dmg = 0.0
				if target.has_meta("marked_by_solar") and target.get_meta("marked_by_solar"):
					extra_dmg += 40.0 * damage_mult
					target.set_meta("marked_by_solar", false)
				if vorpal_sword_unlocked:
					var target_health = target.get_node_or_null("HealthComponent")
					if target_health:
						extra_dmg += target_health.max_health * 0.05
				if noxian_guillotine_unlocked:
					var target_health = target.get_node_or_null("HealthComponent")
					if target_health and target_health.current_health < target_health.max_health * 0.3:
						extra_dmg += 9999.0
						# Fear
						var all_enemies = get_tree().get_nodes_in_group("enemies")
						for e in all_enemies:
							if e != target and is_instance_valid(e) and global_position.distance_to(e.global_position) < 150.0:
								if e.has_method("apply_stun"): e.apply_stun(1.5)
				if extra_dmg > 0.0:
					var kb_dir = (target.global_position - global_position).normalized()
					var data = DamageData.new(extra_dmg, DamageData.DamageType.DARK, 50.0, kb_dir, self)
					area.receive_hit(data)

	if not weapon_unlocked:"""
    content = re.sub(r'func _execute_shadow_slash\(\) -> void:\n\t_attack_timer = attack_cooldown \/ attack_speed_mult\n\tvar current_damage := base_damage \* damage_mult\n\tif executioner_unlocked and randf\(\) < 0\.20:\n\t\tcurrent_damage \*= 3\.0 # Dano triplo carrasco\n\n\tslash_hitbox\.damage_amount = current_damage\n\tslash_hitbox\.monitoring = true\n\tslash_visual\.visible = true\n\n\tif not weapon_unlocked:', execute_slash, content)

    # _on_enemy_killed (cosmic rupture & void feast)
    on_enemy_kill = """func _on_enemy_killed(_pos: Vector2, _xp: int) -> void:
	kill_counter += 1
	if lifesteal_on_kill > 0.0:
		health_component.current_health = minf(health_component.max_health, health_component.current_health + lifesteal_on_kill)
		health_component.health_changed.emit(health_component.current_health, health_component.max_health)

	if abyssal_burst_unlocked and (kill_counter % 6 == 0):
		_trigger_abyssal_burst()

	if cosmic_rupture_unlocked and (kill_counter % 20 == 0):
		var mouse_dir = (get_global_mouse_position() - global_position).normalized()
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e):
				var e_dir = (e.global_position - global_position).normalized()
				if e_dir.dot(mouse_dir) > 0.9: # Narrow angle cone / laser
					var hurtbox = e.get_node_or_null("HurtboxComponent")
					if hurtbox:
						var data = DamageData.new(80.0 * damage_mult, DamageData.DamageType.DARK, 100.0, mouse_dir, self)
						hurtbox.receive_hit(data)

	if void_feast_unlocked and _xp > 10 and void_feast_stacks < 10:
		void_feast_stacks += 1
		health_component.max_health += 20.0
		health_component.current_health += 20.0
		sprite.scale *= 1.05
		damage_mult += 0.05
		hud.update_health(health_component.current_health, health_component.max_health)"""

    # replace first occurence properly, but we can't easily rely on hud in player.gd without getting it. player doesn't have hud directly, it's emitted via EventBus.
    # so we will use health_component.health_changed.emit.

    on_enemy_kill = """func _on_enemy_killed(_pos: Vector2, _xp: int) -> void:
	kill_counter += 1
	if lifesteal_on_kill > 0.0:
		health_component.current_health = minf(health_component.max_health, health_component.current_health + lifesteal_on_kill)
		health_component.health_changed.emit(health_component.current_health, health_component.max_health)

	if abyssal_burst_unlocked and (kill_counter % 6 == 0):
		_trigger_abyssal_burst()

	if cosmic_rupture_unlocked and (kill_counter % 20 == 0):
		var mouse_dir = (get_global_mouse_position() - global_position).normalized()
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e):
				var e_dir = (e.global_position - global_position).normalized()
				if e_dir.dot(mouse_dir) > 0.9: # Narrow angle cone / laser
					var hurtbox = e.get_node_or_null("HurtboxComponent")
					if hurtbox:
						var data = DamageData.new(80.0 * damage_mult, DamageData.DamageType.DARK, 100.0, mouse_dir, self)
						hurtbox.receive_hit(data)

	if void_feast_unlocked and _xp >= 10 and void_feast_stacks < 10:
		void_feast_stacks += 1
		health_component.max_health += 20.0
		health_component.current_health += 20.0
		sprite.scale *= 1.05
		damage_mult += 0.05
		health_component.health_changed.emit(health_component.current_health, health_component.max_health)"""

    content = re.sub(r'func _on_enemy_killed\(_pos: Vector2, _xp: int\) -> void:\n\tkill_counter \+= 1\n\tif lifesteal_on_kill > 0\.0:\n\t\thealth_component\.current_health = minf\(health_component\.max_health, health_component\.current_health \+ lifesteal_on_kill\)\n\t\thealth_component\.health_changed\.emit\(health_component\.current_health, health_component\.max_health\)\n\n\tif abyssal_burst_unlocked and \(kill_counter % 6 == 0\):\n\t\t_trigger_abyssal_burst\(\)', on_enemy_kill, content)

    # _on_health_changed (insatiable hunger)
    on_hp_change = """func _on_health_changed(current: float, max_hp: float) -> void:
	EventBus.emit_player_health_changed(current, max_hp)
	if insatiable_hunger_unlocked:
		if current <= max_hp * 0.5:
			if not has_meta("hunger_active"):
				set_meta("hunger_active", true)
				lifesteal_on_kill = (lifesteal_on_kill if lifesteal_on_kill > 0 else 2.0) * 3.0
				attack_speed_mult += 0.5
		else:
			if has_meta("hunger_active"):
				remove_meta("hunger_active")
				lifesteal_on_kill /= 3.0
				attack_speed_mult -= 0.5"""
    content = content.replace("func _on_health_changed(current: float, max_hp: float) -> void:\n\tEventBus.emit_player_health_changed(current, max_hp)", on_hp_change)

    # _on_died (ancestral resurrect)
    on_died = """func _on_died() -> void:
	if ancestral_resurrect_unlocked and not _ancestral_used:
		_ancestral_used = true
		health_component.current_health = health_component.max_health * 0.5
		health_component.health_changed.emit(health_component.current_health, health_component.max_health)
		# Stasis logic (pause for 2s)
		can_attack = false
		combat_enabled = false
		var tw = create_tween()
		tw.tween_callback(func():
			can_attack = true
			combat_enabled = true
			health_component.is_invincible = false
		).set_delay(2.0)
		health_component.is_invincible = true
		return

	if is_dead:"""
    content = content.replace("func _on_died() -> void:\n\tif is_dead:", on_died)

    with open(filepath, "w") as f:
        f.write(content)
    print("Done patching player combat mechanics")

if __name__ == "__main__":
    main()
