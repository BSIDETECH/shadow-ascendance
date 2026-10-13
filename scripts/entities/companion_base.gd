class_name CompanionBase
extends CharacterBody2D

## Base class for modular companions in "Shadow Cheat: Solo Guild Ascendance".
## Encapsulates HealthComponent, HurtboxComponent, Enneagram psychological evaluation,
## leadership order FSM (Attack, Retreat, Help), and leashing movement physics.

signal ally_damaged(amount: float)
signal ally_died(ally_node: Node)

enum TacticalOrderState {
	IDLE_FOLLOW,    # Autonomous roaming, standard follow_distance
	ORDER_ATTACK,   # Key 1: Move towards focus point, aggressive posture
	ORDER_RETREAT,  # Key 2: Sprint back to player, defensive posture
	ORDER_HELP      # Key 3: Protect player, target threats surrounding player
}

@export_group("Base Stats")
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var armor_reduction: float = 0.0
@export var move_speed: float = 135.0
@export var sprint_speed: float = 190.0
@export var follow_distance: float = 48.0
@export var companion_name: String = "Companion"

@export_group("Leadership & Leashing")
@export var max_leash_distance: float = 280.0
@export var sprint_leash_trigger: float = 180.0
@export var attack_order_duration: float = 4.0
@export var retreat_order_duration: float = 3.5
@export var help_order_duration: float = 5.0

@export_group("Personality & Mental State")
@export var enneagram_profile: EnneagramData = null
@export var stress_level: float = 0.0
@export var current_mental_state: int = 0 # EnneagramEvaluator.MentalState.HEALTHY = 0

var current_tactical_state: TacticalOrderState = TacticalOrderState.IDLE_FOLLOW
var order_timer: float = 0.0
var order_target_position: Vector2 = Vector2.ZERO
var hesitation_timer: float = 0.0
var _pending_order: int = 0
var pending_order_after_hesitation: int = -1
var _pending_target: Vector2 = Vector2.ZERO
var is_dying: bool = false
var downed_timer: float = 0.0
var rescue_timer: float = 0.0
var rescuing_target: Node2D = null

var _player: Node2D = null
var _event_bus: Node = null

var sprite: Sprite2D = null
var health_component: HealthComponent = null
var hurtbox_component: HurtboxComponent = null
var collision_shape: CollisionShape2D = null

func _get_event_bus() -> Node:
	if _event_bus != null and is_instance_valid(_event_bus):
		return _event_bus
	var tree := get_tree()
	if tree != null:
		var root := tree.root
		if root != null:
			_event_bus = root.get_node_or_null("EventBus")
	return _event_bus

func _init() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_setup_components()

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 64 # Layer 7: Companion
	collision_mask = 1   # Layer 1: World walls

	add_to_group("allies")
	add_to_group("companions")

	_setup_components()
	_find_player()

	if enneagram_profile == null:
		enneagram_profile = EnneagramData.create_preset(EnneagramData.Type.REFORMER)

	var eb := _get_event_bus()
	if eb != null and not eb.leadership_order_issued.is_connected(_on_leadership_order_issued):
		eb.leadership_order_issued.connect(_on_leadership_order_issued)

func _exit_tree() -> void:
	var eb := _get_event_bus()
	if eb != null and eb.leadership_order_issued.is_connected(_on_leadership_order_issued):
		eb.leadership_order_issued.disconnect(_on_leadership_order_issued)

func _setup_components() -> void:
	# Discover or instantiate child components for headless/runtime resilience
	sprite = get_node_or_null("Sprite2D") as Sprite2D

	health_component = get_node_or_null("HealthComponent") as HealthComponent
	if health_component == null:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		add_child(health_component)

	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.armor_reduction = armor_reduction
	health_component.can_be_downed = true
	if not health_component.took_damage.is_connected(_on_health_took_damage):
		health_component.took_damage.connect(_on_health_took_damage)
	if not health_component.died.is_connected(_on_health_died):
		health_component.died.connect(_on_health_died)
	if health_component.has_signal("downed") and not health_component.downed.is_connected(_on_downed):
		health_component.downed.connect(_on_downed)

	hurtbox_component = get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox_component == null:
		hurtbox_component = HurtboxComponent.new()
		hurtbox_component.name = "HurtboxComponent"
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		shape.shape = circle
		hurtbox_component.add_child(shape)
		add_child(hurtbox_component)

	hurtbox_component.collision_layer = 64 # Companion layer
	hurtbox_component.collision_mask = 16  # EnemyAttacks mask
	hurtbox_component.team_index = 0       # Ally team
	hurtbox_component.health_component = health_component

	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = 7.0
		collision_shape.shape = circle
		add_child(collision_shape)

func _find_player() -> void:
	var tree := get_tree()
	if tree != null:
		var players := tree.get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Node2D:
			_player = players[0] as Node2D

func _physics_process(delta: float) -> void:
	if is_dying:
		velocity = Vector2.ZERO
		return

	if health_component != null and health_component.get("is_downed"):
		velocity = Vector2.ZERO
		downed_timer -= delta
		if downed_timer <= 0.0:
			health_component.force_kill()
		move_and_slide()
		return
	elif sprite != null and sprite.rotation != 0.0:
		sprite.rotation = 0.0
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Rescue logic
	var is_rescuing = false
	if velocity.length() < 10.0:
		var allies = get_tree().get_nodes_in_group("allies")
		var players = get_tree().get_nodes_in_group("player")
		var all_friendlies = allies + players
		var closest_downed: Node2D = null
		var min_dist = 40.0
		for ally in all_friendlies:
			if ally != self and ally.has_node("HealthComponent"):
				var hc = ally.get_node("HealthComponent")
				if hc.get("is_downed"):
					var d = global_position.distance_to(ally.global_position)
					if d < min_dist:
						min_dist = d
						closest_downed = ally
		if closest_downed != null:
			if rescuing_target != closest_downed:
				rescuing_target = closest_downed
				rescue_timer = 0.0
			is_rescuing = true
			rescue_timer += delta
			if rescue_timer >= 3.0:
				rescuing_target.get_node("HealthComponent").heal(rescuing_target.get_node("HealthComponent").max_health * 0.5)
				rescuing_target = null
				rescue_timer = 0.0

	if not is_rescuing:
		rescue_timer = 0.0
		rescuing_target = null

	_update_psychology(delta)
	_handle_order_timers(delta)
	_handle_movement(delta)
	_handle_combat(delta)

func _update_psychology(delta: float) -> void:
	if enneagram_profile != null:
		var ctx := TacticalContext.create_from_nodes(self, _player, order_target_position)
		stress_level = EnneagramEvaluator.update_stress(delta, stress_level, ctx, enneagram_profile)
		current_mental_state = int(EnneagramEvaluator.get_mental_state(stress_level))

func _handle_order_timers(delta: float) -> void:
	if hesitation_timer > 0.0:
		hesitation_timer -= delta
		if hesitation_timer <= 0.0:
			if _pending_order > 0:
				_apply_order(_pending_order, _pending_target)
			pending_order_after_hesitation = -1
			_pending_order = 0

	if current_tactical_state != TacticalOrderState.IDLE_FOLLOW:
		order_timer -= delta
		if order_timer <= 0.0:
			current_tactical_state = TacticalOrderState.IDLE_FOLLOW

func _handle_movement(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		move_and_slide()
		return

	var dist_to_player := global_position.distance_to(_player.global_position)

	# Hard Leash Override: sprint to player if beyond max leash distance
	if dist_to_player > max_leash_distance:
		current_tactical_state = TacticalOrderState.IDLE_FOLLOW
		var dir := (_player.global_position - global_position).normalized() if dist_to_player > 0.001 else Vector2.RIGHT
		velocity = velocity.move_toward(dir * sprint_speed, 1000.0 * delta)
		move_and_slide()
		_update_sprite_facing()
		return

	var effective_speed := move_speed
	if dist_to_player > sprint_leash_trigger or current_tactical_state == TacticalOrderState.ORDER_RETREAT:
		effective_speed = sprint_speed

	match current_tactical_state:
		TacticalOrderState.IDLE_FOLLOW:
			if dist_to_player > follow_distance:
				var dir := (_player.global_position - global_position).normalized() if dist_to_player > 0.001 else Vector2.RIGHT
				velocity = velocity.move_toward(dir * effective_speed, 800.0 * delta)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)

		TacticalOrderState.ORDER_ATTACK:
			var dist_to_order := global_position.distance_to(order_target_position)
			if dist_to_order > 50.0 and dist_to_player < max_leash_distance * 0.85:
				var dir := (order_target_position - global_position).normalized() if dist_to_order > 0.001 else Vector2.RIGHT
				velocity = velocity.move_toward(dir * move_speed, 800.0 * delta)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)

		TacticalOrderState.ORDER_RETREAT:
			if dist_to_player > follow_distance * 0.6:
				var dir := (_player.global_position - global_position).normalized() if dist_to_player > 0.001 else Vector2.RIGHT
				velocity = velocity.move_toward(dir * sprint_speed, 1000.0 * delta)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
				current_tactical_state = TacticalOrderState.IDLE_FOLLOW

		TacticalOrderState.ORDER_HELP:
			var allies = get_tree().get_nodes_in_group("allies")
			var players = get_tree().get_nodes_in_group("player")
			var all_friendlies = allies + players
			var closest_downed: Node2D = null
			var min_d = 9999.0
			for ally in all_friendlies:
				if ally != self and ally.has_node("HealthComponent") and ally.get_node("HealthComponent").get("is_downed"):
					var d = global_position.distance_to(ally.global_position)
					if d < min_d:
						min_d = d
						closest_downed = ally

			if closest_downed != null:
				if min_d > 28.0:
					var dir := (closest_downed.global_position - global_position).normalized() if min_d > 0.001 else Vector2.RIGHT
					velocity = velocity.move_toward(dir * sprint_speed, 900.0 * delta)
				else:
					velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)
			else:
				if dist_to_player > 28.0:
					var dir := (_player.global_position - global_position).normalized() if dist_to_player > 0.001 else Vector2.RIGHT
					velocity = velocity.move_toward(dir * sprint_speed, 900.0 * delta)
				else:
					velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)

	move_and_slide()
	_update_sprite_facing()

func _update_sprite_facing() -> void:
	if velocity.x != 0.0 and sprite != null:
		sprite.flip_h = velocity.x < 0.0

func _handle_combat(_delta: float) -> void:
	# Virtual hook for subclasses to implement specific attacks
	var p = get_tree().get_first_node_in_group("player")
	if p != null and p.has_meta("solar_flare_unlocked") and p.get_meta("solar_flare_unlocked"):
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e is Node2D and global_position.distance_to(e.global_position) <= 60.0:
				e.set_meta("marked_by_solar", true)

func _on_leadership_order_issued(order_type: int, target_pos: Vector2) -> void:
	if is_dying:
		return

	# Reset hesitation timer and pending order when a new order arrives to prevent stale timer race conditions
	hesitation_timer = 0.0
	pending_order_after_hesitation = -1
	_pending_order = -1

	var evaluation: OrderResult = _evaluate_order(order_type, target_pos)

	if evaluation.voice_line != "":
		var eb := _get_event_bus()
		if eb != null:
			eb.emit_companion_dialogue(companion_name, evaluation.voice_line, evaluation.bbcode_color)

	match evaluation.status:
		2: # REFUSE
			_flash_tint(Color(1.8, 0.4, 0.4))
			return
		1: # HESITATE
			_flash_tint(Color(1.8, 1.8, 0.4))
			hesitation_timer = evaluation.delay_sec
			_pending_order = order_type
			pending_order_after_hesitation = order_type
			_pending_target = target_pos
		0: # OBEY
			if evaluation.delay_sec > 0.0:
				hesitation_timer = evaluation.delay_sec
				_pending_order = order_type
				pending_order_after_hesitation = order_type
				_pending_target = target_pos
			else:
				_apply_order(order_type, target_pos)

func _evaluate_order(order_type: int, target_pos: Vector2) -> OrderResult:
	var ctx := TacticalContext.create_from_nodes(self, _player, target_pos)
	var mental_state := EnneagramEvaluator.get_mental_state(stress_level)
	return EnneagramEvaluator.evaluate_order(order_type, enneagram_profile, mental_state, ctx, stress_level, companion_name)

func evaluate_order(order_type: int, target_pos: Vector2) -> OrderResult:
	return _evaluate_order(order_type, target_pos)

func _apply_order(order_type: int, target_pos: Vector2) -> void:
	order_target_position = target_pos
	match order_type:
		1: # ATTACK
			current_tactical_state = TacticalOrderState.ORDER_ATTACK
			order_timer = attack_order_duration
			_flash_tint(Color(1.6, 0.6, 0.4))
		2: # RETREAT
			current_tactical_state = TacticalOrderState.ORDER_RETREAT
			order_timer = retreat_order_duration
			_flash_tint(Color(0.4, 0.8, 1.8))
		3: # HELP
			current_tactical_state = TacticalOrderState.ORDER_HELP
			order_timer = help_order_duration
			_flash_tint(Color(0.6, 1.8, 0.6))

func _flash_tint(tint: Color) -> void:
	if sprite == null:
		return
	var orig_color := sprite.modulate
	var tween := create_tween()
	if tween != null:
		tween.tween_property(sprite, "modulate", tint, 0.08)
		tween.tween_property(sprite, "modulate", orig_color, 0.16)

func _on_downed() -> void:
	if is_dying: return
	downed_timer = 15.0
	if sprite != null:
		sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)
		sprite.rotation = PI / 2.0

func _on_health_took_damage(data: DamageData) -> void:
	var amt: float = data.amount if data != null else 0.0
	current_health = health_component.current_health
	ally_damaged.emit(amt)

func _on_health_died() -> void:
	if is_dying:
		return
	is_dying = true
	current_health = 0.0
	ally_died.emit(self)
	var eb := _get_event_bus()
	if eb != null:
		eb.emit_entity_died(self, global_position)
		if eb.has_method("emit_ally_died"):
			eb.emit_ally_died(self)
		elif eb.has_signal("ally_died"):
			eb.ally_died.emit(self)
	set_physics_process(false)
	if hurtbox_component != null:
		hurtbox_component.set_deferred("monitorable", false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	var death_tween := create_tween()
	if death_tween != null:
		death_tween.tween_property(self, "modulate:a", 0.0, 0.25)
		death_tween.tween_callback(queue_free)

func _select_combat_target(search_radius: float = 260.0) -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var enemies := tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null

	var best_target: Node2D = null
	var min_score: float = 999999.0

	match current_tactical_state:
		TacticalOrderState.ORDER_HELP:
			var ref_pos := _player.global_position if (_player != null and is_instance_valid(_player)) else global_position
			for e in enemies:
				if e is Node2D and is_instance_valid(e):
					var d := ref_pos.distance_to((e as Node2D).global_position)
					if d < search_radius * 1.3 and d < min_score:
						min_score = d
						best_target = e as Node2D

		TacticalOrderState.ORDER_ATTACK:
			for e in enemies:
				if e is Node2D and is_instance_valid(e):
					var d := order_target_position.distance_to((e as Node2D).global_position)
					if d < search_radius * 1.4 and d < min_score:
						min_score = d
						best_target = e as Node2D

		_:
			for e in enemies:
				if e is Node2D and is_instance_valid(e):
					var d := global_position.distance_to((e as Node2D).global_position)
					if d < search_radius and d < min_score:
						min_score = d
						best_target = e as Node2D

	return best_target
