import re

with open("scripts/ui/gacha_screen.gd", "r") as f:
    content = f.read()

replacements = [
    (r'\{"id": "ex_mage_wrath", "rarity": "EX", "title": "🔥 CATACLISMO ELEMENTAL", "desc": "\[CHEAT\] A Maga dispara 3 bolas de fogo por ataque com dano dobrado \(\+100%\)!"\}', r'{"id": "ex_mage_wrath", "rarity": "EX", "title": "🔥 CATACLISMO ELEMENTAL", "desc": "[CHEAT] A Maga dispara 3 bolas de fogo por ataque com dano dobrado (+100%)!", "req_class": "mage"}'),
    (r'\{"id": "mage_multi", "rarity": "SR", "title": "Eco Arcano da Maga", "desc": "A Maga dispara \+1 Projétil por ataque"\}', r'{"id": "mage_multi", "rarity": "SR", "title": "Eco Arcano da Maga", "desc": "A Maga dispara +1 Projétil por ataque", "req_class": "mage"}'),
    (r'\{"id": "mage_haste", "rarity": "SR", "title": "Aceleração Astral", "desc": "\+40% Cadência de Feitiços da Maga"\}', r'{"id": "mage_haste", "rarity": "SR", "title": "Aceleração Astral", "desc": "+40% Cadência de Feitiços da Maga", "req_class": "mage"}'),
    (r'\{"id": "glacial_prison", "rarity": "SR", "title": "Prisão Glacial", "desc": "Inimigos atingidos pela Maga sofrem congelamento/enraizamento em área por 1\.5s\."\}', r'{"id": "glacial_prison", "rarity": "SR", "title": "Prisão Glacial", "desc": "Inimigos atingidos pela Maga sofrem congelamento/enraizamento em área por 1.5s.", "req_class": "mage"}'),
    (r'\{"id": "mage_dmg", "rarity": "SSR", "title": "Maestria Elemental", "desc": "\+60% Dano da Maga"\}', r'{"id": "mage_dmg", "rarity": "SSR", "title": "Maestria Elemental", "desc": "+60% Dano da Maga", "req_class": "mage"}'),
    (r'\{"id": "boss_meteor", "rarity": "EX", "title": "🌋 METEORO DA MAGA", "desc": "\[ROUBO DO CHEFE\] Maga conjura meteoros massivos que explodem o dobro da área com \+120% dano!"\}', r'{"id": "boss_meteor", "rarity": "EX", "title": "🌋 METEORO DA MAGA", "desc": "[ROUBO DO CHEFE] Maga conjura meteoros massivos que explodem o dobro da área com +120% dano!", "req_class": "mage"}')
]

for search, replace in replacements:
    content = re.sub(search, replace, content)

with open("scripts/ui/gacha_screen.gd", "w") as f:
    f.write(content)
