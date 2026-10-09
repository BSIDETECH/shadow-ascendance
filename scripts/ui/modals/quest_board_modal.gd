class_name QuestBoardModal
extends Control

## Modal do Balcão de Missões da Guilda (Elena).
## Exibe missões de Rank F a S, bloqueando tiers avançados e
## disparando a transição para masmorras com a equipe ativa.

signal quest_accepted(rank: String)
signal modal_closed()

const QUEST_DATABASE: Dictionary = {
	"F": {
		"name": "Floresta dos Esqueletos",
		"subtitle": "Campo de Treino de Recrutas",
		"target": "Arena / Horda de Mortos-Vivos",
		"description": "Patrulha nos arredores da vila para conter a proliferação de esqueletos e slimes.",
		"unlocked": true,
		"criteria": "Nenhum (Disponível para todos os novatos)",
		"reward": "100 Gold + XP Básica"
	},
	"E": {
		"name": "Fortaleza em Ruínas",
		"subtitle": "Baluarte Ancestral de Ignis",
		"target": "Guardião Elemental Ignis & Monólitos",
		"description": "Penetre na fortaleza arruinada, desative os monólitos de leyline e enfrente o Colosso das Chamas.",
		"unlocked": true,
		"criteria": "Nenhum (Expedição Padrão)",
		"reward": "350 Gold + Alma de Guardião"
	},
	"D": {
		"name": "Cidadela de Gelo",
		"subtitle": "Trono Congelado de Glacies",
		"target": "Soberano do Gelo Glacies",
		"description": "Expedição às cavernas permafrost seladas por armadilhas gélidas.",
		"unlocked": false,
		"criteria": "Requer Rank E concluído e 3 expedições bem-sucedidas.",
		"reward": "800 Gold + Essência de Gelo Puro"
	},
	"C": {
		"name": "Cripta das Sombras",
		"subtitle": "Catacumbas dos Esquecidos",
		"target": "Arquimago Necrótico",
		"description": "Descenso às catacumbas profundas onde a luz da deusa não alcança.",
		"unlocked": false,
		"criteria": "Requer Rank D concluído.",
		"reward": "1500 Gold + Tomo Proibido"
	},
	"B": {
		"name": "Pico da Tempestade",
		"subtitle": "Ninho dos Wyverns Elétricos",
		"target": "Tempestade Viva",
		"description": "Ascensão pelas montanhas eletrificadas sob tempestade perpétua.",
		"unlocked": false,
		"criteria": "Requer Rank C concluído.",
		"reward": "3000 Gold + Núcleo Elétrico"
	},
	"A": {
		"name": "Abismo das Chamas",
		"subtitle": "Fenda Infernal",
		"target": "Lorde Demoníaco do Abismo",
		"description": "Incursão ao coração do vulcão primordial.",
		"unlocked": false,
		"criteria": "Requer Rank B concluído.",
		"reward": "6500 Gold + Forja Divina"
	},
	"S": {
		"name": "Trono da Deusa Sombria",
		"subtitle": "Julgamento Final da Ascensão",
		"target": "Avatar do Destino",
		"description": "Confronto definitivo onde o destino da aliança ou a solidão eterna será selado.",
		"unlocked": false,
		"criteria": "Requer Rank A concluído e Agência Orgânica comprovada.",
		"reward": "Ascensão Heroica"
	}
}

var _selected_rank: String = "F"

@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var quest_list_container: VBoxContainer = find_child("QuestListContainer", true, false) as VBoxContainer
@onready var detail_title: Label = find_child("DetailTitle", true, false) as Label
@onready var detail_desc: Label = find_child("DetailDesc", true, false) as Label
@onready var detail_criteria: Label = find_child("DetailCriteria", true, false) as Label
@onready var detail_reward: Label = find_child("DetailReward", true, false) as Label
@onready var start_button: Button = find_child("StartButton", true, false) as Button
@onready var status_label: Label = find_child("StatusLabel", true, false) as Label
@onready var close_button: Button = find_child("CloseButton", true, false) as Button

func _ready() -> void:
	visible = false
	if close_button != null:
		close_button.pressed.connect(close)
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
	_build_quest_list()
	_update_details("F")

func _build_quest_list() -> void:
	if quest_list_container == null:
		return
	for c in quest_list_container.get_children():
		c.queue_free()

	for rank in get_all_ranks():
		var data: Dictionary = QUEST_DATABASE[rank]
		var btn := Button.new()
		btn.name = "RankButton_" + rank
		btn.text = "Rank %s: %s" % [rank, data["name"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 10)
		btn.custom_minimum_size = Vector2(0, 24)
		
		var is_unlocked := is_rank_unlocked(rank)
		if not is_unlocked:
			btn.text += " [BLOQUEADO]"
			btn.modulate = Color(0.65, 0.65, 0.65, 0.8)
		else:
			btn.modulate = Color(1.0, 0.95, 0.8, 1.0)
		
		btn.pressed.connect(func():
			_selected_rank = rank
			_update_details(rank)
		)
		quest_list_container.add_child(btn)

func _update_details(rank: String) -> void:
	if not QUEST_DATABASE.has(rank):
		return
	var data: Dictionary = QUEST_DATABASE[rank]
	var unlocked := is_rank_unlocked(rank)

	if detail_title != null:
		detail_title.text = "Rank %s — %s (%s)" % [rank, data["name"], data["subtitle"]]
	if detail_desc != null:
		detail_desc.text = data["description"]
	if detail_criteria != null:
		detail_criteria.text = "Requisito: " + data["criteria"]
		detail_criteria.modulate = Color(0.4, 1.0, 0.5) if unlocked else Color(1.0, 0.4, 0.4)
	if detail_reward != null:
		detail_reward.text = "Recompensa: " + data["reward"]
	if start_button != null:
		start_button.disabled = not unlocked
		start_button.text = "Iniciar Expedição" if unlocked else "Bloqueada"
	if status_label != null:
		status_label.text = "" if unlocked else "Esta missão exige maior renome na guilda."

func _on_start_pressed() -> void:
	select_quest(_selected_rank)

func open() -> void:
	visible = true
	_selected_rank = "F"
	_update_details("F")
	if status_label != null:
		status_label.text = "Escolha sua próxima missão no Quadro de Avisos."

func close() -> void:
	visible = false
	modal_closed.emit()

func select_quest(rank: String) -> bool:
	if not is_rank_unlocked(rank):
		var details := get_quest_details(rank)
		var crit: String = details.get("criteria", "Requisito não atingido.")
		if status_label != null:
			status_label.text = "Missão Rank %s Bloqueada! %s" % [rank, crit]
		return false

	var tree := get_tree()
	var gm: Node = null
	if tree != null:
		gm = tree.root.get_node_or_null("GameManager")

	var active_party: Array[Dictionary] = []
	if gm != null and gm.has_method("get_active_party_roster"):
		active_party = gm.get_active_party_roster()

	if gm != null and gm.has_method("transition_to_dungeon"):
		gm.transition_to_dungeon(rank, active_party)

	quest_accepted.emit(rank)
	close()
	return true

func is_rank_unlocked(rank: String) -> bool:
	return rank in get_available_ranks()

func get_available_ranks() -> Array[String]:
	return ["F", "E"]

func get_all_ranks() -> Array[String]:
	return ["F", "E", "D", "C", "B", "A", "S"]

func get_quest_details(rank: String) -> Dictionary:
	return QUEST_DATABASE.get(rank, {})
