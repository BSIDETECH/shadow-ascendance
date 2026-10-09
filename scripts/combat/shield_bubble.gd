class_name ShieldBubble
extends Area2D

## Aegis Shield defensive dome created by Paladin.
## Reduces incoming damage to allies and player inside the dome by 30%.

@export var damage_reduction: float = 0.30
@export var radius: float = 55.0
@export var lifetime: float = 5.0

var _time_alive: float = 0.0
var _affected_health_components: Array[HealthComponent] = []

func _ready() -> void:
	collision_layer = 0
	# Monitor layers: Player (2) and Companion (64)
	collision_mask = 2 | 64
	monitoring = true
	monitorable = false

	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		shape = CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		add_child(shape)
	elif shape.shape is CircleShape2D:
		(shape.shape as CircleShape2D).radius = radius

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	queue_redraw()

func _physics_process(delta: float) -> void:
	_time_alive += delta
	if _time_alive >= lifetime:
		_fade_and_remove()

func _draw() -> void:
	# Draw translucent glowing dome
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.9, 0.3, 0.18))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.2, 1.1, 0.5, 0.75), 1.5)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("allies") or body.is_in_group("companions") or body.is_in_group("player"):
		_apply_buff_to_node(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("allies") or body.is_in_group("companions") or body.is_in_group("player"):
		_remove_buff_from_node(body)

func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox != null and hurtbox.team_index == 0:
		if hurtbox.health_component != null:
			_apply_buff_to_health(hurtbox.health_component)

func _on_area_exited(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox != null and hurtbox.team_index == 0:
		if hurtbox.health_component != null:
			_remove_buff_from_health(hurtbox.health_component)

func _apply_buff_to_node(node: Node2D) -> void:
	var hc := node.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null and node.get("health_component") != null:
		hc = node.get("health_component") as HealthComponent
	if hc != null:
		_apply_buff_to_health(hc)

func _remove_buff_from_node(node: Node2D) -> void:
	var hc := node.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null and node.get("health_component") != null:
		hc = node.get("health_component") as HealthComponent
	if hc != null:
		_remove_buff_from_health(hc)

func _apply_buff_to_health(hc: HealthComponent) -> void:
	if not _affected_health_components.has(hc):
		_affected_health_components.append(hc)
		hc.external_damage_mitigation = maxf(hc.external_damage_mitigation, damage_reduction)

func _remove_buff_from_health(hc: HealthComponent) -> void:
	if _affected_health_components.has(hc):
		_affected_health_components.erase(hc)
		if is_instance_valid(hc):
			hc.external_damage_mitigation = 0.0

func _fade_and_remove() -> void:
	set_physics_process(false)
	_clear_all_buffs()
	var tween := create_tween()
	if tween != null:
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _clear_all_buffs() -> void:
	for hc in _affected_health_components:
		if hc != null and is_instance_valid(hc):
			hc.external_damage_mitigation = 0.0
	_affected_health_components.clear()

func _exit_tree() -> void:
	_clear_all_buffs()
