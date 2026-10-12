import re

# 1. Ruined Fortress
with open('scripts/dungeon/ruined_fortress.gd', 'r') as f:
    rf_content = f.read()

rf_rogue_entry = """			"archer":
				var ArcherClass = load("res://scripts/entities/companion_archer.gd")
				if ArcherClass != null:
					comp_node = ArcherClass.new()
			"rogue":
				var RogueClass = load("res://scripts/entities/companion_rogue.gd")
				if RogueClass != null:
					comp_node = RogueClass.new()"""

rf_content = rf_content.replace('''			"archer":
				var ArcherClass = load("res://scripts/entities/companion_archer.gd")
				if ArcherClass != null:
					comp_node = ArcherClass.new()''', rf_rogue_entry)

with open('scripts/dungeon/ruined_fortress.gd', 'w') as f:
    f.write(rf_content)
