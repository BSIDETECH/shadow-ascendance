import re

with open("scripts/ui/gacha_screen.gd", "r") as f:
    content = f.read()

func_is_card_valid = """
func _is_card_valid(card: Dictionary) -> bool:
	if not card.has("req_class"):
		return true

	var req_class = card["req_class"]
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm != null and gm.has_method("get_active_party_roster"):
		var roster = gm.get_active_party_roster()
		for member in roster:
			if member.get("class_type") == req_class:
				return true
	return false

func _create_card_button(card: Dictionary) -> void:"""

content = content.replace("func _create_card_button(card: Dictionary) -> void:", func_is_card_valid)

with open("scripts/ui/gacha_screen.gd", "w") as f:
    f.write(content)
