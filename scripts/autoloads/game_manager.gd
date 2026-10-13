class_name GameManagerClass
extends Node

## Centralized Game Manager AutoLoad.
## Manages scene transitions (Hub <-> Dungeon), active party roster persistence,
## quest selection state, and smooth 0.35s fade transitions.

signal scene_transition_started(target_scene: String)
signal scene_transition_finished(target_scene: String)
signal party_roster_changed(new_roster: Array[Dictionary])
signal quest_selected(rank: String)
signal potions_changed(health_count: int, shield_count: int)

const FADE_DURATION: float = 0.35
const MAX_PARTY_SIZE: int = 3
const SCENE_HUB: String = "res://scenes/hub/greyrock_village.tscn"
const SCENE_ARENA: String = "res://scenes/arena/arena.tscn"
const SCENE_FORTRESS: String = "res://scenes/dungeon/ruined_fortress.tscn"

var active_party_roster: Array[Dictionary] = []
var selected_quest_rank: String = "F"
var total_completed_runs: int = 0
var is_transitioning: bool = false
var player_gold: int = 0
var health_potions: int = 0
var shield_potions: int = 0

# Difficulty Balancing
var enemy_health_mult: float = 1.40
var enemy_damage_mult: float = 1.30
var enemy_speed_mult: float = 1.15
var boss_health_mult: float = 1.40
var boss_damage_mult: float = 1.30

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null

func _ready() -> void:
	_ensure_input_mappings()
	_setup_fade_overlay()

func _ensure_input_mappings() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_E
		InputMap.action_add_event("interact", ev)

func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "TransitionFadeLayer"
	_fade_layer.layer = 120 # Above all HUDs and modals
	
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_fade_layer.add_child(_fade_rect)
	add_child(_fade_layer)

## Transition from Hub to Dungeon Expedition
func transition_to_dungeon(quest_rank: String, party: Array[Dictionary] = []) -> void:
	selected_quest_rank = quest_rank
	quest_selected.emit(quest_rank)
	
	if party.size() > 0:
		set_active_party_roster(party)
	
	var target_scene := SCENE_ARENA
	if (quest_rank == "E" or quest_rank == "D") and ResourceLoader.exists(SCENE_FORTRESS):
		target_scene = SCENE_FORTRESS
	
	change_scene_with_fade(target_scene)

## Transition back from Dungeon to Village Hub
func transition_to_hub() -> void:
	change_scene_with_fade(SCENE_HUB)

## Smooth fade transition between scenes
func change_scene_with_fade(target_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	scene_transition_started.emit(target_path)

	var tree := get_tree()
	if tree == null:
		is_transitioning = false
		scene_transition_finished.emit(target_path)
		return

	if _fade_rect != null:
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		var tween_out := create_tween()
		if tween_out != null:
			tween_out.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
			await tween_out.finished
		else:
			_fade_rect.color.a = 1.0

	var err := tree.change_scene_to_file(target_path)
	if err != OK and target_path != SCENE_ARENA:
		# Fallback to Arena if target scene is pending future milestone
		tree.change_scene_to_file(SCENE_ARENA)

	await tree.process_frame

	if _fade_rect != null:
		var tween_in := create_tween()
		if tween_in != null:
			tween_in.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
			await tween_in.finished
		else:
			_fade_rect.color.a = 0.0
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	is_transitioning = false
	scene_transition_finished.emit(target_path)

# --- Party Roster Management ---

func get_active_party_roster() -> Array[Dictionary]:
	return active_party_roster

func set_active_party_roster(roster: Array[Dictionary]) -> void:
	active_party_roster.clear()
	for member in roster:
		if active_party_roster.size() < MAX_PARTY_SIZE:
			active_party_roster.append(member.duplicate(true))
	party_roster_changed.emit(active_party_roster)

func add_to_party_roster(merc: Dictionary) -> bool:
	var merc_id: String = merc.get("id", "")
	if merc_id == "":
		return false

	# Rejeita duplicatas
	if has_mercenary(merc_id):
		return false

	# Respeita limite máximo
	if active_party_roster.size() >= MAX_PARTY_SIZE:
		return false

	active_party_roster.append(merc.duplicate(true))
	party_roster_changed.emit(active_party_roster)
	return true

func remove_from_party_roster(merc_id: String) -> bool:
	for i in range(active_party_roster.size()):
		if active_party_roster[i].get("id", "") == merc_id:
			active_party_roster.remove_at(i)
			party_roster_changed.emit(active_party_roster)
			return true
	return false

func has_mercenary(merc_id: String) -> bool:
	for m in active_party_roster:
		if m.get("id", "") == merc_id:
			return true
	return false

func clear_party_roster() -> void:
	active_party_roster.clear()
	party_roster_changed.emit(active_party_roster)

# --- Quest Rank State ---

func get_selected_quest_rank() -> String:
	return selected_quest_rank

func set_selected_quest_rank(rank: String) -> void:
	selected_quest_rank = rank
	quest_selected.emit(rank)

var last_ending_type: String = ""
var last_ending_metrics: Dictionary = {}

func get_last_ending_type() -> String:
	return last_ending_type

func get_last_ending_metrics() -> Dictionary:
	return last_ending_metrics

# --- Ending Trigger Helper (M5 compatibility) ---

func trigger_ending(ending_type: String = "", metrics: Dictionary = {}) -> void:
	total_completed_runs += 1
	var tree := get_tree()
	var tracker: Node = null
	if tree != null and tree.root != null:
		tracker = tree.root.get_node_or_null("SilentAgencyTracker")

	if tracker != null:
		if ending_type == "" and tracker.has_method("evaluate_ending"):
			ending_type = tracker.call("evaluate_ending")
		if metrics.is_empty() and tracker.has_method("get_metrics"):
			metrics = tracker.call("get_metrics")

	if ending_type == "":
		ending_type = "BAD_ENDING"

	last_ending_type = ending_type
	last_ending_metrics = metrics

	var ending_scene_path := "res://scenes/ui/ending_screen/ending_screen.tscn"
	if ResourceLoader.exists(ending_scene_path):
		change_scene_with_fade(ending_scene_path)

# --- Economy System ---

func add_gold(amount: int) -> void:
	player_gold += amount
	if EventBus.has_signal("gold_changed"):
		EventBus.gold_changed.emit(player_gold)

func spend_gold(amount: int) -> bool:
	if player_gold >= amount:
		player_gold -= amount
		if EventBus.has_signal("gold_changed"):
			EventBus.gold_changed.emit(player_gold)
		return true
	return false

func get_gold() -> int:
	return player_gold

# --- Potion System ---
func add_health_potion() -> void:
	health_potions += 1
	potions_changed.emit(health_potions, shield_potions)

func add_shield_potion() -> void:
	shield_potions += 1
	potions_changed.emit(health_potions, shield_potions)

func consume_health_potion() -> bool:
	if health_potions > 0:
		health_potions -= 1
		potions_changed.emit(health_potions, shield_potions)
		return true
	return false

func consume_shield_potion() -> bool:
	if shield_potions > 0:
		shield_potions -= 1
		potions_changed.emit(health_potions, shield_potions)
		return true
	return false


# Gacha Card Persistance
var permanent_gacha_cards: Array[Dictionary] = []
var pending_gacha_cards: Array[Dictionary] = []

func add_pending_gacha_card(card: Dictionary) -> void:
	pending_gacha_cards.append(card)

func commit_gacha_cards() -> void:
	permanent_gacha_cards.append_array(pending_gacha_cards)
	pending_gacha_cards.clear()

func clear_gacha_cards() -> void:
	permanent_gacha_cards.clear()
	pending_gacha_cards.clear()

func apply_gacha_card(card: Dictionary, player: Node, hud: Node, tree: SceneTree, gacha_screen: Node = null) -> void:
	if player == null or not is_instance_valid(player):
		return

	if not player.weapon_unlocked:
		player.unlock_weapon()

	var buff_companion = func(prop_name: String, multiplier: float = 1.0, add_value: float = 0.0):
		var targets: Array = []
		var group_allies := tree.get_nodes_in_group("companions")
		for ally in group_allies:
			if ally != null and is_instance_valid(ally) and not targets.has(ally):
				targets.append(ally)
		for target in targets:
			if is_instance_valid(target) and prop_name in target:
				if multiplier != 1.0:
					target.set(prop_name, target.get(prop_name) * multiplier)
				if add_value != 0.0:
					target.set(prop_name, target.get(prop_name) + add_value)

	var id: String = card.get("id", "")
	match id:
		# Cartas R
		"dmg_up":
			player.damage_mult += 0.25
		"spd_up":
			player.move_speed_mult += 0.20
		"mag_up":
			player.pickup_radius *= 1.6
			player._update_magnet_radius()
		"hp_up":
			player.health_component.max_health += 30.0
			player.health_component.current_health += 30.0
			if hud != null and hud.has_method("update_health"):
				hud.update_health(player.health_component.current_health, player.health_component.max_health)
		# Cartas SR
		"mage_multi":
			buff_companion.call("projectiles_per_cast", 1.0, 1.0)
		"dash_cdr":
			player.dash_cooldown_mult *= 0.65
		"heal_full":
			player.health_component.max_health += 40.0
			player.health_component.current_health = player.health_component.max_health
			if hud != null and hud.has_method("update_health"):
				hud.update_health(player.health_component.current_health, player.health_component.max_health)
		"mage_haste":
			buff_companion.call("cast_cooldown", 0.60)
		# Cartas SSR
		"lifesteal":
			player.lifesteal_on_kill += 2.5
		"atk_spd":
			player.attack_speed_mult += 0.50
		"mage_dmg":
			buff_companion.call("projectile_damage", 1.60)
		"ssr_vampire":
			player.lifesteal_on_kill += 4.0
			player.attack_speed_mult += 0.40
		"ssr_storm":
			player.attack_speed_mult += 0.75
			player.move_speed_mult += 0.35
		# Cartas EX (Cheats Iniciais)
		"ex_abyss":
			player.abyssal_burst_unlocked = true
		"ex_god":
			player.damage_mult *= 2.0
			player.dash_cooldown_mult *= 0.40
		"ex_mage_wrath":
			buff_companion.call("projectiles_per_cast", 1.0, 2.0)
			buff_companion.call("projectile_damage", 2.0)
		# Cartas R
		"vorpal_sword":
			player.vorpal_sword_unlocked = true
			player._apply_weapon_mode()
		"alpha_strike":
			player.alpha_strike_unlocked = true
		"wind_momentum":
			player.wind_momentum_unlocked = true
			player.move_speed_mult += 0.20 # FIX: Adicionar movespeed
		"spread_shot":
			player.set_meta("spread_shot_unlocked", true)
		# Cartas SR
		"spin_attack":
			player.spin_attack_unlocked = true
		"glacial_prison":
			player.set_meta("glacial_prison_unlocked", true)
		"insatiable_hunger":
			player.insatiable_hunger_unlocked = true
		"solar_flare":
			player.set_meta("solar_flare_unlocked", true)
		# Cartas SSR
		"cosmic_rupture":
			player.cosmic_rupture_unlocked = true
		"void_feast":
			player.void_feast_unlocked = true
		"noxian_guillotine":
			player.noxian_guillotine_unlocked = true
		"ancestral_resurrect":
			player.ancestral_resurrect_unlocked = true
		# Cartas EX
		"glyph_fury":
			player.set_meta("glyph_fury_unlocked", true)
		"demigod_forge":
			if gacha_screen != null:
				gacha_screen.demigod_forge_active = true
		# Cartas Boss
		"realm_of_death":
			player.set_meta("realm_of_death_unlocked", true)
		# Cartas de Roubo de Chefe (Boss Theft)
		"boss_demon_heart":
			player.health_component.max_health += 100.0
			player.health_component.current_health = player.health_component.max_health
			player.fire_pulse_unlocked = true
			if hud != null and hud.has_method("update_health"):
				hud.update_health(player.health_component.current_health, player.health_component.max_health)
		"boss_executioner":
			player.executioner_unlocked = true
			player.damage_mult += 0.40
		"boss_meteor":
			buff_companion.call("projectile_damage", 2.20)
			buff_companion.call("projectiles_per_cast", 1.0, 1.0)
