class_name HitboxComponent
extends Area2D

## Hitbox Area2D component that delivers DamageData to overlapping HurtboxComponents.
## Uses collision layers/masks and optional team_index to filter targets.

signal hit_landed(hurtbox: HurtboxComponent, damage_data: DamageData)

@export var damage_amount: float = 10.0
@export_flags("PHYSICAL:1", "DARK:2", "FIRE:4", "ICE:8")
var damage_type: int = DamageData.DamageType.PHYSICAL
@export var knockback_force: float = 50.0
@export var team_index: int = 0
@export var custom_damage_data: DamageData = null
@export var hit_source: Node2D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = true
	monitorable = true

func get_effective_damage_data(target_pos: Vector2) -> DamageData:
	if custom_damage_data != null:
		var copy := custom_damage_data.duplicate_data()
		if copy.knockback_direction == Vector2.ZERO and target_pos != global_position:
			copy.knockback_direction = (target_pos - global_position).normalized()
		if copy.source == null:
			copy.source = hit_source if hit_source != null else (owner as Node2D)
		return copy

	var kb_dir := (target_pos - global_position).normalized() if target_pos != global_position else Vector2.ZERO
	var src: Node2D = hit_source if hit_source != null else (owner as Node2D)
	return DamageData.new(damage_amount, damage_type, knockback_force, kb_dir, src)

func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox == null:
		return
	if hurtbox.team_index == team_index:
		return

	var data := get_effective_damage_data(hurtbox.global_position)
	hurtbox.receive_hit(data)
	hit_landed.emit(hurtbox, data)
