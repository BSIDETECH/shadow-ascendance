class_name NPCBlacksmith
extends CharacterBody2D

## Ferreiro Gromm da Vila de Greyrock.
## Vende melhorias de equipamento.
##

signal interacted()

@export var armory_modal: Control = null
@export var dialogue_box: CanvasLayer = null

var is_player_in_range: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	if sprite != null and sprite.texture == null:
		sprite.texture = load("res://assets/kenney_tiny_dungeon/Tiles/tile_0083.png")
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
	var greeting := "O aço não mente, forasteiro. Mostre-me seu ouro e eu lhe mostrarei o poder da minha forja."
	var dlg: Node = dialogue_box
	if dlg == null:
		var tree := get_tree()
		if tree != null and tree.root != null:
			dlg = tree.root.find_child("BottomDialogueBox", true, false)
	if dlg != null and is_instance_valid(dlg) and dlg.has_method("show_dialogue"):
		dlg.call("show_dialogue", "Gromm (Ferreiro)", greeting, func():
			open_armory_ui()
		)
	else:
		open_armory_ui()

func open_armory_ui() -> void:
	if armory_modal != null and is_instance_valid(armory_modal) and armory_modal.has_method("open"):
		armory_modal.open()
	else:
		var tree := get_tree()
		if tree != null:
			var modal: Node = tree.root.find_child("ArmoryModal", true, false)
			if modal != null and modal.has_method("open"):
				modal.open()
