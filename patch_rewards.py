import re

# Ruined Fortress
with open('scripts/dungeon/ruined_fortress.gd', 'r') as f:
    rf_content = f.read()

rf_reward_logic = """
		var gm = get_tree().root.get_node_or_null("GameManager")
		if gm != null:
			var rank = gm.get("selected_quest_rank")
			if rank == null and gm.has_method("get_selected_quest_rank"):
				rank = gm.get_selected_quest_rank()

			var reward = 0
			if rank == "F": reward = 100
			elif rank == "E": reward = 350
			elif rank == "D": reward = 800

			if reward > 0 and gm.has_method("add_gold"):
				gm.add_gold(reward)

		if gm != null and gm.has_method("trigger_ending"):
"""

rf_content = rf_content.replace('		var gm = get_tree().root.get_node_or_null("GameManager")\n		if gm != null and gm.has_method("trigger_ending"):', rf_reward_logic)

with open('scripts/dungeon/ruined_fortress.gd', 'w') as f:
    f.write(rf_content)

# Arena
with open('scripts/arena/arena.gd', 'r') as f:
    arena_content = f.read()

arena_reward_logic = """func _on_boss_died(boss_name: String, _pos: Vector2) -> void:
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm != null:
		var rank = gm.get("selected_quest_rank")
		if rank == null and gm.has_method("get_selected_quest_rank"):
			rank = gm.get_selected_quest_rank()

		var reward = 0
		if rank == "F": reward = 100
		elif rank == "E": reward = 350
		elif rank == "D": reward = 800

		if reward > 0 and gm.has_method("add_gold"):
			gm.add_gold(reward)

	# Quando o Boss morre, pausa a ação e abre a tela de Roubo de Alma do Chefe!"""

arena_content = arena_content.replace('func _on_boss_died(boss_name: String, _pos: Vector2) -> void:\n\t# Quando o Boss morre, pausa a ação e abre a tela de Roubo de Alma do Chefe!', arena_reward_logic)

with open('scripts/arena/arena.gd', 'w') as f:
    f.write(arena_content)
