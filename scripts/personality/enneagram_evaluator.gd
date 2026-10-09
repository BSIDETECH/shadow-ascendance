class_name EnneagramEvaluator
extends RefCounted

## Psychological State Machine and Algorithmic Order Evaluator.
## Maps Leadership Orders (Attack, Retreat, Help) through Enneagram archetypes,
## dynamic stress levels, and tactical context to produce deterministic OrderResults.

enum LeadershipOrder {
	ATTACK = 1,
	RETREAT = 2,
	HELP = 3,
}

enum MentalState {
	HEALTHY = 0,
	STRESSED = 1,
	COLLAPSED = 2,
}

enum OrderStatus {
	OBEY = 0,
	HESITATE = 1,
	REFUSE = 2,
}

const COLOR_OBEY: Color = Color(0.25, 0.90, 0.35)      # Emerald Green (#40e659)
const COLOR_HESITATE: Color = Color(0.95, 0.75, 0.15)  # Amber Yellow (#f2bf26)
const COLOR_REFUSE: Color = Color(0.95, 0.25, 0.25)    # Crimson Red (#f24040)

# ==============================================================================
# 1. PSYCHOLOGICAL STATE ENGINE & STRESS CALCULATOR
# ==============================================================================

static func update_stress(
	delta: float,
	current_stress: float,
	context: TacticalContext,
	profile: EnneagramData
) -> float:
	if profile == null or context == null:
		return clampf(current_stress, 0.0, 100.0)

	var stress_gain: float = 0.0
	var recovery: float = 0.0

	# 1. Health trauma (losing HP causes stress)
	var hp_loss: float = 1.0 - context.companion_hp_ratio
	stress_gain += hp_loss * 12.0

	# 2. Swarm stress (enemies exceeding archetype threshold)
	if context.nearby_enemies_count > profile.swarm_panic_threshold:
		var excess: int = context.nearby_enemies_count - profile.swarm_panic_threshold
		stress_gain += float(excess) * 4.5

	# 3. Isolation & ally peril
	if context.player_hp_ratio < 0.30:
		if profile.enneagram_type == EnneagramData.Type.HELPER:
			stress_gain += 12.0
		elif profile.enneagram_type == EnneagramData.Type.LOYALIST:
			stress_gain += 8.0

	if context.distance_to_player > 180.0 and profile.enneagram_type == EnneagramData.Type.LOYALIST:
		stress_gain += 6.0 * profile.isolation_sensitivity

	# 4. Calm recovery when unthreatened
	if context.nearby_enemies_count == 0 and context.companion_hp_ratio > 0.60:
		recovery = profile.calm_recovery_rate

	var net_rate: float = (stress_gain * profile.stress_sensitivity) - recovery
	return clampf(current_stress + (net_rate * delta), 0.0, 100.0)

static func get_mental_state(stress_level: float) -> MentalState:
	if stress_level >= 80.0:
		return MentalState.COLLAPSED
	elif stress_level >= 50.0:
		return MentalState.STRESSED
	return MentalState.HEALTHY

static func get_mental_state_string(state: MentalState) -> String:
	match state:
		MentalState.HEALTHY:
			return "HEALTHY"
		MentalState.STRESSED:
			return "STRESSED"
		MentalState.COLLAPSED:
			return "COLLAPSED"
		_:
			return "HEALTHY"

static func get_order_string(order: int) -> String:
	match order:
		1, LeadershipOrder.ATTACK:
			return "ATTACK"
		2, LeadershipOrder.RETREAT:
			return "RETREAT"
		3, LeadershipOrder.HELP:
			return "HELP"
		_:
			return "ATTACK"

# ==============================================================================
# 2. OBEDIENCE SCORE CALCULATION
# ==============================================================================

static func calculate_obedience_score(
	order: int,
	profile: EnneagramData,
	mental_state: MentalState,
	context: TacticalContext,
	stress_level: float = 0.0
) -> float:
	if profile == null:
		return 75.0

	var ctx := context if context != null else TacticalContext.new()

	# 1. Base Score from Profile
	var base_score: float = profile.get_base_obedience(int(order)) * 100.0

	# 2. Tactical Situational Modifiers
	var tactical_mod: float = _calculate_tactical_modifier(order, profile, ctx)

	# 3. Psychological State Modifiers
	var state_mod: float = 0.0
	match mental_state:
		MentalState.HEALTHY:
			state_mod = 10.0
		MentalState.STRESSED:
			var eff_stress: float = maxf(stress_level, 50.0)
			state_mod = -15.0 - ((eff_stress - 50.0) * 0.4)
			# Amplify personality resistance under stress
			if tactical_mod < 0.0:
				tactical_mod *= 1.5
		MentalState.COLLAPSED:
			var eff_stress: float = maxf(stress_level, 80.0)
			state_mod = -35.0 - ((eff_stress - 80.0) * 0.8)
			# Strong neurosis amplification in collapse
			if tactical_mod < 0.0:
				tactical_mod *= 2.5

	var final_score: float = base_score + tactical_mod + state_mod
	return clampf(final_score, 0.0, 100.0)

static func _calculate_tactical_modifier(
	order: int,
	profile: EnneagramData,
	ctx: TacticalContext
) -> float:
	var mod: float = 0.0
	var type: EnneagramData.Type = profile.enneagram_type

	match type:
		EnneagramData.Type.REFORMER:
			# Loves orderly tactics, hates chaotic swarms
			if order == int(LeadershipOrder.ATTACK):
				if ctx.nearby_enemies_count <= 4:
					mod += 10.0
				elif ctx.nearby_enemies_count > 6:
					mod -= 20.0
			elif order == int(LeadershipOrder.RETREAT):
				if ctx.companion_hp_ratio < 0.45:
					mod += 15.0 # Tactically sound retreat

		EnneagramData.Type.HELPER:
			# Devoted guardian: Refuses to retreat if player is wounded
			if order == int(LeadershipOrder.RETREAT):
				if ctx.player_hp_ratio < 0.35:
					mod -= 55.0 # Martyr syndrome refusal!
				elif ctx.player_hp_ratio >= 0.75:
					mod += 15.0
			elif order == int(LeadershipOrder.HELP):
				mod += 35.0 # Always prioritizes helping
			elif order == int(LeadershipOrder.ATTACK):
				if ctx.player_hp_ratio < 0.40:
					mod -= 25.0 # Prefers protecting over attacking

		EnneagramData.Type.ACHIEVER:
			# Results-focused, hates retreating and looking weak
			if order == int(LeadershipOrder.ATTACK):
				mod += 20.0
				if ctx.target_is_boss:
					mod += 15.0
			elif order == int(LeadershipOrder.RETREAT):
				mod -= 35.0
				if ctx.closest_enemy_distance < 120.0:
					mod -= 20.0
			elif order == int(LeadershipOrder.HELP):
				if ctx.player_hp_ratio < 0.25:
					mod += 10.0

		EnneagramData.Type.INDIVIDUALIST:
			# Resents micromanagement / spam
			if ctx.order_frequency > 1.2:
				mod -= 30.0
			if order == int(LeadershipOrder.RETREAT):
				mod += 15.0

		EnneagramData.Type.INVESTIGATOR:
			# Analytical distance: cognitive overload from close swarms
			if order == int(LeadershipOrder.ATTACK):
				if ctx.nearby_enemies_count >= 6:
					mod -= 45.0 # Swarm freeze!
				elif ctx.closest_enemy_distance > 100.0:
					mod += 15.0 # Clear sightline
			elif order == int(LeadershipOrder.RETREAT):
				mod += 30.0 # Welcomes safe distance
			elif order == int(LeadershipOrder.HELP):
				if ctx.closest_enemy_distance < 60.0:
					mod -= 20.0 # Reluctant to enter melee

		EnneagramData.Type.LOYALIST:
			# Squad security: hates isolation, loves retreat
			if order == int(LeadershipOrder.RETREAT):
				mod += 35.0
			elif order == int(LeadershipOrder.ATTACK):
				if ctx.distance_to_player > 180.0:
					mod -= 40.0 # Isolation anxiety
			elif order == int(LeadershipOrder.HELP):
				mod += 25.0

		EnneagramData.Type.ENTHUSIAST:
			# Action seeker, hates stopping the fun
			if order == int(LeadershipOrder.ATTACK):
				mod += 25.0
			elif order == int(LeadershipOrder.RETREAT):
				if ctx.companion_hp_ratio > 0.50:
					mod -= 25.0 # Wants to keep fighting
				elif ctx.companion_hp_ratio <= 0.30:
					mod += 40.0 # Flees pain rapidly

		EnneagramData.Type.CHALLENGER:
			# Frontline dominance: NEVER turns back on enemies
			if order == int(LeadershipOrder.ATTACK):
				mod += 35.0
			elif order == int(LeadershipOrder.RETREAT):
				mod -= 50.0
				if ctx.closest_enemy_distance < 100.0:
					mod -= 30.0 # Defiant refusal right in enemy's face!
			elif order == int(LeadershipOrder.HELP):
				mod += 20.0

		EnneagramData.Type.PEACEMAKER:
			# Conflict aversion and resistance to frantic spam
			if ctx.order_frequency > 1.0:
				mod -= 35.0 # Passive resistance to spam
			if order == int(LeadershipOrder.ATTACK):
				mod -= 20.0
			elif order == int(LeadershipOrder.RETREAT):
				mod += 30.0

	return mod

# ==============================================================================
# 3. FULL ORDER EVALUATION
# ==============================================================================

static func evaluate_order(
	order: int,
	profile: EnneagramData,
	mental_state: MentalState,
	context: TacticalContext,
	stress_level: float = 0.0,
	speaker_name: String = ""
) -> OrderResult:
	var score: float = calculate_obedience_score(order, profile, mental_state, context, stress_level)

	var status: OrderStatus = OrderStatus.OBEY
	var delay_sec: float = 0.0
	var color: Color = COLOR_OBEY
	var outcome_str: String = "OBEY"

	if score >= 60.0:
		status = OrderStatus.OBEY
		outcome_str = "OBEY"
		color = COLOR_OBEY
		match mental_state:
			MentalState.HEALTHY:
				delay_sec = 0.0
			MentalState.STRESSED:
				delay_sec = 0.25
			MentalState.COLLAPSED:
				delay_sec = 0.60
	elif score >= 30.0:
		status = OrderStatus.HESITATE
		outcome_str = "HESITATE"
		color = COLOR_HESITATE
		match mental_state:
			MentalState.HEALTHY:
				delay_sec = 0.60
			MentalState.STRESSED:
				delay_sec = 1.10
			MentalState.COLLAPSED:
				delay_sec = 2.00
	else:
		status = OrderStatus.REFUSE
		outcome_str = "REFUSE"
		color = COLOR_REFUSE
		delay_sec = 0.0 # Refusal is declared immediately

	var order_str: String = get_order_string(order)
	var state_str: String = get_mental_state_string(mental_state)
	var voice_line: String = ""

	if profile != null:
		voice_line = profile.get_dialogue_line(order_str, state_str, outcome_str)
	else:
		voice_line = "Ordem processada."

	var res := OrderResult.new(
		int(status),
		delay_sec,
		voice_line,
		color,
		score,
		speaker_name,
		outcome_str
	)
	return res
