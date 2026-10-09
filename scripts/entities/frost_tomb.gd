class_name FrostTomb
extends StaticBody2D

## Frost Tomb companion trap spawned by Rank D Boss Glacies.
## Encasing a companion: freezes their actions for up to 6.0s.
## Breaking the tomb's HealthComponent before 6.0s frees the companion
## and logs a telemetry rescue. If the companion dies, the tomb despawns immediately.

signal companion_rescued(companion: Node)
signal companion_executed(companion: Node)
signal tomb_destroyed()

@export var max_health: float = 60.0
@export var trap_timeout: float = 6.0
var current_health: float = 60.0
var timer: float = 6.0
var is_broken: bool = false
var trapped_companion: Node2D = null

var health_component: HealthComponent = null
var hurtbox_component: HurtboxComponent = null
var collision_shape: CollisionShape2D = null

func _init(p_companion: Node2D = null) -> void:
	trapped_companion = p_companion
	_setup_components()
	if trapped_companion != null and is_instance_valid(trapped_companion):
		_trap_target(trapped_companion)

func _ready() -> void:
	collision_layer = 1 # World obstacle
	collision_mask = 0
	add_to_group("frost_tombs")
	_setup_components()

	if trapped_companion != null and is_instance_valid(trapped_companion):
		_trap_target(trapped_companion)

func _setup_components() -> void:
	if health_component == null:
		health_component = get_node_or_null("HealthComponent") as HealthComponent
	if health_component == null:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		add_child(health_component)

	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.i_frame_duration = 0.0
	current_health = max_health
	if not health_component.died.is_connected(_on_tomb_broken):
		health_component.died.connect(_on_tomb_broken)
	if not health_component.took_damage.is_connected(_on_took_damage):
		health_component.took_damage.connect(_on_took_damage)

	if hurtbox_component == null:
		hurtbox_component = get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox_component == null:
		hurtbox_component = HurtboxComponent.new()
		hurtbox_component.name = "HurtboxComponent"
		hurtbox_component.collision_layer = 4 # Enemies layer
		hurtbox_component.collision_mask = 8  # PlayerAttacks
		hurtbox_component.team_index = 1     # Attackable by player
		var hurt_shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(24.0, 28.0)
		hurt_shape.shape = box
		hurtbox_component.add_child(hurt_shape)
		add_child(hurtbox_component)

	hurtbox_component.health_component = health_component
	hurtbox_component.team_index = 1

	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var body_box := RectangleShape2D.new()
		body_box.size = Vector2(20.0, 20.0)
		collision_shape.shape = body_box
		add_child(collision_shape)

func _get_companion_health(comp: Node) -> HealthComponent:
	if comp == null or not is_instance_valid(comp):
		return null
	var h := comp.get_node_or_null("HealthComponent") as HealthComponent
	if h != null:
		return h
	for child in comp.get_children():
		if child is HealthComponent:
			return child as HealthComponent
	return null

func _trap_target(comp: Node2D) -> void:
	trapped_companion = comp
	global_position = comp.global_position
	comp.set_physics_process(false)
	comp.set("velocity", Vector2.ZERO)

	# Listen to trapped companion death for immediate despawn (T2.EXP.20)
	var comp_health := _get_companion_health(comp)
	if comp_health != null and not comp_health.died.is_connected(_on_companion_died):
		comp_health.died.connect(_on_companion_died)

func _physics_process(delta: float) -> void:
	if is_broken:
		return

	# Boundary check (T2.EXP.20): If trapped companion is dead or deleted, despawn immediately
	if not _is_trapped_companion_alive():
		_despawn_cleanly()
		return

	timer -= delta
	queue_redraw()

	if timer <= 0.0:
		_execute_lethal_tomb()

func _is_trapped_companion_alive() -> bool:
	if trapped_companion == null or not is_instance_valid(trapped_companion):
		return false
	var comp_health := _get_companion_health(trapped_companion)
	if comp_health != null:
		return comp_health.is_alive()
	return not trapped_companion.get("is_dying")

func _on_took_damage(data: DamageData) -> void:
	current_health = health_component.current_health
	queue_redraw()

func _on_tomb_broken() -> void:
	if is_broken:
		return
	is_broken = true
	current_health = 0.0

	# Free companion
	if trapped_companion != null and is_instance_valid(trapped_companion):
		trapped_companion.set_physics_process(true)
		var comp_health := _get_companion_health(trapped_companion)
		if comp_health != null and comp_health.died.is_connected(_on_companion_died):
			comp_health.died.disconnect(_on_companion_died)
		companion_rescued.emit(trapped_companion)

	# Record silent telemetry rescue (M5 integration)
	var tree := get_tree() if is_inside_tree() else Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var eb = tree.root.get_node_or_null("EventBus")
		if eb != null:
			if eb.has_method("emit_companion_rescued"):
				eb.emit_companion_rescued(trapped_companion)
			elif eb.has_signal("companion_rescued"):
				eb.companion_rescued.emit(trapped_companion)
		var tracker = tree.root.get_node_or_null("SilentAgencyTracker")
		if tracker != null and tracker.has_method("record_rescue"):
			tracker.call("record_rescue")

	tomb_destroyed.emit()
	_despawn_cleanly()

func _execute_lethal_tomb() -> void:
	if is_broken:
		return
	is_broken = true

	if trapped_companion != null and is_instance_valid(trapped_companion):
		var comp_health := trapped_companion.get_node_or_null("HealthComponent") as HealthComponent
		if comp_health != null and comp_health.is_alive():
			var lethal_dmg := DamageData.new(9999.0, DamageData.DamageType.ICE, 0.0, Vector2.ZERO, self)
			comp_health.take_damage(lethal_dmg)
		companion_executed.emit(trapped_companion)

	_despawn_cleanly()

func _on_companion_died() -> void:
	# Trapped Ally Death Immediately Despawns Frost Tomb Node (T2.EXP.20)
	_despawn_cleanly()

func _despawn_cleanly() -> void:
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if hurtbox_component != null:
		hurtbox_component.set_deferred("monitoring", false)
		hurtbox_component.set_deferred("monitorable", false)
	queue_free()

func _draw() -> void:
	# Semi-transparent glacial ice block with cracks
	var width := 22.0
	var height := 26.0
	var rect := Rect2(-width * 0.5, -height * 0.5, width, height)
	var pulse := sin(timer * 4.0) * 0.1
	var ice_color := Color(0.4, 0.85, 1.0, 0.65 + pulse)
	var border_color := Color(0.8, 0.95, 1.0, 0.9)

	draw_rect(rect, ice_color)
	draw_rect(rect, border_color, false, 2.0)

	# Draw countdown timer indicator on top
	var timer_pct := clampf(timer / maxf(trap_timeout, 0.001), 0.0, 1.0)
	var bar_width := width * timer_pct
	var bar_rect := Rect2(-width * 0.5, (-height * 0.5) - 6.0, bar_width, 3.0)
	draw_rect(bar_rect, Color(1.0, 0.2, 0.2, 0.85))
