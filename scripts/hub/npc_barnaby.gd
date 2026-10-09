class_name NPCBarnaby
extends CharacterBody2D

## Taberneiro Barnaby da Taverna de Greyrock.
## Oferece boatos táticos e gerencia o recrutamento de mercenários.

signal interacted()

@export var tavern_recruit_modal: Control = null
@export var dialogue_box: CanvasLayer = null

var is_player_in_range: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	if sprite != null and sprite.texture == null:
		sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0086.png")
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

func interact() -> void:
	interacted.emit()
	var greeting := "Bem-vindo à Taverna do Javali Saltitante! Descanse os pés, ouça os boatos sobre os monstros e contrate mercenários valorosos para cobrir sua retaguarda."
	var dlg: Node = dialogue_box
	if dlg == null:
		var tree := get_tree()
		if tree != null and tree.root != null:
			dlg = tree.root.find_child("BottomDialogueBox", true, false)
	if dlg != null and is_instance_valid(dlg) and dlg.has_method("show_dialogue"):
		dlg.call("show_dialogue", "Barnaby (Taberneiro)", greeting, func():
			open_tavern_ui()
		)
	else:
		open_tavern_ui()

func open_tavern_ui() -> void:
	if tavern_recruit_modal != null and is_instance_valid(tavern_recruit_modal) and tavern_recruit_modal.has_method("open"):
		tavern_recruit_modal.open()
	else:
		var tree := get_tree()
		if tree != null:
			var modal: Node = tree.root.find_child("TavernRecruitModal", true, false)
			if modal != null and modal.has_method("open"):
				modal.open()

func get_random_rumor() -> String:
	var rumors := get_all_rumors()
	if rumors.is_empty():
		return "Nada de novo sob o céu de cinzas."
	return rumors[randi() % rumors.size()]

func get_all_rumors() -> Array[String]:
	if tavern_recruit_modal != null and tavern_recruit_modal.has_method("get_rumors"):
		return tavern_recruit_modal.get_rumors()
	return [
		"O Colosso Ignis absorve 90% dos golpes até que você derrube os dois monólitos!",
		"Glacies congela os incautos em Tumbas de Gelo na Fase 2; quebre-as antes de 6 segundos!",
		"Preste atenção no linguajar dos recrutas: palavras revelam seu verdadeiro Eneagrama."
	]
