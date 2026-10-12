extends Node

## Manages tactical orders (Keys 1: Attack, 2: Retreat, 3: Help),
## the 3-charge pool, recharge from 10 enemy kills, and 0.15s input debounce.

enum LeadershipOrder {
	NONE = 0,
	ATTACK = 1,
	RETREAT = 2,
	HELP = 3
}

const MAX_CHARGES: int = 3
const KILLS_PER_RECHARGE: int = 10
const INPUT_DEBOUNCE_TIME: float = 0.15

var current_charges: int = MAX_CHARGES
var max_charges: int = MAX_CHARGES
var charges: int:
	get: return current_charges
	set(val):
		current_charges = clampi(val, 0, max_charges)
		var eb := _get_event_bus()
		if eb != null:
			eb.emit_leadership_charges_changed(current_charges, max_charges)
var kills_towards_recharge: int = 0
var total_orders_issued: int = 0

var _debounce_timer: float = 0.0
var is_enabled: bool = true

var _event_bus: Node = null

func _get_event_bus() -> Node:
	if _event_bus != null and is_instance_valid(_event_bus):
		return _event_bus
	if not is_inside_tree():
		var loop := Engine.get_main_loop()
		if loop is SceneTree and (loop as SceneTree).root != null:
			_event_bus = (loop as SceneTree).root.get_node_or_null("EventBus")
		return _event_bus
	var tree := get_tree()
	if tree != null:
		_event_bus = tree.root.get_node_or_null("EventBus")
	return _event_bus

func _ready() -> void:
	_ensure_input_mappings()
	var eb := _get_event_bus()
	if eb != null and not eb.enemy_died.is_connected(_on_enemy_died):
		eb.enemy_died.connect(_on_enemy_died)
	call_deferred("_broadcast_initial_state")

func _broadcast_initial_state() -> void:
	var eb := _get_event_bus()
	if eb != null:
		eb.emit_leadership_charges_changed(current_charges, max_charges)

func _process(delta: float) -> void:
	if _debounce_timer > 0.0:
		_debounce_timer = maxf(0.0, _debounce_timer - delta)

func _unhandled_input(event: InputEvent) -> void:
	if not is_enabled:
		return

	if event.is_action_pressed("command_attack"):
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		issue_order(int(LeadershipOrder.ATTACK))
	elif event.is_action_pressed("command_retreat"):
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		issue_order(int(LeadershipOrder.RETREAT))
	elif event.is_action_pressed("command_help"):
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		issue_order(int(LeadershipOrder.HELP))

func issue_order(order_type: int, override_target: Vector2 = Vector2.INF) -> bool:
	if not is_enabled:
		return false

	# 1. Debounce check
	if _debounce_timer > 0.0:
		return false

	var eb := _get_event_bus()

	# 2. Charge check
	if current_charges <= 0:
		_debounce_timer = INPUT_DEBOUNCE_TIME
		if eb != null:
			eb.emit_leadership_order_failed("Sem cargas de liderança disponíveis!")
		return false

	# 3. Deduct charge and set debounce
	current_charges -= 1
	_debounce_timer = INPUT_DEBOUNCE_TIME
	total_orders_issued += 1

	# 4. Determine target position
	var target_pos: Vector2 = override_target
	if target_pos == Vector2.INF:
		target_pos = get_order_target_position(order_type)

	# 5. Emit signals
	if eb != null:
		eb.emit_leadership_charges_changed(current_charges, max_charges)
		eb.emit_leadership_order_issued(order_type, target_pos)

	return true

func get_order_target_position(order_type: int) -> Vector2:
	var player_node: Node2D = get_player_node()
	match order_type:
		1, int(LeadershipOrder.ATTACK):
			if player_node != null and is_instance_valid(player_node):
				return player_node.get_global_mouse_position()
			var vp := get_viewport()
			if vp != null:
				return vp.get_canvas_transform().affine_inverse() * vp.get_mouse_position()
			return Vector2.ZERO
		2, int(LeadershipOrder.RETREAT), 3, int(LeadershipOrder.HELP):
			if player_node != null and is_instance_valid(player_node):
				return player_node.global_position
			return Vector2.ZERO
	return Vector2.ZERO

func get_player_node() -> Node2D:
	if not is_inside_tree():
		var loop := Engine.get_main_loop()
		if loop is SceneTree:
			var players := (loop as SceneTree).get_nodes_in_group("player")
			if players.size() > 0 and players[0] is Node2D:
				return players[0] as Node2D
		return null
	var tree := get_tree()
	if tree != null:
		var players := tree.get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Node2D:
			return players[0] as Node2D
	return null

func _on_enemy_died(_pos: Vector2, _xp: int) -> void:
	kills_towards_recharge += 1
	if kills_towards_recharge >= KILLS_PER_RECHARGE:
		kills_towards_recharge -= KILLS_PER_RECHARGE
		if current_charges < max_charges:
			current_charges += 1
			var eb := _get_event_bus()
			if eb != null:
				eb.emit_leadership_charges_changed(current_charges, max_charges)

func add_charge(amount: int = 1) -> void:
	current_charges = clampi(current_charges + amount, 0, max_charges)
	var eb := _get_event_bus()
	if eb != null:
		eb.emit_leadership_charges_changed(current_charges, max_charges)

func spend_charge(amount: int = 1) -> bool:
	if current_charges < amount:
		return false
	current_charges = clampi(current_charges - amount, 0, max_charges)
	var eb := _get_event_bus()
	if eb != null:
		eb.emit_leadership_charges_changed(current_charges, max_charges)
	return true

func consume_charge(amount: int = 1) -> bool:
	return spend_charge(amount)

func notify_kill() -> void:
	_on_enemy_died(Vector2.ZERO, 0)

func can_issue_order_debounce() -> bool:
	if _debounce_timer > 0.0:
		return false
	_debounce_timer = INPUT_DEBOUNCE_TIME
	return true

func reset_charges() -> void:
	current_charges = max_charges
	kills_towards_recharge = 0
	_debounce_timer = 0.0
	var eb := _get_event_bus()
	if eb != null:
		eb.emit_leadership_charges_changed(current_charges, max_charges)

func can_issue_order() -> bool:
	return is_enabled and current_charges > 0 and _debounce_timer <= 0.0

func _ensure_input_mappings() -> void:
	_register_action_if_missing("command_attack", [KEY_1, KEY_KP_1])
	_register_action_if_missing("command_retreat", [KEY_2, KEY_KP_2])
	_register_action_if_missing("command_help", [KEY_3, KEY_KP_3])

func _register_action_if_missing(action_name: StringName, keys: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		for k in keys:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action_name, ev)
