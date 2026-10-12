import re

def main():
    filepath = "scripts/ui/gacha_screen.gd"
    with open(filepath, "r") as f:
        content = f.read()

    # Add POOL_R
    r_cards = """	{"id": "hp_up", "rarity": "R", "title": "Vigor de Ferro", "desc": "+30 de Vida Máxima"},
	{"id": "vorpal_sword", "rarity": "R", "title": "Espada Vorpal", "desc": "Os próximos ataques corpo a corpo causam dano percentual adicional e aumentam o alcance de corte."},
	{"id": "alpha_strike", "rarity": "R", "title": "Golpe Alpha", "desc": "O Dash do jogador causa dano cortante aos inimigos atravessados e concede invulnerabilidade durante o deslocamento."},
	{"id": "wind_momentum", "rarity": "R", "title": "Vento Impetuoso", "desc": "Aumenta a velocidade de movimento e gera um escudo reflexivo temporário após acumular distância percorrida."},
	{"id": "spread_shot", "rarity": "R", "title": "Tiro Espalhado", "desc": "Seus disparos ou projéteis ricocheteiam no inimigo mais próximo."}"""
    content = re.sub(r'\{"id": "hp_up", "rarity": "R", "title": "Vigor de Ferro", "desc": "\+30 de Vida Máxima"\}', r_cards, content)

    # Add POOL_SR
    sr_cards = """	{"id": "mage_haste", "rarity": "SR", "title": "Aceleração Astral", "desc": "+40% Cadência de Feitiços da Maga"},
	{"id": "spin_attack", "rarity": "SR", "title": "Redemoinho", "desc": "A cada 8s, o jogador gira por 2s, causando dano de corte contínuo em área e ignorando desacelerações."},
	{"id": "glacial_prison", "rarity": "SR", "title": "Prisão Glacial", "desc": "Inimigos atingidos pela Maga sofrem congelamento/enraizamento em área por 1.5s."},
	{"id": "insatiable_hunger", "rarity": "SR", "title": "Fome Insaciável", "desc": "Quando com menos de 50% de vida, o jogador e os companheiros ganham +50% de velocidade de ataque e roubo de vida triplicado."},
	{"id": "solar_flare", "rarity": "SR", "title": "Pilar Solar", "desc": "Ataques de aliados marcam os inimigos; seu próximo golpe consome a marca para dano mágico extra em área."}"""
    content = re.sub(r'\{"id": "mage_haste", "rarity": "SR", "title": "Aceleração Astral", "desc": "\+40% Cadência de Feitiços da Maga"\}', sr_cards, content)

    # Add POOL_SSR
    ssr_cards = """	{"id": "mage_dmg", "rarity": "SSR", "title": "Maestria Elemental", "desc": "+60% Dano da Maga"},
	{"id": "cosmic_rupture", "rarity": "SSR", "title": "Ruptura Cósmica", "desc": "A cada 20 monstros abatidos, conjura um raio de luz concentrado atravessando o mapa na direção do cursor."},
	{"id": "void_feast", "rarity": "SSR", "title": "Banquete do Vazio", "desc": "Ao abater elites ou chefes, você ganha permanentemente +20 de Vida Máxima e +5% de tamanho/dano (acumula até 10 vezes)."},
	{"id": "noxian_guillotine", "rarity": "SSR", "title": "Guilhotina de Noxus", "desc": "Inimigos abaixo de 30% de vida sofrem execução instantânea. Se executados, causa uma explosão de medo e reinicia o efeito imediatamente."},
	{"id": "ancestral_resurrect", "rarity": "SSR", "title": "Ressurreição Ancestral", "desc": "Ao receber dano fatal, você não morre: congela em êxtase por 2s e revive com 50% de vida (1 uso por run)."}"""
    content = re.sub(r'\{"id": "mage_dmg", "rarity": "SSR", "title": "Maestria Elemental", "desc": "\+60% Dano da Maga"\}', ssr_cards, content)

    # Add STARTER_CHEAT_CARDS
    starter_cards = """	{"id": "ssr_storm", "rarity": "SSR", "title": "🌪️ TEMPESTADE DE LÂMINAS", "desc": "[ARQUÉTIPO] +75% Velocidade de Corte e +35% Velocidade de Movimento!"},
	{"id": "glyph_fury", "rarity": "EX", "title": "👑 Fúria dos Glifos", "desc": "Todo feitiço conjurado reseta 50% do tempo de recarga das habilidades dos companheiros."},
	{"id": "demigod_forge", "rarity": "EX", "title": "🔥 Forja do Semi-Deus", "desc": "Todas as cartas que você adquirir a partir deste momento vêm aprimoradas para uma raridade acima (R vira SR, SR vira SSR)."}"""
    content = re.sub(r'\{"id": "ssr_storm", "rarity": "SSR", "title": "🌪️ TEMPESTADE DE LÂMINAS", "desc": "\[ARQUÉTIPO\] \+75% Velocidade de Corte e \+35% Velocidade de Movimento!"\}', starter_cards, content)

    # Add POOL_EX
    ex_cards = """	{"id": "ex_god", "rarity": "EX", "title": "⚡ DÁDIVA DO DESTINO", "desc": "[CHEAT] Dano DOBRADO (+100%) e Dash 60% mais rápido!"},
	{"id": "glyph_fury", "rarity": "EX", "title": "👑 Fúria dos Glifos", "desc": "Todo feitiço conjurado reseta 50% do tempo de recarga das habilidades dos companheiros."},
	{"id": "demigod_forge", "rarity": "EX", "title": "🔥 Forja do Semi-Deus", "desc": "Todas as cartas que você adquirir a partir deste momento vêm aprimordas para uma raridade acima (R vira SR, SR vira SSR)."}"""
    content = re.sub(r'\{"id": "ex_god", "rarity": "EX", "title": "⚡ DÁDIVA DO DESTINO", "desc": "\[CHEAT\] Dano DOBRADO \(\+100%\) e Dash 60% mais rápido!"\}', ex_cards, content)

    # Add BOSS_THEFT_CARDS
    boss_cards = """	{"id": "boss_meteor", "rarity": "EX", "title": "🌋 METEORO DA MAGA", "desc": "[ROUBO DO CHEFE] Maga conjura meteoros massivos que explodem o dobro da área com +120% dano!"},
	{"id": "realm_of_death", "rarity": "EX", "title": "⚡ Reino da Morte", "desc": "[ROUBO DO CHEFE] Ao enfrentar um Chefe, drena 15% de todos os atributos dele e transfere para você durante o restante do confronto."}"""
    content = re.sub(r'\{"id": "boss_meteor", "rarity": "EX", "title": "🌋 METEORO DA MAGA", "desc": "\[ROUBO DO CHEFE\] Maga conjura meteoros massivos que explodem o dobro da área com \+120% dano!"\}', boss_cards, content)

    # Add global variable `demigod_forge_active`
    content = content.replace("extends CanvasLayer\n\n", "extends CanvasLayer\n\nvar demigod_forge_active: bool = false\n\n")

    # Change roll logic
    roll_logic = """func _roll_single_card(exclude_ids: Array[String]) -> Dictionary:
	var roll := randf()
	var target_pool: Array[Dictionary]

	if roll < 0.65:
		target_pool = POOL_SR if demigod_forge_active else POOL_R
	elif roll < 0.93:
		target_pool = POOL_SSR if demigod_forge_active else POOL_SR
	elif roll < 0.995:
		target_pool = POOL_EX if demigod_forge_active else POOL_SSR
	else:
		target_pool = POOL_EX"""
    content = re.sub(r'func _roll_single_card\(exclude_ids: Array\[String\]\) -> Dictionary:\n\tvar roll := randf\(\)\n\tvar target_pool: Array\[Dictionary\]\n\n\tif roll < 0\.65:\n\t\ttarget_pool = POOL_R\n\telif roll < 0\.93:\n\t\ttarget_pool = POOL_SR\n\telif roll < 0\.995:\n\t\ttarget_pool = POOL_SSR\n\telse:\n\t\ttarget_pool = POOL_EX', roll_logic, content)

    with open(filepath, "w") as f:
        f.write(content)
    print("Done patching gacha_screen.gd")

if __name__ == "__main__":
    main()
