with open('scripts/arena/arena.gd', 'r') as f:
    content = f.read()

replacement = """		var merc_class: String = merc_data.get("class_type", merc_data.get("class", "mage"))
		var comp_node = null

		var scene_path = "res://scenes/entities/companion/companion_" + merc_class.to_lower() + ".tscn"

		var CompanionScene = load(scene_path)
		if CompanionScene == null:
			if merc_class.to_lower() == "rogue":
				var RogueClass = load("res://scripts/entities/companion_rogue.gd")
				if RogueClass != null:
					comp_node = RogueClass.new()
			if comp_node == null:
				CompanionScene = load("res://scenes/entities/companion/companion.tscn")

		if CompanionScene != null and comp_node == null:
			comp_node = CompanionScene.instantiate()"""

original = """		var merc_class: String = merc_data.get("class_type", merc_data.get("class", "mage"))
		var comp_node = null

		var scene_path = "res://scenes/entities/companion/companion_" + merc_class.to_lower() + ".tscn"

		var CompanionScene = load(scene_path)
		if CompanionScene == null:
			CompanionScene = load("res://scenes/entities/companion/companion.tscn")
			if CompanionScene == null and merc_class.to_lower() == "rogue":
				# Try GDScript if scene doesn't exist
				var RogueClass = load("res://scripts/entities/companion_rogue.gd")
				if RogueClass != null:
					comp_node = RogueClass.new()

		if CompanionScene != null and comp_node == null:
			comp_node = CompanionScene.instantiate()"""

content = content.replace(original, replacement)

with open('scripts/arena/arena.gd', 'w') as f:
    f.write(content)
