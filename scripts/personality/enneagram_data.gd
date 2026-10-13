class_name EnneagramData
extends Resource

## Data container and preset factory for Enneagram Personality Profiles (Types 1-9).

enum Type {
	NONE = 0,
	REFORMER = 1,       # Tipo 1: O Reformador / Perfeccionista
	HELPER = 2,         # Tipo 2: O Ajudante / Prestativo
	ACHIEVER = 3,       # Tipo 3: O Realizador / Triunfador
	INDIVIDUALIST = 4,  # Tipo 4: O Individualista / Romântico
	INVESTIGATOR = 5,   # Tipo 5: O Investigador / Observador
	LOYALIST = 6,       # Tipo 6: O Leal / Cético
	ENTHUSIAST = 7,     # Tipo 7: O Entusiasta / Otimista
	CHALLENGER = 8,     # Tipo 8: O Desafiador / Líder
	PEACEMAKER = 9,     # Tipo 9: O Pacificador / Mediador
}

# --- Core Identity ---
@export var enneagram_type: Type = Type.NONE
@export var type_name: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

# --- Base Obedience Tendencies [0.0 .. 1.0] ---
@export_range(0.0, 1.0) var base_attack_obedience: float = 0.70
@export_range(0.0, 1.0) var base_retreat_obedience: float = 0.70
@export_range(0.0, 1.0) var base_help_obedience: float = 0.70

# --- Psychological Tuning ---
@export var stress_sensitivity: float = 1.0
@export var calm_recovery_rate: float = 4.0
@export var swarm_panic_threshold: int = 6
@export var isolation_sensitivity: float = 1.0

# --- Dialogue Database (PT-BR) ---
# Format: "[ORDER]_[STATE]_[OUTCOME]"
@export var dialogue_lines: Dictionary = {}

func get_dialogue_line(order_str: String, state_str: String, outcome_str: String) -> String:
	var key := "%s_%s_%s" % [order_str.to_upper(), state_str.to_upper(), outcome_str.to_upper()]
	if dialogue_lines.has(key):
		return dialogue_lines[key]
	var fallback_key := "%s_HEALTHY_%s" % [order_str.to_upper(), outcome_str.to_upper()]
	if dialogue_lines.has(fallback_key):
		return dialogue_lines[fallback_key]
	match outcome_str.to_upper():
		"OBEY":
			return "Ordem recebida. Executando!"
		"HESITATE":
			return "Espere... isso é seguro?! Vou tentar..."
		"REFUSE":
			return "Eu recuso essa ordem!"
		_:
			return "Entendido."

func get_base_obedience(order_type: int) -> float:
	match order_type:
		1: # ATTACK
			return base_attack_obedience
		2: # RETREAT
			return base_retreat_obedience
		3: # HELP
			return base_help_obedience
		_:
			return 0.70

static func create_type(type_id: int) -> EnneagramData:
	return create_preset(type_id as Type)

static func create_preset(p_type: Type) -> EnneagramData:
	var d: EnneagramData = load("res://scripts/personality/enneagram_data.gd").new()
	d.enneagram_type = p_type

	match p_type:
		Type.REFORMER:
			d.type_name = "O Reformador"
			d.title = "Perfeccionista Tático"
			d.description = "Valoriza integridade, ordem e execução metodológica. Despreza caos e ordens suicidas."
			d.base_attack_obedience = 0.80
			d.base_retreat_obedience = 0.75
			d.base_help_obedience = 0.85
			d.stress_sensitivity = 1.1
			d.calm_recovery_rate = 4.0
			d.swarm_panic_threshold = 6
			d.dialogue_lines = {
				"ATTACK_HEALTHY_OBEY": "Executando avanço tático com precisão.",
				"ATTACK_HEALTHY_HESITATE": "A formação está instável... mas atacarei.",
				"ATTACK_HEALTHY_REFUSE": "Esse ataque viola a ordem tática! Recuse.",
				"ATTACK_STRESSED_OBEY": "Avanço realizado, mas há brechas no flanco!",
				"ATTACK_STRESSED_HESITATE": "Essa ordem é falha... vou precisar de cobertura!",
				"ATTACK_STRESSED_REFUSE": "Não vou atirar nossa linha ao caos absoluto!",
				"ATTACK_COLLAPSED_OBEY": "Atacando às cegas... que os deuses nos guardem!",
				"ATTACK_COLLAPSED_HESITATE": "Tudo está fora de controle... onde ataco?!",
				"ATTACK_COLLAPSED_REFUSE": "Erro crasso! Não participarei desse suicídio desordenado!",

				"RETREAT_HEALTHY_OBEY": "Recuo ordenado iniciado. Mantenham os flancos cobertos.",
				"RETREAT_HEALTHY_HESITATE": "Recuar agora parece prematuro, mas cumpro a ordem.",
				"RETREAT_HEALTHY_REFUSE": "Abandonar esta posição estratégica seria um erro fatal!",
				"RETREAT_STRESSED_OBEY": "Recuando em linha defensiva, sem pânico!",
				"RETREAT_STRESSED_HESITATE": "Recuar agora é desleixado... mas se você insiste...",
				"RETREAT_STRESSED_REFUSE": "Um recuo desorganizado nos massacrará! Mantenham a linha!",
				"RETREAT_COLLAPSED_OBEY": "Caindo para trás antes que a formação se dissolva!",
				"RETREAT_COLLAPSED_HESITATE": "Para onde recuar?! As rotas estão corrompidas!",
				"RETREAT_COLLAPSED_REFUSE": "Eu prefiro tombar em formação a fugir como gado em pânico!",

				"HELP_HEALTHY_OBEY": "Cumprindo protocolo de suporte. Mantenha a guarda alta!",
				"HELP_HEALTHY_HESITATE": "Intervenção requer quebra de postura... avançando com cautela.",
				"HELP_HEALTHY_REFUSE": "Minha posição atual é vital para a sobrevivência do grupo!",
				"HELP_STRESSED_OBEY": "Socorro a caminho! Não ceda terreno!",
				"HELP_STRESSED_HESITATE": "Socorro fora dos parâmetros ideais... intervindo!",
				"HELP_STRESSED_REFUSE": "Não posso cobrir seus erros imprudentes a esse custo!",
				"HELP_COLLAPSED_OBEY": "Tentando resgate de emergência!",
				"HELP_COLLAPSED_HESITATE": "Quem eu devo salvar primeiro?! Há erros demais!",
				"HELP_COLLAPSED_REFUSE": "Não há salvação em meio a essa ruína completa!"
			}

		Type.HELPER:
			d.type_name = "O Ajudante"
			d.title = "Prestativo Devotado"
			d.description = "Empático e leal. Coloca a vida dos aliados acima de si mesmo. Recusa recuar se alguém estiver em perigo."
			d.base_attack_obedience = 0.65
			d.base_retreat_obedience = 0.50
			d.base_help_obedience = 0.95
			d.stress_sensitivity = 1.3
			d.calm_recovery_rate = 3.5
			d.swarm_panic_threshold = 5
			d.dialogue_lines = {
				"ATTACK_HEALTHY_OBEY": "Vou abrir caminho para você passar!",
				"ATTACK_HEALTHY_HESITATE": "Posso atacar, mas... você estará seguro sem mim?",
				"ATTACK_HEALTHY_REFUSE": "Prefiro ficar ao seu lado garantindo sua vida!",
				"ATTACK_STRESSED_OBEY": "Afastando os monstros de você!",
				"ATTACK_STRESSED_HESITATE": "Eu deveria atacar...? Mas você está sangrando!",
				"ATTACK_STRESSED_REFUSE": "Não posso atacar agora, você precisa de mim aqui!",
				"ATTACK_COLLAPSED_OBEY": "Golpeando qualquer coisa que ameace meus amigos!",
				"ATTACK_COLLAPSED_HESITATE": "Não sei se bato neles ou se cuido de você...",
				"ATTACK_COLLAPSED_REFUSE": "Não vou me afastar de você por nada no mundo!",

				"RETREAT_HEALTHY_OBEY": "Vamos juntos, não solte a minha mão!",
				"RETREAT_HEALTHY_HESITATE": "Recuar? Mas você está bem? Tem certeza?",
				"RETREAT_HEALTHY_REFUSE": "Não posso recuar enquanto houver feridos para trás!",
				"RETREAT_STRESSED_OBEY": "Correndo ao seu lado, proteja-se!",
				"RETREAT_STRESSED_HESITATE": "Recuar?! Mas quem vai proteger você se eu correr?!",
				"RETREAT_STRESSED_REFUSE": "Eu jamais vou recuar enquanto você estiver em perigo! Jamais!",
				"RETREAT_COLLAPSED_OBEY": "Fujam vocês primeiro, eu seguro o quanto der!",
				"RETREAT_COLLAPSED_HESITATE": "Não posso te deixar para trás... por favor venha comigo!",
				"RETREAT_COLLAPSED_REFUSE": "Pode ordenar o que quiser! Eu morro aqui com você!",

				"HELP_HEALTHY_OBEY": "Já estou indo! Ninguém toca em você!",
				"HELP_HEALTHY_HESITATE": "Chegando o mais rápido que minhas pernas aguentam!",
				"HELP_HEALTHY_REFUSE": "Estou bloqueado, mas não desista!",
				"HELP_STRESSED_OBEY": "Aguente firme! Eu estou aqui!",
				"HELP_STRESSED_HESITATE": "Estou correndo, por favor, continue respirando!",
				"HELP_STRESSED_REFUSE": "Perdão... estou cercado, não consigo alcançar você!",
				"HELP_COLLAPSED_OBEY": "Eu dou minha vida pela sua! Tome cobertura atrás de mim!",
				"HELP_COLLAPSED_HESITATE": "Não morra! Por favor, eu imploro, não morra!",
				"HELP_COLLAPSED_REFUSE": "Eu falhei em te proteger... quebrei minha promessa..."
			}

		Type.ACHIEVER:
			d.type_name = "O Realizador"
			d.title = "Triunfador Competitivo"
			d.description = "Ambicioso e focado em resultados. Quer aniquilar o chefe e odeia parecer fraco ou recuar."
			d.base_attack_obedience = 0.90
			d.base_retreat_obedience = 0.40
			d.base_help_obedience = 0.70
			d.stress_sensitivity = 1.0
			d.calm_recovery_rate = 4.5
			d.swarm_panic_threshold = 7
			d.dialogue_lines = {
				"ATTACK_HEALTHY_OBEY": "Alvo travado. Observe como um profissional faz.",
				"ATTACK_HEALTHY_HESITATE": "Esse ângulo é medíocre, mas vou finalizar a presa.",
				"ATTACK_HEALTHY_REFUSE": "Alvo de baixo valor. Vou mirar no chefe!",
				"ATTACK_STRESSED_OBEY": "Demorou para dar a ordem... vou liquidar todos de uma vez!",
				"ATTACK_STRESSED_HESITATE": "Não me dê ordens óbvias! Já estou mirando no líder!",
				"ATTACK_STRESSED_REFUSE": "Chega de ordens lentas! Eu vou matar esse chefe sozinho!",
				"ATTACK_COLLAPSED_OBEY": "Massacrando a todos para provar meu valor!",
				"ATTACK_COLLAPSED_HESITATE": "Minha glória está escorrendo... preciso matar mais rápido!",
				"ATTACK_COLLAPSED_REFUSE": "Eu não serei humilhado por monstros inferiores!",

				"RETREAT_HEALTHY_OBEY": "Recuo estratégico para reorganizar o contra-ataque.",
				"RETREAT_HEALTHY_HESITATE": "Recuar agora manchará nosso desempenho... que seja.",
				"RETREAT_HEALTHY_REFUSE": "Estamos a segundos da vitória! Recuar é inadmissível!",
				"RETREAT_STRESSED_OBEY": "Reposicionando para o bote decisivo.",
				"RETREAT_STRESSED_HESITATE": "Recuar? Isso vai manchar meu histórico... que droga!",
				"RETREAT_STRESSED_REFUSE": "Recuar?! Covardia não faz parte da minha lenda! Eu não fujo!",
				"RETREAT_COLLAPSED_OBEY": "Uma mancha no meu nome... mas sobrevivo para triunfar.",
				"RETREAT_COLLAPSED_HESITATE": "Fugir agora destrói tudo que construí nesta masmorra!",
				"RETREAT_COLLAPSED_REFUSE": "Prefiro cair lutando no topo do que rastejar como derrotado!",

				"HELP_HEALTHY_OBEY": "Intervenção rápida! Mantendo o grupo em alta performance.",
				"HELP_HEALTHY_HESITATE": "Cobrir você custará meu tempo de abate... a caminho.",
				"HELP_HEALTHY_REFUSE": "Resolva sua parte, eu garanto o objetivo principal!",
				"HELP_STRESSED_OBEY": "Não me atrase... já estou cobrindo suas costas!",
				"HELP_STRESSED_HESITATE": "Você está puxando nosso rendimento para baixo! Chegando!",
				"HELP_STRESSED_REFUSE": "Não perca tempo choramingando, derrote o alvo você mesmo!",
				"HELP_COLLAPSED_OBEY": "Salvando a equipe antes do desastre total!",
				"HELP_COLLAPSED_HESITATE": "Por que você tem que cair justo agora?!",
				"HELP_COLLAPSED_REFUSE": "Carregar você está arruinando minha vitória!"
			}

		Type.INDIVIDUALIST:
			d.type_name = "O Individualista"
			d.title = "Alma Solitária"
			d.description = "Profundo, sensível e dramático. Odeia ordens repetitivas ou ser comandado como um peão comum."
			d.base_attack_obedience = 0.60
			d.base_retreat_obedience = 0.70
			d.base_help_obedience = 0.65
			d.stress_sensitivity = 1.2
			d.calm_recovery_rate = 3.5
			d.swarm_panic_threshold = 5
			d.dialogue_lines = {
				"ATTACK_HEALTHY_OBEY": "A lâmina dança na sombra do destino.",
				"ATTACK_HEALTHY_HESITATE": "Essa cadência é tão comum... mas farei ao meu modo.",
				"ATTACK_HEALTHY_REFUSE": "Não sou uma engrenagem na sua máquina de guerra.",
				"ATTACK_STRESSED_OBEY": "Ferindo as sombras antes que elas me consumam.",
				"ATTACK_STRESSED_HESITATE": "Você sempre comanda como se eu fosse descartável...",
				"ATTACK_STRESSED_REFUSE": "Não serei o peão do seu massacre tolo!",
				"ATTACK_COLLAPSED_OBEY": "Um golpe final em meio à melancolia do fim.",
				"ATTACK_COLLAPSED_HESITATE": "Que sentido faz este golpe em meio ao vazio?",
				"ATTACK_COLLAPSED_REFUSE": "Deixe que as trevas levem tudo. Minha arte acabou.",

				"RETREAT_HEALTHY_OBEY": "Afasto-me das cinzas antes que a beleza se perca.",
				"RETREAT_HEALTHY_HESITATE": "Recuar... para prolongar este fardo sombrio?",
				"RETREAT_HEALTHY_REFUSE": "Aqui jaz o meu lugar no palco. Não darei um passo atrás.",
				"RETREAT_STRESSED_OBEY": "Buscando o refúgio das sombras solitárias.",
				"RETREAT_STRESSED_HESITATE": "Fugir ou perecer... ambos têm o mesmo sabor amargo.",
				"RETREAT_STRESSED_REFUSE": "Se o abismo me chama, deixarei que ele me leve.",
				"RETREAT_COLLAPSED_OBEY": "Arrastando minha alma para longe do clamor.",
				"RETREAT_COLLAPSED_HESITATE": "Minhas pernas pesam como memórias esquecidas...",
				"RETREAT_COLLAPSED_REFUSE": "Não fujo mais da tragédia que me pertence.",

				"HELP_HEALTHY_OBEY": "Não deixarei sua luz se apagar na escuridão.",
				"HELP_HEALTHY_HESITATE": "Sua dor me atrai... mas quem compreende a minha?",
				"HELP_HEALTHY_REFUSE": "Nossos caminhos de dor devem ser trilhados sós.",
				"HELP_STRESSED_OBEY": "Intervenho, pois conheço o desespero do abandono.",
				"HELP_STRESSED_HESITATE": "Você só nota minha presença quando precisa de salvação...",
				"HELP_STRESSED_REFUSE": "Ninguém me salvou quando minha alma ruiu.",
				"HELP_COLLAPSED_OBEY": "Compartilhando os últimos suspiros com você.",
				"HELP_COLLAPSED_HESITATE": "Socorro...? Tudo é efêmero e decadente...",
				"HELP_COLLAPSED_REFUSE": "Estamos todos sozinhos neste túmulo."
			}

		Type.INVESTIGATOR:
			d.type_name = "O Investigador"
			d.title = "Estrategista Analítico"
			d.description = "Observador racional que prefere manter distância. Entra em colapso e hesita quando cercado por enxames."
			d.base_attack_obedience = 0.70
			d.base_retreat_obedience = 0.85
			d.base_help_obedience = 0.60
			d.stress_sensitivity = 1.4
			d.calm_recovery_rate = 5.0
			d.swarm_panic_threshold = 5
			d.dialogue_lines = {
				"ATTACK_HEALTHY_OBEY": "Calculando trajetórias. Disparo em três, dois, um.",
				"ATTACK_HEALTHY_HESITATE": "Ângulo de tiro desfavorável. Recalibrando parâmetros...",
				"ATTACK_HEALTHY_REFUSE": "Probabilidade de sucesso inferior a 15%. Disparo abortado.",
				"ATTACK_STRESSED_OBEY": "Fogo disparado, mas os vetores estão instáveis!",
				"ATTACK_STRESSED_HESITATE": "Densidade de inimigos alta demais... calculando vetor de escape...",
				"ATTACK_STRESSED_REFUSE": "Sobrecarga de alvos no campo visual! Impossível calcular!",
				"ATTACK_COLLAPSED_OBEY": "Disparo errático executado sob coação!",
				"ATTACK_COLLAPSED_HESITATE": "Variáveis caóticas demais... travamento de mira!",
				"ATTACK_COLLAPSED_REFUSE": "Variáveis caóticas demais! Meus circuitos de decisão travaram!",

				"RETREAT_HEALTHY_OBEY": "Reposicionamento defensivo ideal. Ampliando campo de visão.",
				"RETREAT_HEALTHY_HESITATE": "Distância atual ainda é teoricamente sustentável, mas recuando.",
				"RETREAT_HEALTHY_REFUSE": "Mantenho este ponto de observação. Visada perfeita.",
				"RETREAT_STRESSED_OBEY": "Recuando antes que os recursos se esgotem por completo.",
				"RETREAT_STRESSED_HESITATE": "Calculando melhor rota... três saídas bloqueadas!",
				"RETREAT_STRESSED_REFUSE": "Cercado em 360 graus... rota de fuga matematicamente inexistente!",
				"RETREAT_COLLAPSED_OBEY": "Evacuação cega de emergência!",
				"RETREAT_COLLAPSED_HESITATE": "Margem de erro crítica... onde piso?!",
				"RETREAT_COLLAPSED_REFUSE": "Paralisia analítica total! Não consigo calcular o passo!",

				"HELP_HEALTHY_OBEY": "Aplicando fogo de supressão nas coordenadas da ameaça.",
				"HELP_HEALTHY_HESITATE": "Aproximar-me reduz minha eficiência balística... avançando.",
				"HELP_HEALTHY_REFUSE": "Apoio corpo a corpo contradiz minha função de longo alcance.",
				"HELP_STRESSED_OBEY": "Disparo de resgate emergencial!",
				"HELP_STRESSED_HESITATE": "Aproximar-me aumenta meu risco de colapso em 78%...",
				"HELP_STRESSED_REFUSE": "Sem munição e sem lógica! Não posso intervir sem morrer!",
				"HELP_COLLAPSED_OBEY": "Tentando conter a maré antes do fim lógico!",
				"HELP_COLLAPSED_HESITATE": "Equações de suporte entrando em colapso...",
				"HELP_COLLAPSED_REFUSE": "Sua morte é uma variável que não posso mais evitar."
			}

		Type.LOYALIST:
			d.type_name = "O Leal"
			d.title = "Sentinela Fiel"
			d.description = "Protetor vigilante e cauteloso. Tem pavor de ser abandonado ou isolado do líder."
			d.base_attack_obedience = 0.75
			d.base_retreat_obedience = 0.90
			d.base_help_obedience = 0.85
			d.stress_sensitivity = 1.3
			d.calm_recovery_rate = 3.5
			d.swarm_panic_threshold = 6
			d.dialogue_lines = {
				"ATTACK_HEALTHY_OBEY": "Cobrindo o avanço! Olhos abertos para emboscadas!",
				"ATTACK_HEALTHY_HESITATE": "Avançar agora? Você tem certeza de que a retaguarda está limpa?",
				"ATTACK_HEALTHY_REFUSE": "Isso parece uma emboscada óbvia! Não podemos entrar aí!",
				"ATTACK_STRESSED_OBEY": "Avançando, mas fiquem juntos! Não se separem!",
				"ATTACK_STRESSED_HESITATE": "Tem certeza disso?! Parece uma armadilha evidente!",
				"ATTACK_STRESSED_REFUSE": "Você está nos levando para o matadouro! Eu não vou entrar aí!",
				"ATTACK_COLLAPSED_OBEY": "Golpeando no escuro... estamos cercados?!",
				"ATTACK_COLLAPSED_HESITATE": "Não vejo meus companheiros... onde vocês estão?!",
				"ATTACK_COLLAPSED_REFUSE": "Traição ou loucura?! Eu não vou morrer nessa armadilha!",

				"RETREAT_HEALTHY_OBEY": "Sim, recuar agora! Formação defensiva imediata!",
				"RETREAT_HEALTHY_HESITATE": "Recuando! Mas vigiem a retaguarda, eles vão nos flanquear!",
				"RETREAT_HEALTHY_REFUSE": "Se corrermos agora, seremos estraçalhados pelas costas!",
				"RETREAT_STRESSED_OBEY": "Todos juntos, recuar! Ninguém solte a linha!",
				"RETREAT_STRESSED_HESITATE": "Recuando! Mas tem monstros atrás daquela coluna!",
				"RETREAT_STRESSED_REFUSE": "Eles estão por toda parte! Não temos para onde correr!",
				"RETREAT_COLLAPSED_OBEY": "Fugindo com o grupo... por favor, não me deixe para trás!",
				"RETREAT_COLLAPSED_HESITATE": "Para onde fugir?! Fomos encurralados!",
				"RETREAT_COLLAPSED_REFUSE": "Acabou... não há saída... estamos condenados!",

				"HELP_HEALTHY_OBEY": "Protegendo o flanco aliado! Ninguém fica para trás!",
				"HELP_HEALTHY_HESITATE": "Estou indo, mas quem vai cobrir a nossa retaguarda?!",
				"HELP_HEALTHY_REFUSE": "Não posso abrir mão desta barreira sem condenar a todos!",
				"HELP_STRESSED_OBEY": "Segure a guarda! Não vou deixar você cair!",
				"HELP_STRESSED_HESITATE": "Estou correndo, mas estamos nos expondo demais!",
				"HELP_STRESSED_REFUSE": "Estamos todos condenados se nos separarmos agora!",
				"HELP_COLLAPSED_OBEY": "Resgate desesperado! Fiquem comigo!",
				"HELP_COLLAPSED_HESITATE": "Socorro! Alguém me ajude a salvar o líder!",
				"HELP_COLLAPSED_REFUSE": "Nós fomos abandonados... ninguém virá nos salvar!"
			}

		Type.ENTHUSIAST:
			d.type_name = "O Entusiasta"
			d.title = "Vanguarda Impulsiva"
			d.description = "Ágil, alegre e impetuoso. Ama a adrenalina do combate, mas odeia ficar preso ou ferido."
			d.base_attack_obedience = 0.85
			d.base_retreat_obedience = 0.60
			d.base_help_obedience = 0.70
			d.stress_sensitivity = 0.9
			d.calm_recovery_rate = 4.5
			d.swarm_panic_threshold = 7
			d.dialogue_lines = {
				"ATTACK_HEALTHY_OBEY": "Hora da festa! Deixa que eu mostro como se faz barulho!",
				"ATTACK_HEALTHY_HESITATE": "Só atacar? Não tem nenhum truque mais divertido?!",
				"ATTACK_HEALTHY_REFUSE": "Esse plano é monótono demais. Vou flanquear pelo outro lado!",
				"ATTACK_STRESSED_OBEY": "Explodindo o caminho! Sai da frente!",
				"ATTACK_STRESSED_HESITATE": "Essa luta está ficando pesada... mas lá vou eu!",
				"ATTACK_STRESSED_REFUSE": "Chega dessa carnificina sufocante! Eu preciso de ar!",
				"ATTACK_COLLAPSED_OBEY": "Golpeando tudo para abrir espaço!",
				"ATTACK_COLLAPSED_HESITATE": "Socorro, tá doendo demais! Onde eu bato?!",
				"ATTACK_COLLAPSED_REFUSE": "Cansei dessa masmorra de pesadelo! Me tirem daqui!",

				"RETREAT_HEALTHY_OBEY": "Fuga tática com estilo! Ninguém me pega!",
				"RETREAT_HEALTHY_HESITATE": "Recuar já? A diversão mal começou!",
				"RETREAT_HEALTHY_REFUSE": "Fugir agora? Nem pensar, olha o combo que preparei!",
				"RETREAT_STRESSED_OBEY": "Correndo em zigue-zague! Desviando de tudo!",
				"RETREAT_STRESSED_HESITATE": "Tá bom, tá bom, recuando antes que me acertem!",
				"RETREAT_STRESSED_REFUSE": "Corram por suas vidas! Isso aqui virou um inferno!",
				"RETREAT_COLLAPSED_OBEY": "Fugindo o mais rápido possível! Tchau!",
				"RETREAT_COLLAPSED_HESITATE": "Não consigo correr com essas feridas sangrando!",
				"RETREAT_COLLAPSED_REFUSE": "Cada um por si agora! Eu não quero morrer aqui!",

				"HELP_HEALTHY_OBEY": "Cavaleiro do resgate chegando em alta velocidade!",
				"HELP_HEALTHY_HESITATE": "Aguenta aí, estou desviando de uns projéteis antes!",
				"HELP_HEALTHY_REFUSE": "Tenta rolar para o lado, estou ocupado fazendo manobras!",
				"HELP_STRESSED_OBEY": "Chegando no pulo! Segura a onda!",
				"HELP_STRESSED_HESITATE": "Uou, quase arrancaram minha cabeça! Já estou indo!",
				"HELP_STRESSED_REFUSE": "Se eu entrar aí, nós dois seremos triturados!",
				"HELP_COLLAPSED_OBEY": "Tentativa kamikaze de resgate!",
				"HELP_COLLAPSED_HESITATE": "Não consigo atravessar esses espinhos!",
				"HELP_COLLAPSED_REFUSE": "Eu não aguento mais dor! Salve-se quem puder!"
			}

		Type.CHALLENGER:
			d.type_name = "O Desafiador"
			d.title = "Titã Indomável"
			d.description = "Líder natural, destemido e furioso. Recusa covardia e recuos diante de inimigos que ainda respiram."
			d.base_attack_obedience = 0.95
			d.base_retreat_obedience = 0.20
			d.base_help_obedience = 0.85
			d.stress_sensitivity = 0.8
			d.calm_recovery_rate = 4.0
			d.swarm_panic_threshold = 10
			d.dialogue_lines = {
				"ATTACK_HEALTHY_OBEY": "Esmagar e avançar! Nenhum verme ficará de pé!",
				"ATTACK_HEALTHY_HESITATE": "Não preciso de ordem para fazer picadinho desses monstros!",
				"ATTACK_HEALTHY_REFUSE": "Não me mande cutucar fraquezas. Eu quebro as defesas deles no meio!",
				"ATTACK_STRESSED_OBEY": "Sangue por sangue! Venham todos de uma vez!",
				"ATTACK_STRESSED_HESITATE": "Eu decido quem morre primeiro!",
				"ATTACK_STRESSED_REFUSE": "Cale a boca! Eu vou arrancar a cabeça de todos eles sozinho!",
				"ATTACK_COLLAPSED_OBEY": "FÚRIA TOTAL! DESPEDAÇAR!",
				"ATTACK_COLLAPSED_HESITATE": "VOU MATAR ATÉ MEU CORPO ARREBENTAR!",
				"ATTACK_COLLAPSED_REFUSE": "EU NÃO RECEBO ORDENS DE NINGUÉM! MORRAM!",

				"RETREAT_HEALTHY_OBEY": "Só para reposicionar as armas. Mas eu volto para cobrar!",
				"RETREAT_HEALTHY_HESITATE": "Recuar?! Olhe nos olhos desses desgraçados, eles vão sangrar!",
				"RETREAT_HEALTHY_REFUSE": "Eu não dou as costas para lixo como esse! Lute ou saia do caminho!",
				"RETREAT_STRESSED_OBEY": "Vou dar dez passos para trás. No décimo primeiro, eles caem!",
				"RETREAT_STRESSED_HESITATE": "Não ouse me chamar de covarde! Não estou fugindo!",
				"RETREAT_STRESSED_REFUSE": "Eu nunca recuo! Venham me buscar no meio dos cadáveres!",
				"RETREAT_COLLAPSED_OBEY": "Vou quebrar o cerco por trás antes que me engulam!",
				"RETREAT_COLLAPSED_HESITATE": "Recuar de joelhos?! NUNCA!",
				"RETREAT_COLLAPSED_REFUSE": "EU NÃO ME CURVO! PODEM VIR TODOS!",

				"HELP_HEALTHY_OBEY": "Tirem as mãos sujas do meu aliado! O próximo é meu!",
				"HELP_HEALTHY_HESITATE": "Aguente o tranco! Não seja um frouxo enquanto eu chego!",
				"HELP_HEALTHY_REFUSE": "Levante e lute você mesmo! Eu tenho uma guerra para vencer!",
				"HELP_STRESSED_OBEY": "Ninguém encosta na minha matilha! ESMAGAR!",
				"HELP_STRESSED_HESITATE": "Estou quebrando os crânios no caminho para te alcançar!",
				"HELP_STRESSED_REFUSE": "Pare de chorar no chão e crave sua espada neles!",
				"HELP_COLLAPSED_OBEY": "EU CARREGO TODOS VOCÊS NAS COSTAS SE FOR PRECISO!",
				"HELP_COLLAPSED_HESITATE": "NÃO OUSE MORRER ANTES DE EU TERMINAR AQUI!",
				"HELP_COLLAPSED_REFUSE": "LUTEM ATÉ O FIM OU MORRAM DE VEZ!"
			}

		Type.PEACEMAKER:
			d.type_name = "O Pacificador"
			d.title = "Baluarte Sereno"
			d.description = "Sereno, paciente e obstinado. Resistente a ordens frenéticas ou ordens dadas com desespero."
			d.base_attack_obedience = 0.55
			d.base_retreat_obedience = 0.85
			d.base_help_obedience = 0.80
			d.stress_sensitivity = 0.9
			d.calm_recovery_rate = 5.0
			d.swarm_panic_threshold = 6
			d.dialogue_lines = {
				"ATTACK_HEALTHY_OBEY": "Com calma e firmeza... avançando sem pressa.",
				"ATTACK_HEALTHY_HESITATE": "Tanto barulho e violência... tem mesmo que ser agora?",
				"ATTACK_HEALTHY_REFUSE": "Não há necessidade de provocar mais sangue neste momento.",
				"ATTACK_STRESSED_OBEY": "Avançando para que essa confusão termine logo.",
				"ATTACK_STRESSED_HESITATE": "Muita correria não leva a nada... farei no meu tempo.",
				"ATTACK_STRESSED_REFUSE": "Não vou me desgastar com essa loucura desenfreada.",
				"ATTACK_COLLAPSED_OBEY": "Se é o único jeito de termos silêncio...",
				"ATTACK_COLLAPSED_HESITATE": "Meus braços pesam... não consigo me apressar...",
				"ATTACK_COLLAPSED_REFUSE": "Parem todos de gritar... não vou dar mais nenhum golpe.",

				"RETREAT_HEALTHY_OBEY": "Excelente ideia. Vamos respirar e encontrar um lugar seguro.",
				"RETREAT_HEALTHY_HESITATE": "Devagar... correria só atrai mais problemas.",
				"RETREAT_HEALTHY_REFUSE": "Este lugar está tranquilo o bastante. Não precisamos correr.",
				"RETREAT_STRESSED_OBEY": "Afastando-se do tumulto com passos firmes.",
				"RETREAT_STRESSED_HESITATE": "Pare de me puxar, eu sei andar sem tropeçar.",
				"RETREAT_STRESSED_REFUSE": "Minhas pernas pesam demais... façam o que quiserem.",
				"RETREAT_COLLAPSED_OBEY": "Procurando um canto escuro para descansar...",
				"RETREAT_COLLAPSED_HESITATE": "Estou tão exausto deste caos sem fim...",
				"RETREAT_COLLAPSED_REFUSE": "Não dou mais um passo. Deixem-me em paz.",

				"HELP_HEALTHY_OBEY": "Fique calmo. Já estou trazendo estabilidade para você.",
				"HELP_HEALTHY_HESITATE": "Respire fundo... já estou a caminho, sem afobação.",
				"HELP_HEALTHY_REFUSE": "Você consegue se recompor sozinho se parar de entrar em pânico.",
				"HELP_STRESSED_OBEY": "Apoiando o companheiro, respirem juntos.",
				"HELP_STRESSED_HESITATE": "Não precisa berrar tanto, eu já te ouvi...",
				"HELP_STRESSED_REFUSE": "Eu mal consigo me manter de pé... desculpe...",
				"HELP_COLLAPSED_OBEY": "Dividindo o peso do mundo com você...",
				"HELP_COLLAPSED_HESITATE": "Tudo está tão pesado...",
				"HELP_COLLAPSED_REFUSE": "A paz foi destruída... não há mais nada a fazer."
			}

		_:
			d.type_name = "Neutro"
			d.title = "Mercenário Errante"
			d.description = "Comportamento equilibrado sem viés psicológico marcado."

	return d
