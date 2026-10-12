with open('scripts/hub/greyrock_village.gd', 'r') as f:
    content = f.read()

hud_setup = """func _ready() -> void:
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
			)"""

content = content.replace("func _ready() -> void:\n\t_configure_player_non_combat()\n\t_wire_npc_modals()\n\t_wire_modal_hud_toggle()", hud_setup)

with open('scripts/hub/greyrock_village.gd', 'w') as f:
    f.write(content)
