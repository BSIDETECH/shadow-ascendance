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
@onready var blacksmith: Node2D = $Blacksmith
@onready var madre_selene: Node2D = $MadreSelene
@onready var quest_board_modal: Control = $UI/QuestBoardModal
@onready var armory_modal: Control = $UI/ArmoryModal
@onready var tavern_recruit_modal: Control = $UI/TavernRecruitModal
@onready var hub_hud: Control = $UI/HubHUD
@onready var bottom_dialogue_box: CanvasLayer = $UI/BottomDialogueBox
@onready var instruction_label: Label = $UI/HubHUD/InstructionLabel

func _ready() -> void:
	_configure_player_non_combat()
	_wire_npc_modals()
	_wire_modal_hud_toggle()
	_setup_gold_hud()

func _setup_gold_hud() -> void:
	if hub_hud != null:
		var gold_label = Label.new()
		gold_label.name = "GoldLabel"
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		gold_label.add_theme_font_size_override("font_size", 12)
		gold_label.text = "💰 Ouro: " + str(GameManager.get_gold() if GameManager.has_method("get_gold") else 0)

		# Position in top-right corner or similar
		gold_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		gold_label.position = Vector2(hub_hud.size.x - 100, 10)
		hub_hud.add_child(gold_label)

		var eb = get_tree().root.get_node_or_null("EventBus")
		if eb != null and eb.has_signal("gold_changed"):
			eb.gold_changed.connect(func(new_gold: int):
				var lbl = hub_hud.get_node_or_null("GoldLabel")
				if lbl != null:
					lbl.text = "💰 Ouro: " + str(new_gold)
			)

func _configure_player_non_combat() -> void:
	if player != null:
		player.can_attack = false
		player.combat_enabled = false

func _wire_npc_modals() -> void:
	if elena != null and quest_board_modal != null:
		elena.quest_board_modal = quest_board_modal
	if barnaby != null and tavern_recruit_modal != null:
		barnaby.tavern_recruit_modal = tavern_recruit_modal
	if blacksmith != null and armory_modal != null:
		blacksmith.armory_modal = armory_modal
	if bottom_dialogue_box != null:
		if elena != null:
			elena.dialogue_box = bottom_dialogue_box
		if barnaby != null:
			barnaby.dialogue_box = bottom_dialogue_box
		if blacksmith != null:
			blacksmith.dialogue_box = bottom_dialogue_box
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
	if armory_modal != null:
		armory_modal.visibility_changed.connect(_update_hub_hud_visibility)
	_update_hub_hud_visibility()

func _update_hub_hud_visibility() -> void:
	if hub_hud == null:
		return
	var modal_open: bool = (quest_board_modal != null and quest_board_modal.visible) or (tavern_recruit_modal != null and tavern_recruit_modal.visible) or (armory_modal != null and armory_modal.visible)
	hub_hud.visible = not modal_open

func is_non_combat_zone() -> bool:
	return true

func get_village_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(map_width, map_height))
