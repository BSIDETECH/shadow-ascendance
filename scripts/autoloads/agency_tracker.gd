extends Node

## Silent Agency Tracker AutoLoad (M5)
## Adheres strictly to the Principle of Zero Interpretive Aid.
## Tracks organic conduct metrics without visible karma or morality meters,
## evaluating player leadership into Dual Endings (A Aliança dos Vivos vs O Monstro Solitário).

# --- Telemetry Metrics (with sanitization clamping to 0, T2.EXP.26) ---
var allies_deployed: int = 0:
	set(val):
		allies_deployed = maxi(0, val)

var allies_survived: int = 0:
	set(val):
		allies_survived = maxi(0, val)

var allies_fallen: int = 0:
	set(val):
		allies_fallen = maxi(0, val)

var rescues_performed: int = 0:
	set(val):
		rescues_performed = maxi(0, val)

var reckless_orders_issued: int = 0:
	set(val):
		reckless_orders_issued = maxi(0, val)

var abandonment_ticks: int = 0:
	set(val):
		abandonment_ticks = maxi(0, val)

var agency_score: int:
	get:
		return calculate_agency_score()

# Combat distance monitoring configuration (T2.EXP.22)
const COMBAT_ABANDON_DISTANCE: float = 350.0
var abandonment_check_interval: float = 1.0
var _abandonment_timer: float = 0.0

func _ready() -> void:
	call_deferred("_connect_event_bus")

func _connect_event_bus() -> void:
	var eb = _get_event_bus()
	if eb == null:
		return

	if eb.has_signal("companion_rescued") and not eb.companion_rescued.is_connected(_on_companion_rescued):
		eb.companion_rescued.connect(_on_companion_rescued)
	if eb.has_signal("ally_died") and not eb.ally_died.is_connected(_on_ally_died):
		eb.ally_died.connect(_on_ally_died)
	if eb.has_signal("leadership_order_issued") and not eb.leadership_order_issued.is_connected(_on_leadership_order_issued):
		eb.leadership_order_issued.connect(_on_leadership_order_issued)

func _get_event_bus() -> Node:
	var tree := get_tree()
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("EventBus")
	return null

# --- Public Telemetry API ---

func record_order(_order_type: int, is_reckless: bool = false) -> void:
	if is_reckless:
		reckless_orders_issued += 1

func record_rescue() -> void:
	rescues_performed += 1

func record_ally_death(_ally_node: Node = null) -> void:
	allies_fallen += 1

func record_abandonment_tick() -> void:
	abandonment_ticks += 1

func record_ally_deployed(_ally: Dictionary = {}) -> void:
	allies_deployed += 1

func record_ally_survived() -> void:
	allies_survived += 1

## Agency Score formula:
## (survived * 25) + (rescues * 15) - (fallen * 35) - (reckless * 10) - (abandonment * 15)
func calculate_agency_score() -> int:
	return (allies_survived * 25) + (rescues_performed * 15) - (allies_fallen * 35) - (reckless_orders_issued * 10) - (abandonment_ticks * 15)

## Evaluates Ending type based on organic conduct:
## - Solo run (allies_deployed == 0) -> BAD_ENDING (O Monstro Solitário)
## - Score < 0 or fallen >= 3 -> BAD_ENDING (O Monstro Solitário)
## - Score >= 50 and fallen <= 1 -> GOOD_ENDING (A Aliança dos Vivos)
## - Fallback: BAD_ENDING if score < 0 else GOOD_ENDING
func evaluate_ending() -> String:
	if allies_deployed == 0:
		return "BAD_ENDING"
	var score: int = calculate_agency_score()
	if score < 0 or allies_fallen >= 3:
		return "BAD_ENDING"
	if score >= 50 and allies_fallen <= 1:
		return "GOOD_ENDING"
	return "BAD_ENDING"

func get_metrics() -> Dictionary:
	return {
		"allies_deployed": allies_deployed,
		"allies_survived": allies_survived,
		"allies_fallen": allies_fallen,
		"rescues_performed": rescues_performed,
		"reckless_orders_issued": reckless_orders_issued,
		"abandonment_ticks": abandonment_ticks,
		"agency_score": calculate_agency_score(),
		"ending": evaluate_ending()
	}

func reset_metrics() -> void:
	allies_deployed = 0
	allies_survived = 0
	allies_fallen = 0
	rescues_performed = 0
	reckless_orders_issued = 0
	abandonment_ticks = 0
	_abandonment_timer = 0.0

# --- Event Handlers & Signal Listeners ---

func _on_companion_rescued(_companion: Node = null) -> void:
	record_rescue()

func _on_ally_died(_ally_node: Node = null) -> void:
	record_ally_death(_ally_node)

func _get_companion_hp_ratio(comp: Node) -> float:
	if comp == null or not is_instance_valid(comp):
		return 1.0
	if comp.has_method("get_health_ratio"):
		return comp.call("get_health_ratio")
	var hc: Node = null
	if comp.get("health_component") != null:
		hc = comp.get("health_component")
	elif comp.has_node("HealthComponent"):
		hc = comp.get_node("HealthComponent")
	else:
		for child in comp.get_children():
			if child is HealthComponent or child.get_class() == "HealthComponent":
				hc = child
				break
	if hc != null:
		var max_h: float = hc.get("max_health") if hc.get("max_health") != null else 100.0
		var cur_h: float = hc.get("current_health") if hc.get("current_health") != null else max_h
		if max_h > 0.0:
			return cur_h / max_h
	if comp.get("max_health") != null and comp.get("current_health") != null:
		var max_h: float = comp.get("max_health")
		var cur_h: float = comp.get("current_health")
		if max_h > 0.0:
			return cur_h / max_h
	return 1.0

func _on_leadership_order_issued(order_type: int, _target_pos: Vector2) -> void:
	var is_reckless := false
	# If ally HP < 20% and order == ATTACK, flag reckless order (T2.EXP.23)
	if order_type == 1:
		var tree := get_tree()
		if tree != null:
			var companions: Array = tree.get_nodes_in_group("companions")
			if companions.is_empty():
				companions = tree.get_nodes_in_group("allies")
			for comp in companions:
				if is_instance_valid(comp) and not comp.get("is_dying"):
					var hp_ratio := _get_companion_hp_ratio(comp)
					if hp_ratio < 0.20:
						is_reckless = true
						break
	record_order(order_type, is_reckless)

# --- Combat Distance & Abandonment Monitoring (T2.EXP.22) ---

func check_abandonment_condition(player_dist: float, ally_engaged: bool) -> bool:
	if player_dist > COMBAT_ABANDON_DISTANCE and ally_engaged:
		record_abandonment_tick()
		return true
	return false

func _physics_process(delta: float) -> void:
	_abandonment_timer += delta
	if _abandonment_timer >= abandonment_check_interval:
		_abandonment_timer = 0.0
		_check_combat_abandonment()

func _check_combat_abandonment() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var enemies: Array = tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var players: Array = tree.get_nodes_in_group("player")
	if players.is_empty() or not (players[0] is Node2D):
		return
	var player_pos: Vector2 = (players[0] as Node2D).global_position

	var companions: Array = tree.get_nodes_in_group("companions")
	if companions.is_empty():
		companions = tree.get_nodes_in_group("allies")

	for comp in companions:
		if is_instance_valid(comp) and comp is Node2D and not comp.get("is_dying"):
			var comp_pos: Vector2 = (comp as Node2D).global_position
			var dist := player_pos.distance_to(comp_pos)
			if dist > COMBAT_ABANDON_DISTANCE:
				var engaged := false
				for e in enemies:
					if is_instance_valid(e) and e is Node2D:
						if comp_pos.distance_to((e as Node2D).global_position) <= 280.0:
							engaged = true
							break
				if engaged:
					record_abandonment_tick()
