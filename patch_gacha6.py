import re

with open("scripts/ui/gacha_screen.gd", "r") as f:
    content = f.read()

# _pick_starter_cheat_cards
# Original:
# func _pick_starter_cheat_cards() -> Array[Dictionary]:
# 	var pool := STARTER_CHEAT_CARDS.duplicate()
# 	pool.shuffle()
# 	return [pool[0], pool[1], pool[2]]

# New:
new_starter = """func _pick_starter_cheat_cards() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for c in STARTER_CHEAT_CARDS:
		if _is_card_valid(c):
			pool.append(c.duplicate())
	pool.shuffle()

	# Fallback just in case
	while pool.size() < 3:
		pool.append(POOL_R[0])

	return [pool[0], pool[1], pool[2]]"""

content = re.sub(
    r'func _pick_starter_cheat_cards\(\) -> Array\[Dictionary\]:\n\s*var pool := STARTER_CHEAT_CARDS\.duplicate\(\)\n\s*pool\.shuffle\(\)\n\s*return \[pool\[0\], pool\[1\], pool\[2\]\]',
    new_starter,
    content
)

# open_boss_theft
# Original:
#	var pool := BOSS_THEFT_CARDS.duplicate()
#	pool.shuffle()
#	for card_data in pool:
#		_create_card_button(card_data)

new_boss = """	var pool: Array[Dictionary] = []
	for c in BOSS_THEFT_CARDS:
		if _is_card_valid(c):
			pool.append(c.duplicate())
	pool.shuffle()
	for card_data in pool:
		_create_card_button(card_data)"""

content = re.sub(
    r'\s*var pool := BOSS_THEFT_CARDS\.duplicate\(\)\n\s*pool\.shuffle\(\)\n\s*for card_data in pool:\n\s*_create_card_button\(card_data\)',
    '\n' + new_boss,
    content
)

# _roll_single_card
# Original:
#	var available: Array[Dictionary] = []
#	for c in target_pool:
#		if not exclude_ids.has(c.id):
#			available.append(c)

new_roll = """	var available: Array[Dictionary] = []
	for c in target_pool:
		if not exclude_ids.has(c.id) and _is_card_valid(c):
			available.append(c)"""

content = re.sub(
    r'\s*var available: Array\[Dictionary\] = \[\]\n\s*for c in target_pool:\n\s*if not exclude_ids\.has\(c\.id\):\n\s*available\.append\(c\)',
    '\n' + new_roll,
    content
)

with open("scripts/ui/gacha_screen.gd", "w") as f:
    f.write(content)
