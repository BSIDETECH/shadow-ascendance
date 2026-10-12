import re

def main():
    filepath = "scripts/entities/player.gd"
    with open(filepath, "r") as f:
        content = f.read()

    new_vars = """var kill_counter: int = 0
@export var weapon_unlocked: bool = false # Starts unarmed: single-target punch ("soquinho")

# New Gacha Flags
var vorpal_sword_unlocked: bool = false
var alpha_strike_unlocked: bool = false
var wind_momentum_unlocked: bool = false
var spin_attack_unlocked: bool = false
var insatiable_hunger_unlocked: bool = false
var cosmic_rupture_unlocked: bool = false
var void_feast_unlocked: bool = false
var noxian_guillotine_unlocked: bool = false
var ancestral_resurrect_unlocked: bool = false

var _wind_distance: float = 0.0
var _spin_timer: float = 0.0
var _is_spinning: bool = false
var _ancestral_used: bool = false
var void_feast_stacks: int = 0"""

    content = content.replace('var kill_counter: int = 0\n@export var weapon_unlocked: bool = false # Starts unarmed: single-target punch ("soquinho")', new_vars)

    weapon_mode_mod = """func _apply_weapon_mode() -> void:
	if slash_collision != null:
		slash_collision.polygon = WEAPON_POLYGON if weapon_unlocked else PUNCH_POLYGON
	if slash_visual != null:
		slash_visual.polygon = WEAPON_POLYGON if weapon_unlocked else PUNCH_POLYGON
	if slash_hitbox != null:
		slash_hitbox.damage_type = DamageData.DamageType.DARK if weapon_unlocked else DamageData.DamageType.PHYSICAL
		if vorpal_sword_unlocked:
			slash_hitbox.scale = Vector2(1.25, 1.25)
		else:
			slash_hitbox.scale = Vector2.ONE"""

    content = re.sub(r'func _apply_weapon_mode\(\) -> void:\n\tif slash_collision != null:\n\t\tslash_collision\.polygon = WEAPON_POLYGON if weapon_unlocked else PUNCH_POLYGON\n\tif slash_visual != null:\n\t\tslash_visual\.polygon = WEAPON_POLYGON if weapon_unlocked else PUNCH_POLYGON\n\tif slash_hitbox != null:\n\t\tslash_hitbox\.damage_type = DamageData\.DamageType\.DARK if weapon_unlocked else DamageData\.DamageType\.PHYSICAL', weapon_mode_mod, content)

    with open(filepath, "w") as f:
        f.write(content)
    print("Done patching player.gd variables")

if __name__ == "__main__":
    main()
