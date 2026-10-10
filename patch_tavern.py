import re

with open('scripts/ui/modals/tavern_recruit_modal.gd', 'r') as f:
    content = f.read()

# 1. Add Silas to MERCENARY_CANDIDATES
silas_entry = """	{
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
]"""

content = content.replace("	}\n]", silas_entry)

# 2. Add spend_gold check in hire_candidate
hire_check_original = """		if gm.has_method("add_to_party_roster"):"""
hire_check_new = """		if gm.has_method("spend_gold"):
			if not gm.spend_gold(candidate.get("cost", 100)):
				if status_label != null:
					status_label.text = "Ouro insuficiente!"
				return false

		if gm.has_method("add_to_party_roster"):"""

content = content.replace(hire_check_original, hire_check_new)

with open('scripts/ui/modals/tavern_recruit_modal.gd', 'w') as f:
    f.write(content)
