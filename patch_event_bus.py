import re

with open('scripts/autoloads/event_bus.gd', 'r') as f:
    content = f.read()

content = re.sub(
    r'(signal ally_died\(ally: Node\)\n)',
    r'\1signal gold_changed(new_gold: int)\n',
    content
)

with open('scripts/autoloads/event_bus.gd', 'w') as f:
    f.write(content)
