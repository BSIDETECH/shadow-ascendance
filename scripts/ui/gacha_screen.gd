class_name GachaScreen
extends CanvasLayer

signal card_chosen(card_data: Dictionary)

const RARITY_COLORS := {
	"R": Color(0.2, 0.6, 1.0),       # Celestial Blue
	"SR": Color(0.7, 0.2, 1.0),      # Royal Purple
	"SSR": Color(1.0, 0.8, 0.1),     # Radiant Gold
	"EX": Color(1.0, 0.15, 0.35)     # Monarch Crimson / Cheat
}

# Cartas de Despertar Inicial (Level 1 -> 2: O Cheat da Partida)
const STARTER_CHEAT_CARDS: Array[Dictionary] = [
	{"id": "ex_abyss", "rarity": "EX", "title": "👑 AUTORIDADE DO MONARCA", "desc": "[CHEAT] A cada 6 abates, detona uma Explosão Abissal devastadora em toda a tela!"},
	{"id": "ex_god", "rarity": "EX", "title": "⚡ DÁDIVA DO DESTINO", "desc": "[CHEAT] Dano DOBRADO (+100%) e Recarga do Dash reduzida em 60%!"},
	{"id": "ex_mage_wrath", "rarity": "EX", "title": "🔥 CATACLISMO ELEMENTAL", "desc": "[CHEAT] A Maga dispara 3 bolas de fogo por ataque com dano dobrado (+100%)!"},
	{"id": "ssr_vampire", "rarity": "SSR", "title": "🩸 CEIFADOR CARMESIM", "desc": "[ARQUÉTIPO] +4 de Vida roubada por monstro abatido e +40% cadência de corte!"},
	{"id": "ssr_storm", "rarity": "SSR", "title": "🌪️ TEMPESTADE DE LÂMINAS", "desc": "[ARQUÉTIPO] +75% Velocidade de Corte e +35% Velocidade de Movimento!"}
]

# Cartas Regulares Balanceadas por Raridade (Level 3+)
const POOL_R: Array[Dictionary] = [
	{"id": "dmg_up", "rarity": "R", "title": "Lâmina Voraz", "desc": "+25% Dano das Lâminas de Sombra"},
	{"id": "spd_up", "rarity": "R", "title": "Passos da Penumbra", "desc": "+20% Velocidade de Movimento"},
	{"id": "mag_up", "rarity": "R", "title": "Vórtice Espiritual", "desc": "+60% Raio de Atração de XP"},
	{"id": "hp_up", "rarity": "R", "title": "Vigor de Ferro", "desc": "+30 de Vida Máxima"}
]

const POOL_SR: Array[Dictionary] = [
	{"id": "mage_multi", "rarity": "SR", "title": "Eco Arcano da Maga", "desc": "A Maga dispara +1 Projétil por ataque"},
	{"id": "dash_cdr", "rarity": "SR", "title": "Reflexo Fantasma", "desc": "-35% Tempo de Recarga do Dash"},
	{"id": "heal_full", "rarity": "SR", "title": "Vitalidade Monarca", "desc": "+40 Vida Máxima e Cura Total"},
	{"id": "mage_haste", "rarity": "SR", "title": "Aceleração Astral", "desc": "+40% Cadência de Feitiços da Maga"}
]

const POOL_SSR: Array[Dictionary] = [
	{"id": "lifesteal", "rarity": "SSR", "title": "Dreno Sanguíneo", "desc": "+2.5 de Vida roubada por abate"},
	{"id": "atk_spd", "rarity": "SSR", "title": "Frenesi do Abismo", "desc": "+50% Velocidade de Corte de Sombras"},
	{"id": "mage_dmg", "rarity": "SSR", "title": "Maestria Elemental", "desc": "+60% Dano da Maga"}
]

const POOL_EX: Array[Dictionary] = [
	{"id": "ex_abyss", "rarity": "EX", "title": "👑 AUTORIDADE DO MONARCA", "desc": "[CHEAT] A cada 6 abates, uma Explosão Abissal devasta a tela!"},
	{"id": "ex_god", "rarity": "EX", "title": "⚡ DÁDIVA DO DESTINO", "desc": "[CHEAT] Dano DOBRADO (+100%) e Dash 60% mais rápido!"}
]

# Cartas Exclusivas de Roubo de Chefe
const BOSS_THEFT_CARDS: Array[Dictionary] = [
	{"id": "boss_demon_heart", "rarity": "EX", "title": "👹 CORAÇÃO TITÂNICO", "desc": "[ROUBO DO CHEFE] +100 Vida Máxima, Cura Total e emite pulsos de fogo devastadores a cada 3s!"},
	{"id": "boss_executioner", "rarity": "EX", "title": "💀 CARNICEIRO DO ABISMO", "desc": "[ROUBO DO CHEFE] Golpes têm 20% de chance de causar Dano Triplo fatal e +40% de dano base!"},
	{"id": "boss_meteor", "rarity": "EX", "title": "🌋 METEORO DA MAGA", "desc": "[ROUBO DO CHEFE] Maga conjura meteoros massivos que explodem o dobro da área com +120% dano!"}
]

@onready var cards_container: HBoxContainer = find_child("CardsContainer", true, false) as HBoxContainer
@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var subtitle_label: Label = find_child("SubtitleLabel", true, false) as Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func open_gacha(level: int) -> void:
	visible = true
	get_tree().paused = true

	# Clear previous cards
	for child in cards_container.get_children():
		child.queue_free()

	var offered_cards: Array[Dictionary] = []

	if level == 2:
		# PRIMEIRA RODADA: O Topzão Cheat Garantido!
		title_label.text = "✦ DESPERTAR DO CHEAT INICIAL ✦"
		subtitle_label.text = "★ RANK F CHEAT AWAKENING ★ Escolha a habilidade que definirá o estilo desta partida:"
		offered_cards = _pick_starter_cheat_cards()
	else:
		# RODADAS SEGUINTES: Gacha balanceado com raridades ponderadas
		title_label.text = "✦ BÊNÇÃO DA DEUSA ✦"
		subtitle_label.text = "Subiu para o Nível %d! Escolha uma bênção para fortalecer seu grupo:" % level
		offered_cards = _pick_weighted_cards()

	for card_data in offered_cards:
		_create_card_button(card_data)

func open_boss_theft(boss_name: String) -> void:
	visible = true
	get_tree().paused = true

	for child in cards_container.get_children():
		child.queue_free()

	title_label.text = "👑 ALMA DO CHEFE DEVORADA 👑"
	subtitle_label.text = "O %s tombou! Absorva sua essência e roube um poder ancestral supremo:" % boss_name

	var pool := BOSS_THEFT_CARDS.duplicate()
	pool.shuffle()
	for card_data in pool:
		_create_card_button(card_data)

func _pick_starter_cheat_cards() -> Array[Dictionary]:
	var pool := STARTER_CHEAT_CARDS.duplicate()
	pool.shuffle()
	return [pool[0], pool[1], pool[2]]

func _pick_weighted_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var used_ids: Array[String] = []

	for i in range(3):
		var card: Dictionary = _roll_single_card(used_ids)
		result.append(card)
		used_ids.append(card.id)

	return result

func _roll_single_card(exclude_ids: Array[String]) -> Dictionary:
	var roll := randf()
	var target_pool: Array[Dictionary]

	if roll < 0.65:
		target_pool = POOL_R
	elif roll < 0.93:
		target_pool = POOL_SR
	elif roll < 0.995:
		target_pool = POOL_SSR
	else:
		target_pool = POOL_EX

	var available: Array[Dictionary] = []
	for c in target_pool:
		if not exclude_ids.has(c.id):
			available.append(c)

	if available.is_empty():
		available = POOL_R

	available.shuffle()
	return available[0]

func _create_card_button(card: Dictionary) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(165, 205)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 10)

	var rarity_color: Color = RARITY_COLORS.get(card.rarity, Color.WHITE)

	var text_content := "\n[%s]\n\n%s\n\n%s" % [card.rarity, card.title, card.desc]
	btn.text = text_content
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.16, 0.95)
	style.border_color = rarity_color
	style.set_border_width_all(3 if card.rarity == "EX" else 2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", rarity_color)

	btn.mouse_entered.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.08)
	)
	btn.mouse_exited.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.08)
	)

	btn.pressed.connect(func():
		_on_card_selected(card)
	)

	cards_container.add_child(btn)

func _on_card_selected(card: Dictionary) -> void:
	card_chosen.emit(card)
	visible = false
	get_tree().paused = false
