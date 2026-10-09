class_name HurtboxComponent
extends Area2D

## Hurtbox Area2D component that routes incoming hits to a HealthComponent.
## Emits hit_received signal upon successfully receiving a valid hit.

signal hit_received(damage_data: DamageData)

@export var health_component: HealthComponent = null
@export var team_index: int = 0

func _ready() -> void:
	if health_component == null:
		_auto_discover_health_component()
	monitorable = true

func _auto_discover_health_component() -> void:
	if get_parent() is HealthComponent:
		health_component = get_parent() as HealthComponent
		return
	if get_parent() != null:
		var sibling := get_parent().get_node_or_null("HealthComponent") as HealthComponent
		if sibling != null:
			health_component = sibling
			return
	if owner != null:
		var owner_health := owner.get_node_or_null("HealthComponent") as HealthComponent
		if owner_health != null:
			health_component = owner_health

func receive_hit(data: DamageData) -> void:
	if data == null:
		return
	if health_component != null and health_component.is_alive():
		health_component.take_damage(data)
		hit_received.emit(data)

## Duck-typing fallback for generic damage invokers.
func take_damage(data_or_amount: Variant, maybe_knockback: Vector2 = Vector2.ZERO) -> void:
	if data_or_amount is DamageData:
		receive_hit(data_or_amount)
	elif data_or_amount is float or data_or_amount is int:
		var kb_force := maybe_knockback.length()
		var kb_dir := maybe_knockback.normalized() if kb_force > 0.0 else Vector2.ZERO
		var data := DamageData.new(float(data_or_amount), DamageData.DamageType.PHYSICAL, kb_force, kb_dir, null)
		receive_hit(data)
