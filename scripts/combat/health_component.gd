class_name HealthComponent
extends Node

## Health management component supporting damage handling, healing, and i-frames.
## Adheres strictly to the godot-combat-system pattern.

signal health_changed(current: float, max_health: float)
signal took_damage(damage_data: DamageData)
signal died()
signal healed(amount: float)
signal invincibility_started()
signal invincibility_ended()

@export var max_health: float = 100.0:
	set(val):
		max_health = maxf(1.0, val)
		if current_health > max_health:
			current_health = max_health
			health_changed.emit(current_health, max_health)

@export var current_health: float = 100.0
@export_range(0.0, 1.0) var armor_reduction: float = 0.0
@export_range(0.0, 1.0) var external_damage_mitigation: float = 0.0
@export var i_frame_duration: float = 0.2
@export var is_invincible: bool = false
@export var disable_collision_on_death: bool = true

var _i_frame_timer: float = 0.0

func _ready() -> void:
	current_health = minf(current_health, max_health)

func _physics_process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	if _i_frame_timer > 0.0:
		_i_frame_timer -= delta
		if _i_frame_timer <= 0.0:
			_i_frame_timer = 0.0
			invincibility_ended.emit()

func is_currently_invincible() -> bool:
	return is_invincible or _i_frame_timer > 0.0

func is_alive() -> bool:
	return current_health > 0.0

func take_damage(data: DamageData) -> void:
	if data == null or not is_alive() or is_currently_invincible():
		return

	var damage_amount: float = data.amount
	if armor_reduction > 0.0:
		damage_amount *= (1.0 - armor_reduction)
	if external_damage_mitigation > 0.0:
		damage_amount *= (1.0 - external_damage_mitigation)

	var old_health := current_health
	current_health = maxf(0.0, current_health - damage_amount)
	health_changed.emit(current_health, max_health)
	took_damage.emit(data)

	if current_health <= 0.0:
		_on_death()
	else:
		if i_frame_duration > 0.0:
			_i_frame_timer = i_frame_duration
			invincibility_started.emit()

func heal(amount: float) -> void:
	if amount <= 0.0 or not is_alive():
		return
	var old_health := current_health
	current_health = minf(max_health, current_health + amount)
	var gained := current_health - old_health
	if gained > 0.0:
		healed.emit(gained)
		health_changed.emit(current_health, max_health)

func set_invincible_duration(duration: float) -> void:
	if duration > 0.0:
		_i_frame_timer = maxf(_i_frame_timer, duration)
		invincibility_started.emit()

func reset_health() -> void:
	current_health = max_health
	_i_frame_timer = 0.0
	health_changed.emit(current_health, max_health)

func _on_death() -> void:
	died.emit()
	if not disable_collision_on_death:
		return
	var host: Node = owner if owner != null else get_parent()
	if host == null:
		return
	for child in host.find_children("*", "CollisionShape2D", true, false):
		var shape := child as CollisionShape2D
		if shape != null:
			shape.set_deferred("disabled", true)
