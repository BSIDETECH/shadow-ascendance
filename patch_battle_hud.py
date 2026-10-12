with open('scripts/ui/hud.gd', 'r') as f:
    content = f.read()

hud_setup = """		if eb.has_signal("leadership_order_failed"):
			eb.leadership_order_failed.connect(_on_leadership_order_failed)

		if eb.has_signal("gold_changed"):
			eb.gold_changed.connect(_on_gold_changed)

	_setup_gold_hud()
	update_leadership_charges(3, 3)

func _setup_gold_hud() -> void:
	if kills_label != null and kills_label.get_parent() != null:
		var parent = kills_label.get_parent()
		var gold_label = Label.new()
		gold_label.name = "GoldLabel"
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		gold_label.add_theme_font_size_override("font_size", 12)
		var gm = get_tree().root.get_node_or_null("GameManager")
		gold_label.text = "💰 Ouro: " + str(gm.get_gold() if gm != null and gm.has_method("get_gold") else 0)
		parent.add_child(gold_label)

func _on_gold_changed(new_gold: int) -> void:
	if kills_label != null and kills_label.get_parent() != null:
		var gold_label = kills_label.get_parent().get_node_or_null("GoldLabel")
		if gold_label != null:
			gold_label.text = "💰 Ouro: " + str(new_gold)"""

content = content.replace("""		if eb.has_signal("leadership_order_failed"):
			eb.leadership_order_failed.connect(_on_leadership_order_failed)

	update_leadership_charges(3, 3)""", hud_setup)

with open('scripts/ui/hud.gd', 'w') as f:
    f.write(content)
