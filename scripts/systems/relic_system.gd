extends Node

var active_relics: Array[RelicData] = []

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_killed)

func add_relic(relic: RelicData) -> void:
	active_relics.append(relic)

	if relic.target == "player" or relic.target == "all":
		var players := get_tree().get_nodes_in_group("player")
		for p in players:
			apply_relic_to_player(p, relic)

	if relic.target == "companion" or relic.target == "all":
		var companions := get_tree().get_nodes_in_group("companions")
		for c in companions:
			apply_relic_to_companion(c, relic)

func apply_all_relics(entity: Node, target_type: String) -> void:
	for relic in active_relics:
		if relic.target == target_type or relic.target == "all":
			if target_type == "player":
				apply_relic_to_player(entity, relic)
			elif target_type == "companion":
				apply_relic_to_companion(entity, relic)

func apply_relic_to_player(player: Node, relic: RelicData) -> void:
	if not player.get(relic.property_name) == null:
		var current_val = player.get(relic.property_name)

		if relic.relic_type == RelicData.RelicType.STAT_MODIFIER:
			if relic.property_name.ends_with("_mult"):
				player.set(relic.property_name, current_val + relic.value)
			else:
				# Other simple float modifiers
				player.set(relic.property_name, current_val + relic.value)
		elif relic.relic_type == RelicData.RelicType.ON_KILL_HEAL:
			player.set(relic.property_name, current_val + relic.value)
		elif relic.relic_type == RelicData.RelicType.COOLDOWN_REDUCTION:
			# Cooldown reduction (e.g. -10%) is additive in terms of multipliers or a multiplicative effect?
			# Based on earlier assumptions, `current_val * (1.0 + relic.value)` works perfectly
			# as current_val is 1.0 and relic.value is -0.10, making it 0.9.
			# Wait, the user specifically noted dash_cooldown_mult *= 0.90
			# But if we just do: player.set(relic.property_name, current_val + relic.value) for -0.10, it goes to 0.9 as well.
			# We'll use multiplier.
			player.set(relic.property_name, current_val * (1.0 + relic.value))

func apply_relic_to_companion(companion: Node, relic: RelicData) -> void:
	if not companion.get(relic.property_name) == null:
		var current_val = companion.get(relic.property_name)

		if relic.property_name == "max_health":
			companion.set("max_health", current_val * (1.0 + relic.value))
			if companion.has_node("HealthComponent"):
				var hc = companion.get_node("HealthComponent")
				hc.max_health = hc.max_health * (1.0 + relic.value)
				hc.current_health = hc.current_health * (1.0 + relic.value)
		else:
			if relic.property_name.ends_with("_mult"):
				companion.set(relic.property_name, current_val + relic.value)
			else:
				companion.set(relic.property_name, current_val + relic.value)


func get_starter_relics() -> Array[RelicData]:
	return [
		RelicData.new(
			"boots_of_wind",
			"Botas de Vento",
			"+15% vel",
			RelicData.RelicType.STAT_MODIFIER,
			"player",
			"move_speed_mult",
			0.15
		),
		RelicData.new(
			"guardian_crest",
			"Brasão do Guardião",
			"+20% vida para companions",
			RelicData.RelicType.STAT_MODIFIER,
			"companion",
			"max_health",
			0.20
		),
		RelicData.new(
			"vampiric_necklace",
			"Colar Vampírico",
			"cura 2 HP por morte",
			RelicData.RelicType.ON_KILL_HEAL,
			"player",
			"lifesteal_on_kill",
			2.0
		),
		RelicData.new(
			"arcane_hourglass",
			"Ampulheta Arcana",
			"-10% cooldowns",
			RelicData.RelicType.COOLDOWN_REDUCTION,
			"player",
			"dash_cooldown_mult",
			-0.10
		)
	]

func _on_enemy_killed(_pos: Vector2, _xp: int) -> void:
	pass
