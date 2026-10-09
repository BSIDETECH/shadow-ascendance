class_name NPCMadreSelene
extends CharacterBody2D

## Vidente Madre Selene no Santuário de Greyrock.
## Entrega presságios enigmáticos baseados na conduta silenciosa do jogador.

signal omen_delivered(omen: Dictionary)
signal interacted()

@export var dialogue_box: CanvasLayer = null

var is_player_in_range: bool = false
var last_omen: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	if sprite != null and sprite.texture == null:
		sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0100.png")
	if interaction_prompt != null:
		interaction_prompt.visible = false
	if interaction_area != null:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if is_player_in_range and event.is_action_pressed("interact"):
		interact()
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is Player:
		is_player_in_range = true
		if interaction_prompt != null:
			interaction_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body is Player:
		is_player_in_range = false
		if interaction_prompt != null:
			interaction_prompt.visible = false
		if dialogue_box != null and is_instance_valid(dialogue_box) and dialogue_box.visible:
			dialogue_box.call("close_dialogue")

func interact() -> String:
	interacted.emit()
	var omen := get_current_omen()
	last_omen = omen
	omen_delivered.emit(omen)

	var omen_text: String = omen.get("text", "")
	var dlg: Node = dialogue_box
	if dlg == null:
		var tree := get_tree()
		if tree != null and tree.root != null:
			dlg = tree.root.find_child("BottomDialogueBox", true, false)
	if dlg != null and is_instance_valid(dlg) and dlg.has_method("show_dialogue"):
		dlg.call("show_dialogue", "Madre Selene (Vidente)", omen_text)

	return omen_text

func get_current_omen() -> Dictionary:
	var total_runs := 0
	var tree := get_tree()
	var gm: Node = null
	if tree != null:
		gm = tree.root.get_node_or_null("GameManager")
	if gm != null:
		total_runs = gm.get("total_completed_runs") if gm.get("total_completed_runs") != null else 0

	# Silent agency evaluation if tracker exists
	var tracker: Node = null
	if tree != null:
		tracker = tree.root.get_node_or_null("SilentAgencyTracker")

	var omen_type := "INTRODUCTORY" if total_runs == 0 else "PROPHECY"
	var text := ""
	var conduct := "NEUTRAL"

	if omen_type == "INTRODUCTORY":
		text = "Vejo o fio da sua alma ainda intacto, estrangeiro... As escolhas na escuridão determinarão se você ascenderá como líder dos vivos ou reinará como um monstro solitário."
		conduct = "FRESH_SAVE"
	else:
		var agency_score: int = 50
		var fallen: int = 0
		if tracker != null:
			agency_score = tracker.get("agency_score") if tracker.get("agency_score") != null else 50
			fallen = tracker.get("allies_fallen") if tracker.get("allies_fallen") != null else 0

		if agency_score >= 50 and fallen <= 1:
			conduct = "BENEVOLENT"
			text = "Os sussurros do além cantam sobre lealdade... As correntes de sangue mantêm seus aliados de pé. A aliança dos vivos resiste ao abismo."
		elif agency_score < 0 or fallen >= 3:
			conduct = "ISOLATIONIST"
			text = "O cheiro de cinzas e abandono o precede... Vejo companheiros caídos cujos nomes você já esqueceu. O abismo solitário o espera no final da trilha."
		else:
			conduct = "UNSTABLE"
			text = "O equilíbrio da sua liderança oscila sobre uma lâmina afiada. Cada ordem impensada empurra seus aliados mais perto do silêncio perpétuo."

	return {
		"type": omen_type,
		"text": text,
		"conduct": conduct,
		"total_runs": total_runs
	}
