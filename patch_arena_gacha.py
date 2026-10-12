import re

def main():
    filepath = "scripts/arena/arena.gd"
    with open(filepath, "r") as f:
        content = f.read()

    new_cases = """		# Cartas R
		"vorpal_sword":
			player.vorpal_sword_unlocked = true
			player._apply_weapon_mode()
		"alpha_strike":
			player.alpha_strike_unlocked = true
		"wind_momentum":
			player.wind_momentum_unlocked = true
		"spread_shot":
			player.set_meta("spread_shot_unlocked", true)
		# Cartas SR
		"spin_attack":
			player.spin_attack_unlocked = true
		"glacial_prison":
			player.set_meta("glacial_prison_unlocked", true)
		"insatiable_hunger":
			player.insatiable_hunger_unlocked = true
		"solar_flare":
			player.set_meta("solar_flare_unlocked", true)
		# Cartas SSR
		"cosmic_rupture":
			player.cosmic_rupture_unlocked = true
		"void_feast":
			player.void_feast_unlocked = true
		"noxian_guillotine":
			player.noxian_guillotine_unlocked = true
		"ancestral_resurrect":
			player.ancestral_resurrect_unlocked = true
		# Cartas EX
		"glyph_fury":
			player.set_meta("glyph_fury_unlocked", true)
		"demigod_forge":
			gacha_screen.demigod_forge_active = true
		# Cartas Boss
		"realm_of_death":
			player.set_meta("realm_of_death_unlocked", true)"""

    content = content.replace('		# Cartas de Roubo de Chefe (Boss Theft)', new_cases + '\n\t\t# Cartas de Roubo de Chefe (Boss Theft)')

    boss_spawn = """func _spawn_boss() -> void:
	_boss_spawned = true
	var boss := enemy_scene.instantiate() as Enemy
	if boss != null:
		boss.set_type(Enemy.EnemyType.DEMON_BOSS)
		boss.global_position = player.global_position + Vector2(0, -380)

		if player != null and is_instance_valid(player) and player.has_meta("realm_of_death_unlocked") and player.get_meta("realm_of_death_unlocked"):
			boss.max_health *= 0.85
			boss.contact_damage *= 0.85
			boss.health_component.max_health = boss.max_health
			boss.health_component.current_health = boss.max_health
			boss.hitbox_component.damage_amount = boss.contact_damage

			player.damage_mult += 0.15
			player.health_component.max_health += player.health_component.max_health * 0.15
			player.health_component.current_health += player.health_component.max_health * 0.15
			hud.update_health(player.health_component.current_health, player.health_component.max_health)

		add_child(boss)"""

    content = re.sub(r'func _spawn_boss\(\) -> void:\n\t_boss_spawned = true\n\tvar boss := enemy_scene\.instantiate\(\) as Enemy\n\tif boss != null:\n\t\tboss\.set_type\(Enemy\.EnemyType\.DEMON_BOSS\)\n\t\tboss\.global_position = player\.global_position \+ Vector2\(0, -380\)\n\t\tadd_child\(boss\)', boss_spawn, content)

    with open(filepath, "w") as f:
        f.write(content)
    print("Done patching arena.gd for gacha cards")

if __name__ == "__main__":
    main()
