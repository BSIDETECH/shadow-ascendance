with open('scripts/ui/modals/tavern_recruit_modal.gd', 'r') as f:
    content = f.read()

content = content.replace('''		"cost": 140
	{
		"id": "rogue_silas",''', '''		"cost": 140
	},
	{
		"id": "rogue_silas",''')

with open('scripts/ui/modals/tavern_recruit_modal.gd', 'w') as f:
    f.write(content)
