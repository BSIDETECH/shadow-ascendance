import re

with open('scripts/autoloads/game_manager.gd', 'r') as f:
    content = f.read()

# Add player_gold variable
content = re.sub(
    r'(var is_transitioning: bool = false\n)',
    r'\1var player_gold: int = 0\n',
    content
)

# Add gold methods at the end of the file
methods = """
# --- Economy System ---

func add_gold(amount: int) -> void:
	player_gold += amount
	if EventBus.has_signal("gold_changed"):
		EventBus.gold_changed.emit(player_gold)

func spend_gold(amount: int) -> bool:
	if player_gold >= amount:
		player_gold -= amount
		if EventBus.has_signal("gold_changed"):
			EventBus.gold_changed.emit(player_gold)
		return true
	return false

func get_gold() -> int:
	return player_gold
"""

content += methods

with open('scripts/autoloads/game_manager.gd', 'w') as f:
    f.write(content)
