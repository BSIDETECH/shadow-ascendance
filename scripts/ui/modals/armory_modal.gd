const ARMORY_UPGRADES: Array[Dictionary] = [
	{
		"id": "dmg_up",
		"name": "Afiador de Lâminas",
		"desc": "+5 Dano Base",
		"cost": 150,
		"type": "damage",
		"value": 5.0
	},
	{
		"id": "hp_up",
		"name": "Forja de Armadura",
		"desc": "+20 Vida Máxima",
		"cost": 150,
		"type": "health",
		"value": 20.0
	},
	{
		"id": "spd_up",
		"name": "Botas Leves",
		"desc": "+10 Velocidade",
		"cost": 200,
		"type": "speed",
		"value": 10.0
	}
]
class_name ArmoryModal
extends Control

## Modal da Forja de Gromm.
## Permite comprar upgrades permanentes de equipamento.

signal upgrade_purchased(upgrade_id: String)
signal modal_closed()



@onready var roster_container: HBoxContainer = find_child("UpgradesHBox", true, false) as HBoxContainer
@onready var status_label: Label = find_child("StatusLabel", true, false) as Label
@onready var party_status_label: Label = find_child("GoldLabel", true, false) as Label
@onready var close_button: Button = find_child("CloseButton", true, false) as Button

func _ready() -> void:
	visible = false
	if close_button != null:
		close_button.pressed.connect(close)
	_render_upgrades()

func open() -> void:
	visible = true
	_render_upgrades()
	_update_gold_count()
	if status_label != null:
		status_label.text = "Gromm: \"Boas lâminas custam caro.\""

func close() -> void:
	visible = false
	modal_closed.emit()

func _update_gold_count() -> void:
	var current_gold := 0
	var tree := get_tree()
	var gm: Node = null
	if tree != null:
		gm = tree.root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("get_gold"):
		current_gold = gm.get_gold()
	if party_status_label != null:
		party_status_label.text = "Ouro: %d" % current_gold

func _render_upgrades() -> void:
	if roster_container == null:
		return
	for c in roster_container.get_children():
		c.queue_free()

	for upg in ARMORY_UPGRADES:
		var card := _create_upgrade_card(upg)
		roster_container.add_child(card)

func _create_upgrade_card(upg: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 140)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)


	var name_lbl := Label.new()
	name_lbl.text = upg["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.modulate = Color(1.0, 0.9, 0.5)
	name_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = upg["desc"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.modulate = Color(0.85, 0.9, 1.0)
	vbox.add_child(desc_lbl)

	var btn := Button.new()
	btn.name = "BuyButton_" + upg["id"]
	btn.add_theme_font_size_override("font_size", 10)
	btn.text = "Comprar (%d Ouro)" % upg.get("cost", 100)
	btn.pressed.connect(func():
		buy_upgrade(upg["id"])
	)
	vbox.add_child(btn)

	return panel



func buy_upgrade(upgrade_id: String) -> bool:
	var upg: Dictionary = {}
	for u in ARMORY_UPGRADES:
		if u["id"] == upgrade_id:
			upg = u
			break

	if upg.is_empty():
		return false

	var tree := get_tree()
	var gm: Node = null
	if tree != null:
		gm = tree.root.get_node_or_null("GameManager")

	if gm != null:
		if gm.has_method("spend_gold"):
			if not gm.spend_gold(upg.get("cost", 100)):
				if status_label != null:
					status_label.text = "Ouro insuficiente!"
				return false
		elif "player_gold" in gm:
			if gm.player_gold >= upg.get("cost", 100):
				gm.player_gold -= upg.get("cost", 100)
			else:
				if status_label != null:
					status_label.text = "Ouro insuficiente!"
				return false

		if gm.has_method("buy_blacksmith_upgrade"):
			gm.buy_blacksmith_upgrade(upg["type"], upg["value"])
			if status_label != null:
				status_label.text = "Melhoria '%s' comprada com sucesso!" % upg["name"]
			upgrade_purchased.emit(upg["id"])
			_update_gold_count()
			return true
	return false
