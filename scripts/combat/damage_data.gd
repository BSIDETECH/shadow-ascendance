class_name DamageData
extends Resource

## Typed combat payload for "Shadow Cheat: Solo Guild Ascendance".
## Elemental and damage categories are bitflags to avoid raw string checks.

enum DamageType {
	PHYSICAL = 1,
	DARK = 2,
	FIRE = 4,
	ICE = 8,
	LIGHTNING = 16,
}

@export var amount: float = 10.0
@export_flags("PHYSICAL:1", "DARK:2", "FIRE:4", "ICE:8", "LIGHTNING:16")
var damage_type: int = DamageType.PHYSICAL
@export var knockback_force: float = 50.0
@export var knockback_direction: Vector2 = Vector2.ZERO
var source: Node2D = null

func _init(
	p_amount: float = 10.0,
	p_type: int = DamageType.PHYSICAL,
	p_kb_force: float = 50.0,
	p_kb_dir: Vector2 = Vector2.ZERO,
	p_source: Node2D = null
) -> void:
	amount = p_amount
	damage_type = p_type
	knockback_force = p_kb_force
	knockback_direction = p_kb_dir
	source = p_source

func has_type(type_flag: int) -> bool:
	return (damage_type & type_flag) != 0

func get_knockback_velocity() -> Vector2:
	if knockback_direction == Vector2.ZERO or knockback_force <= 0.0:
		return Vector2.ZERO
	return knockback_direction.normalized() * knockback_force

func duplicate_data() -> DamageData:
	var copy := duplicate(true) as DamageData
	if copy == null:
		copy = DamageData.new(amount, damage_type, knockback_force, knockback_direction, source)
	return copy
