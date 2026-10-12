class_name TavernRecruitModal
extends Control

## Modal da Taverna do Barnaby.
## Apresenta boatos táticos sobre os Guardiões Elementais e leylines,
## e permite recrutar mercenários deduzindo seu Eneagrama através de falas autênticas.

signal mercenary_hired(candidate: Dictionary)
signal modal_closed()

const TACTICAL_RUMORS: Array[String] = [
	"\"Ouça com atenção, novato: o Colosso Ignis mitiga 90% do dano enquanto os dois monólitos de leyline estiverem erguidos. Destrua os monólitos para induzir 4 segundos de sobrecarga crítica!\"",
	"\"O Soberano Glacies aprisiona seus companheiros em Tumbas de Gelo na Fase 2. Se você quebrar o gelo em até 6 segundos, você salva a vida dele e fortalece o laço da equipe!\"",
	"\"Mercenários têm temperamentos distintos. Quem fala de força bruta odeia recuar. Quem calcula tudo entra em pânico se cercado. Observe o que eles dizem antes de contratar.\"",
	"\"Um bom líder não dá ordens de ataque para aliados à beira da morte. Abandonar companheiros feridos mancha sua reputação para sempre nas sombras.\""
]

const MERCENARY_CANDIDATES: Array[Dictionary] = [
	{
		"id": "paladin_roland",
		"name": "Roland",
		"class_name": "Paladino",
		"class_type": "paladin",
		"enneagram_type": 8,
		"enneagram_name": "Tipo 8 (O Desafiador)",
		"quote": "Se o inimigo não cair no primeiro golpe, eu quebro o escudo dele no meio. Não me peça para dar passos para trás!",
		"role_desc": "Tanque Corpo a Corpo (160 HP, Armadura 25%, Carga com Escudo & Atordoamento)",
		"icon_tile": "tile_0087.png",
		"cost": 150
	},
	{
		"id": "archer_lyra",
		"name": "Lyra",
		"class_name": "Arqueira",
		"class_type": "archer",
		"enneagram_type": 5,
		"enneagram_name": "Tipo 5 (O Investigador)",
		"quote": "Calculo o vento e os ângulos balísticos a cada disparo. Se formos cercados por enxames caóticos sem espaço para analisar, precisarei me afastar.",
		"role_desc": "Suporte de Longo Alcance (75 HP, 145 px/s, Flechas Perfurantes & Armadilha de Lentidão 55%)",
		"icon_tile": "tile_0096.png",
		"cost": 120
	},
	{
		"id": "mage_morgana",
		"name": "Morgana",
		"class_name": "Maga Elemental",
		"class_type": "mage",
		"enneagram_type": 1,
		"enneagram_name": "Tipo 1 (O Reformador)",
		"quote": "A disciplina na formação é indispensável. Cada feitiço elemental deve ser disparado estritamente conforme o protocolo tático estabelecido.",
		"role_desc": "Conjuradora em Área (Feitiços de Fogo e Gelo, Dano Elemental Contínuo)",
		"icon_tile": "tile_0085.png",
		"cost": 140
	},
	{
		"id": "rogue_silas",
		"name": "Silas",
		"class_name": "Ladino",
		"class_type": "rogue",
		"enneagram_type": 7,
		"enneagram_name": "Tipo 7 (O Entusiasta)",
		"quote": "Adrenalina é meu combustível! Se o plano for ficar parado tomando pancada, nem me chame.",
		"role_desc": "Combatente Ágil (90 HP, 150 px/s, Ataque com Adagas, Dash com Dano & Furtividade)",
		"icon_tile": "tile_0088.png",
		"cost": 130
	}
]

var _current_rumor_idx: int = 0

@onready var rumor_label: Label = find_child("RumorLabel", true, false) as Label
@onready var next_rumor_btn: Button = find_child("NextRumorButton", true, false) as Button
@onready var roster_container: HBoxContainer = find_child("MercenaryHBox", true, false) as HBoxContainer
@onready var status_label: Label = find_child("StatusLabel", true, false) as Label
@onready var party_status_label: Label = find_child("PartyCountLabel", true, false) as Label
@onready var close_button: Button = find_child("CloseButton", true, false) as Button
@onready var gold_label: Label = find_child("GoldLabel", true, false) as Label

func _ready() -> void:
	visible = false
	if close_button != null:
		close_button.pressed.connect(close)
	if next_rumor_btn != null:
		next_rumor_btn.pressed.connect(func(): cycle_rumor())
	_render_candidates()
	_update_rumor_display()

func open() -> void:
	visible = true
	_update_rumor_display()
	_render_candidates()
	_update_party_count()
	_update_gold_display()
	if status_label != null:
		status_label.text = "Barnaby: \"Tome um trago e escolha com quem você quer sangrar nas ruínas.\""

func close() -> void:
	visible = false
	modal_closed.emit()

func get_candidates() -> Array[Dictionary]:
	return MERCENARY_CANDIDATES

func get_rumors() -> Array[String]:
	return TACTICAL_RUMORS

func cycle_rumor() -> String:
	_current_rumor_idx = (_current_rumor_idx + 1) % TACTICAL_RUMORS.size()
	var r := TACTICAL_RUMORS[_current_rumor_idx]
	_update_rumor_display()
	return r

func _update_rumor_display() -> void:
	if rumor_label != null and TACTICAL_RUMORS.size() > 0:
		rumor_label.text = TACTICAL_RUMORS[_current_rumor_idx]

func _update_gold_display() -> void:
	if gold_label == null:
		return
	var tree := get_tree()
	if tree != null:
		var gm: Node = tree.root.get_node_or_null("GameManager")
		if gm != null and gm.has_method("get_gold"):
			gold_label.text = "Ouro: %d" % gm.get_gold()

func _update_party_count() -> void:
	var current_count := 0
	var tree := get_tree()
	var gm: Node = null
	if tree != null:
		gm = tree.root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("get_active_party_roster"):
		current_count = gm.get_active_party_roster().size()
	if party_status_label != null:
		party_status_label.text = "Grupo: %d / 3" % current_count

func _render_candidates() -> void:
	if roster_container == null:
		return
	for c in roster_container.get_children():
		c.queue_free()

	for merc in MERCENARY_CANDIDATES:
		var card := _create_candidate_card(merc)
		roster_container.add_child(card)

func _create_candidate_card(merc: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(110, 130)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = "%s (%s)" % [merc["name"], merc["class_name"]]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.modulate = Color(1.0, 0.9, 0.5)
	name_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name_lbl)

	var quote_lbl := Label.new()
	quote_lbl.text = "\"%s\"" % merc["quote"]
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_lbl.custom_minimum_size = Vector2(40, 0)
	quote_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quote_lbl.add_theme_font_size_override("font_size", 8)
	quote_lbl.modulate = Color(0.85, 0.9, 1.0)
	vbox.add_child(quote_lbl)

	var role_lbl := Label.new()
	role_lbl.text = merc["role_desc"]
	role_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role_lbl.custom_minimum_size = Vector2(40, 0)
	role_lbl.add_theme_font_size_override("font_size", 8)
	role_lbl.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(role_lbl)

	var btn := Button.new()
	btn.name = "HireButton_" + merc["id"]
	btn.custom_minimum_size = Vector2(0, 20)
	btn.add_theme_font_size_override("font_size", 9)
	var hired := is_candidate_hired(merc["id"])
	if hired:
		btn.text = "Recrutado ✓"
		btn.disabled = true
		btn.modulate = Color(0.5, 1.0, 0.5)
	else:
		btn.text = "Recrutar (%d Ouro)" % merc.get("cost", 100)
		btn.pressed.connect(func():
			hire_candidate(merc["id"])
		)
	vbox.add_child(btn)

	return panel

func is_candidate_hired(candidate_id: String) -> bool:
	var tree := get_tree()
	var gm: Node = null
	if tree != null:
		gm = tree.root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("has_mercenary"):
		return gm.has_mercenary(candidate_id)
	return false

func hire_candidate(candidate_id: String) -> bool:
	var candidate: Dictionary = {}
	for m in MERCENARY_CANDIDATES:
		if m["id"] == candidate_id:
			candidate = m
			break

	if candidate.is_empty():
		return false

	var tree := get_tree()
	var gm: Node = null
	if tree != null:
		gm = tree.root.get_node_or_null("GameManager")

	if gm != null:
		if gm.has_method("has_mercenary") and gm.has_mercenary(candidate_id):
			if status_label != null:
				status_label.text = "Mercenário %s já faz parte do grupo!" % candidate["name"]
			return false

		if gm.has_method("get_active_party_roster") and gm.get_active_party_roster().size() >= 3:
			if status_label != null:
				status_label.text = "Grupo cheio! O limite é de 3 companheiros."
			return false

		if gm.has_method("spend_gold"):
			if not gm.spend_gold(candidate.get("cost", 100)):
				if status_label != null:
					status_label.text = "Ouro insuficiente!"
				return false

		if gm.has_method("add_to_party_roster"):
			var success: bool = gm.add_to_party_roster(candidate)
			if success:
				if status_label != null:
					status_label.text = "%s foi recrutado com sucesso para a expedição!" % candidate["name"]
				mercenary_hired.emit(candidate)
				_render_candidates()
				_update_party_count()
				_update_gold_display()
				return true
			else:
				if status_label != null:
					status_label.text = "Falha ao recrutar %s." % candidate["name"]
				return false

	return false
