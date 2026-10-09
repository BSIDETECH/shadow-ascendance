class_name GreyrockVillage
extends Node2D

## Cenário central de exploração: Vila de Greyrock.
## Zona pacífica sem monstros, com movimentação livre do protagonista,
## acompanhamento de câmera, NPCs interativos e balcão de expedições.

@export var map_width: float = 640.0
@export var map_height: float = 360.0

@onready var player: Player = $Player
@onready var elena: Node2D = $Elena
@onready var barnaby: Node2D = $Barnaby
@onready var madre_selene: Node2D = $MadreSelene
@onready var quest_board_modal: Control = $UI/QuestBoardModal
@onready var tavern_recruit_modal: Control = $UI/TavernRecruitModal
@onready var hub_hud: Control = $UI/HubHUD
@onready var bottom_dialogue_box: CanvasLayer = $UI/BottomDialogueBox
@onready var instruction_label: Label = $UI/HubHUD/InstructionLabel

func _ready() -> void:
	_configure_player_non_combat()
	_wire_npc_modals()
	_wire_modal_hud_toggle()

func _configure_player_non_combat() -> void:
	if player != null:
		player.can_attack = false
		player.combat_enabled = false

func _wire_npc_modals() -> void:
	if elena != null and quest_board_modal != null:
		elena.quest_board_modal = quest_board_modal
	if barnaby != null and tavern_recruit_modal != null:
		barnaby.tavern_recruit_modal = tavern_recruit_modal
	if bottom_dialogue_box != null:
		if elena != null:
			elena.dialogue_box = bottom_dialogue_box
		if barnaby != null:
			barnaby.dialogue_box = bottom_dialogue_box
		if madre_selene != null:
			madre_selene.dialogue_box = bottom_dialogue_box
		bottom_dialogue_box.visibility_changed.connect(_on_dialogue_visibility_changed)

func _on_dialogue_visibility_changed() -> void:
	if instruction_label != null and bottom_dialogue_box != null:
		instruction_label.visible = not bottom_dialogue_box.visible

func _wire_modal_hud_toggle() -> void:
	if quest_board_modal != null:
		quest_board_modal.visibility_changed.connect(_update_hub_hud_visibility)
	if tavern_recruit_modal != null:
		tavern_recruit_modal.visibility_changed.connect(_update_hub_hud_visibility)
	_update_hub_hud_visibility()

func _update_hub_hud_visibility() -> void:
	if hub_hud == null:
		return
	var modal_open: bool = (quest_board_modal != null and quest_board_modal.visible) or (tavern_recruit_modal != null and tavern_recruit_modal.visible)
	hub_hud.visible = not modal_open

func is_non_combat_zone() -> bool:
	return true

func get_village_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(map_width, map_height))
