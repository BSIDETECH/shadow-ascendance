class_name TacticalContext
extends RefCounted

## Snapshot of battlefield and companion metrics for Enneagram decision making.

var companion_hp_ratio: float = 1.0       # Current HP / Max HP [0.0..1.0]
var player_hp_ratio: float = 1.0          # Player HP / Max HP [0.0..1.0]
var nearby_enemies_count: int = 0         # Enemies within perception radius (~140px)
var closest_enemy_distance: float = 999.0 # Distance to nearest foe
var distance_to_player: float = 0.0       # Distance to protagonist
var distance_to_target: float = 0.0       # Distance to order coordinate/enemy
var allies_fallen_count: int = 0          # Fallen allies in this expedition
var order_frequency: float = 0.0          # Orders received in past 3.0s (spam metric)
var target_is_boss: bool = false          # Whether combat target is a Guardian Boss
var is_under_hazard: bool = false         # Standing in telegraphed hazard zone

static func create_from_nodes(
	companion: CharacterBody2D,
	player: Node2D,
	order_target: Vector2 = Vector2.ZERO
) -> TacticalContext:
	var ctx := TacticalContext.new()
	if companion == null or not is_instance_valid(companion):
		return ctx

	var health_comp: HealthComponent = companion.get_node_or_null("HealthComponent") as HealthComponent
	if health_comp != null and health_comp.max_health > 0.0:
		ctx.companion_hp_ratio = clampf(health_comp.current_health / health_comp.max_health, 0.0, 1.0)
	elif companion.get("current_health") != null and companion.get("max_health") != null:
		var max_h := float(companion.get("max_health"))
		if max_h > 0.0:
			ctx.companion_hp_ratio = clampf(float(companion.get("current_health")) / max_h, 0.0, 1.0)

	if player != null and is_instance_valid(player):
		ctx.distance_to_player = companion.global_position.distance_to(player.global_position)
		var p_health: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
		if p_health != null and p_health.max_health > 0.0:
			ctx.player_hp_ratio = clampf(p_health.current_health / p_health.max_health, 0.0, 1.0)
		elif player.get("current_health") != null and player.get("max_health") != null:
			var p_max := float(player.get("max_health"))
			if p_max > 0.0:
				ctx.player_hp_ratio = clampf(float(player.get("current_health")) / p_max, 0.0, 1.0)

	if order_target != Vector2.ZERO:
		ctx.distance_to_target = companion.global_position.distance_to(order_target)

	var tree := companion.get_tree()
	if tree != null:
		var enemies := tree.get_nodes_in_group("enemies")
		var nearby: int = 0
		var min_d: float = 9999.0
		for e in enemies:
			if e is Node2D and is_instance_valid(e):
				var d := companion.global_position.distance_to((e as Node2D).global_position)
				if d < 140.0:
					nearby += 1
				if d < min_d:
					min_d = d
		ctx.nearby_enemies_count = nearby
		ctx.closest_enemy_distance = min_d

	return ctx
