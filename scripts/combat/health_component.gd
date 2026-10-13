class_name HealthComponent
extends Node

## Health management component supporting damage handling, healing, and i-frames.
## Adheres strictly to the godot-combat-system pattern.

signal health_changed(current: float, max_health: float)
signal shield_changed(current: float, max_shield: float)
signal took_damage(damage_data: DamageData)
signal died()
signal downed()
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
@export var can_be_downed: bool = false
var is_downed: bool = false

@export var shield_health: float = 0.0:
	set(val):
		shield_health = maxf(0.0, val)
		shield_changed.emit(shield_health, max_shield)
@export var max_shield: float = 0.0

var _shield_decay_rate: float = 0.0
var _i_frame_timer: float = 0.0

func _ready() -> void:
	current_health = minf(current_health, max_health)

func _physics_process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	if shield_health > 0.0 and _shield_decay_rate > 0.0:
		shield_health = maxf(0.0, shield_health - (_shield_decay_rate * delta))

	if _i_frame_timer > 0.0:
		_i_frame_timer -= delta
		if _i_frame_timer <= 0.0:
			_i_frame_timer = 0.0
			invincibility_ended.emit()

func is_currently_invincible() -> bool:
	return is_invincible or _i_frame_timer > 0.0

func apply_shield(amount: float, duration: float = 0.0) -> void:
	max_shield = amount
	shield_health = amount
	if duration > 0.0:
		_shield_decay_rate = amount / duration
	else:
		_shield_decay_rate = 0.0
	shield_changed.emit(shield_health, max_shield)

func is_alive() -> bool:
	return current_health > 0.0

func take_damage(data: DamageData) -> void:
	if data == null or data.amount <= 0.0 or not is_alive() or is_currently_invincible():
		return

	var damage_amount: float = maxf(0.0, data.amount)
	if armor_reduction > 0.0:
		damage_amount *= (1.0 - armor_reduction)
	if external_damage_mitigation > 0.0:
		damage_amount *= (1.0 - external_damage_mitigation)

	if shield_health > 0.0:
		if shield_health >= damage_amount:
			shield_health -= damage_amount
			damage_amount = 0.0
		else:
			damage_amount -= shield_health
			shield_health = 0.0
		shield_changed.emit(shield_health, max_shield)

		# Allow EventBus to bubble it if needed
		var eb = get_tree().root.get_node_or_null("EventBus")
		if eb and eb.has_signal("player_shield_changed") and self.get_parent() is Player:
			eb.player_shield_changed.emit(shield_health, max_shield)
	current_health = maxf(0.0, current_health - damage_amount)
	health_changed.emit(current_health, max_health)
	took_damage.emit(data)
	if is_inside_tree():
		var eb = get_node_or_null("/root/EventBus")
		if eb != null:
			eb.emit_damage_dealt(get_parent(), data)

	if current_health <= 0.0:
		if can_be_downed and not is_downed:
			is_downed = true
			current_health = 0.01 # Keep a tiny amount of HP so it's technically alive for healing
			health_changed.emit(0.0, max_health) # Visual 0
			downed.emit()
		elif not is_downed:
			_on_death()
	else:
		if i_frame_duration > 0.0 and damage_amount > 0.0:
			_i_frame_timer = i_frame_duration
			invincibility_started.emit()

func heal(amount: float) -> void:
	if amount <= 0.0 or (not is_alive() and not is_downed):
		return
	var old_health := current_health
	if is_downed:
		is_downed = false
		current_health = 0.0 # Clear the 0.01

	current_health = minf(max_health, current_health + amount)
	var gained := current_health - old_health
	if gained > 0.0:
		healed.emit(gained)
		health_changed.emit(current_health, max_health)

func add_shield(amount: float) -> void:
	if amount <= 0.0 or not is_alive():
		return
	shield_health += amount
	max_shield = maxf(max_shield, shield_health)
	shield_changed.emit(shield_health, max_shield)
	var eb = get_tree().root.get_node_or_null("EventBus")
	if eb and eb.has_signal("player_shield_changed") and self.get_parent() is Player:
		eb.player_shield_changed.emit(shield_health, max_shield)

func set_invincible_duration(duration: float) -> void:
	if duration > 0.0:
		_i_frame_timer = maxf(_i_frame_timer, duration)
		invincibility_started.emit()

func reset_health() -> void:
	current_health = max_health
	_i_frame_timer = 0.0
	is_downed = false
	health_changed.emit(current_health, max_health)

func force_kill() -> void:
	if current_health > 0.0:
		current_health = 0.0
		health_changed.emit(current_health, max_health)
	_on_death()

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
