import re

def main():
    # 1. EventBus - add spell_casted
    with open("scripts/autoloads/event_bus.gd", "r") as f:
        eb = f.read()
    eb = eb.replace("signal damage_dealt(target: Node, damage_data: DamageData)", "signal spell_casted()\nsignal damage_dealt(target: Node, damage_data: DamageData)")
    with open("scripts/autoloads/event_bus.gd", "w") as f:
        f.write(eb)

    # 2. Fireball - spread_shot
    with open("scripts/entities/fireball.gd", "r") as f:
        fb = f.read()
    fb_exp = """func _explode() -> void:
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0

	# Deal AoE damage to all enemies within radius
	var space := get_world_2d().direct_space_state
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Node2D and is_instance_valid(e):
			var dist := global_position.distance_to((e as Node2D).global_position)
			if dist <= aoe_radius:
				var hurtbox := (e as Node2D).get_node_or_null("HurtboxComponent") as HurtboxComponent
				if hurtbox != null:
					var kb_dir := ((e as Node2D).global_position - global_position).normalized()
					var data := DamageData.new(
						damage,
						DamageData.DamageType.FIRE,
						90.0,
						kb_dir,
						self
					)
					hurtbox.receive_hit(data)

	# Spread Shot logic
	var p = get_tree().get_first_node_in_group("player")
	if p != null and p.has_meta("spread_shot_unlocked") and p.get_meta("spread_shot_unlocked") and not has_meta("is_bounced"):
		var nearest = null
		var min_dist = 99999.0
		for e in enemies:
			if e is Node2D and is_instance_valid(e) and global_position.distance_to(e.global_position) > aoe_radius:
				var dist = global_position.distance_to(e.global_position)
				if dist < min_dist and dist < 200.0:
					min_dist = dist
					nearest = e
		if nearest != null:
			var new_fb = load("res://scenes/entities/projectile/fireball.tscn").instantiate()
			new_fb.global_position = global_position
			new_fb.direction = (nearest.global_position - global_position).normalized()
			new_fb.damage = damage
			new_fb.set_meta("is_bounced", true)
			get_parent().add_child(new_fb)"""
    fb = re.sub(r'func _explode\(\) -> void:\n\tset_physics_process\(false\)\n\tcollision_layer = 0\n\tcollision_mask = 0\n\n\t# Deal AoE damage to all enemies within radius\n\tvar space := get_world_2d\(\)\.direct_space_state\n\tvar enemies := get_tree\(\)\.get_nodes_in_group\("enemies"\)\n\tfor e in enemies:\n\t\tif e is Node2D and is_instance_valid\(e\):\n\t\t\tvar dist := global_position\.distance_to\(\(e as Node2D\)\.global_position\)\n\t\t\tif dist <= aoe_radius:\n\t\t\t\tvar hurtbox := \(e as Node2D\)\.get_node_or_null\("HurtboxComponent"\) as HurtboxComponent\n\t\t\t\tif hurtbox != null:\n\t\t\t\t\tvar kb_dir := \(\(e as Node2D\)\.global_position - global_position\)\.normalized\(\)\n\t\t\t\t\tvar data := DamageData\.new\(\n\t\t\t\t\t\tdamage,\n\t\t\t\t\t\tDamageData\.DamageType\.FIRE,\n\t\t\t\t\t\t90\.0,\n\t\t\t\t\t\tkb_dir,\n\t\t\t\t\t\tself\n\t\t\t\t\t\)\n\t\t\t\t\thurtbox\.receive_hit\(data\)', fb_exp, fb)
    with open("scripts/entities/fireball.gd", "w") as f:
        f.write(fb)

    # 3. IceSpike - glacial_prison
    with open("scripts/entities/ice_spike.gd", "r") as f:
        ice = f.read()
    ice_slow = """func _apply_ice_slow(entity: Node) -> void:
	var actual_factor = slow_factor
	var p = get_tree().get_first_node_in_group("player")
	var is_glacial = (p != null and p.has_meta("glacial_prison_unlocked") and p.get_meta("glacial_prison_unlocked"))
	if is_glacial:
		actual_factor = 1.0 # Root/Freeze

	if entity.has_method("apply_slow"):
		entity.apply_slow(actual_factor, slow_duration)
	elif entity.get("_slow_timer") != null and entity.get("_slow_factor") != null:
		entity.set("_slow_factor", maxf(float(entity.get("_slow_factor")), actual_factor))
		entity.set("_slow_timer", maxf(float(entity.get("_slow_timer")), slow_duration))

	if is_glacial and entity is Node2D:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if e != entity and is_instance_valid(e) and (e as Node2D).global_position.distance_to(entity.global_position) <= 60.0:
				if e.has_method("apply_slow"): e.apply_slow(1.0, 1.5)
				elif e.get("_slow_timer") != null:
					e.set("_slow_factor", 1.0)
					e.set("_slow_timer", 1.5)"""
    ice = re.sub(r'func _apply_ice_slow\(entity: Node\) -> void:\n\tif entity\.has_method\("apply_slow"\):\n\t\tentity\.apply_slow\(slow_factor, slow_duration\)\n\telif entity\.get\("_slow_timer"\) != null and entity\.get\("_slow_factor"\) != null:\n\t\tentity\.set\("_slow_factor", maxf\(float\(entity\.get\("_slow_factor"\)\), slow_factor\)\)\n\t\tentity\.set\("_slow_timer", maxf\(float\(entity\.get\("_slow_timer"\)\), slow_duration\)\)', ice_slow, ice)
    with open("scripts/entities/ice_spike.gd", "w") as f:
        f.write(ice)

    # 4. Companion (Furia dos Glifos)
    with open("scripts/entities/companion.gd", "r") as f:
        comp = f.read()
    comp = comp.replace("super._ready()", "super._ready()\n\tEventBus.spell_casted.connect(func(): if has_meta(\"glyph_fury_unlocked\") or (get_tree().get_first_node_in_group(\"player\") and get_tree().get_first_node_in_group(\"player\").has_meta(\"glyph_fury_unlocked\")): _cast_timer *= 0.5)")
    comp = comp.replace("var base_dir := (target_node.global_position - global_position).normalized()", "EventBus.spell_casted.emit()\n\n\tvar base_dir := (target_node.global_position - global_position).normalized()")
    with open("scripts/entities/companion.gd", "w") as f:
        f.write(comp)

    # 5. CompanionBase (Solar Flare marking)
    with open("scripts/entities/companion_base.gd", "r") as f:
        comp_b = f.read()
    comp_b_cb = """func _handle_combat(_delta: float) -> void:
	# Virtual method for subclasses to override
	var p = get_tree().get_first_node_in_group("player")
	if p != null and p.has_meta("solar_flare_unlocked") and p.get_meta("solar_flare_unlocked"):
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e is Node2D and global_position.distance_to(e.global_position) <= 60.0:
				e.set_meta("marked_by_solar", true)"""
    comp_b = comp_b.replace("func _handle_combat(_delta: float) -> void:\n\t# Virtual method for subclasses to override\n\tpass", comp_b_cb)
    with open("scripts/entities/companion_base.gd", "w") as f:
        f.write(comp_b)

    print("Done patching companions and projectiles")

if __name__ == "__main__":
    main()
