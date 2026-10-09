class_name GameManagerClass
extends Node

## Centralized Game Manager AutoLoad.
## Manages scene transitions (Hub <-> Dungeon), active party roster persistence,
## quest selection state, and smooth 0.35s fade transitions.

signal scene_transition_started(target_scene: String)
signal scene_transition_finished(target_scene: String)
signal party_roster_changed(new_roster: Array[Dictionary])
signal quest_selected(rank: String)

const FADE_DURATION: float = 0.35
const MAX_PARTY_SIZE: int = 3
const SCENE_HUB: String = "res://scenes/hub/greyrock_village.tscn"
const SCENE_ARENA: String = "res://scenes/arena/arena.tscn"
const SCENE_FORTRESS: String = "res://scenes/dungeon/ruined_fortress.tscn"

var active_party_roster: Array[Dictionary] = []
var selected_quest_rank: String = "F"
var total_completed_runs: int = 0
var is_transitioning: bool = false

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
