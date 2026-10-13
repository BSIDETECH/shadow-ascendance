class_name ShopModal
extends Control

signal shop_closed()

@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var roster_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/RosterContainer
@onready var header: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/Header
var gold_label: Label = null

func _ready() -> void:
	visible = false
	if close_button != null:
		close_button.pressed.connect(close)

	if roster_container != null:
		for child in roster_container.get_children():
			child.queue_free()

func open() -> void:
	visible = true
	_update_shop_list()

	if gold_label == null and header != null:
		gold_label = Label.new()
		gold_label.name = "GoldLabel"
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		gold_label.text = "Ouro: " + str(GameManager.get_gold())
		header.add_child(gold_label)
	elif gold_label != null:
		gold_label.text = "Ouro: " + str(GameManager.get_gold())

func close() -> void:
	visible = false
	shop_closed.emit()

func _update_shop_list() -> void:
	if roster_container == null:
		return

	for child in roster_container.get_children():
		child.queue_free()

	_add_item_to_shop("Poção de Vida", "Restaura 100 HP.", 10, "health")
	_add_item_to_shop("Poção de Escudo", "Concede 50 de escudo.", 10, "shield")
	_add_item_to_shop("Poção de Ressurreição", "Ressuscita um aliado caído.", 30, "revive")
	_add_item_to_shop("Poção de Barreira", "Escudo gigante.", 20, "barrier")

func _add_item_to_shop(item_name: String, description: String, cost: int, type: String) -> void:
	var item_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	item_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	item_panel.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = item_name
	name_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(desc_lbl)

	var btn = Button.new()
	btn.text = "Comprar (" + str(cost) + " Ouro)"
	btn.pressed.connect(func():
		_buy_item(cost, type)
	)
	vbox.add_child(btn)

	roster_container.add_child(item_panel)

func _process(_delta: float) -> void:
	if visible and roster_container != null:
		var current_gold = GameManager.get_gold()
		for panel in roster_container.get_children():
			var vbox = panel.get_child(0)
			if vbox != null:
				for child in vbox.get_children():
					if child is Button:
						if current_gold >= 10:
							child.disabled = false
						else:
							child.disabled = true

func _buy_item(cost: int, type: String) -> void:
	if GameManager.spend_gold(cost):
		if type == "health":
			GameManager.add_health_potion()
		elif type == "shield":
			GameManager.add_shield_potion()
		elif type == "revive":
			GameManager.add_revive_potion()
		elif type == "barrier":
			GameManager.add_barrier_potion()
		if gold_label != null:
			gold_label.text = "Ouro: " + str(GameManager.get_gold())
