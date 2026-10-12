extends Node

## Centralized EventBus AutoLoad for global decoupled events.
## Adheres to godot-signal-architecture guidelines.

signal spell_casted()
signal damage_dealt(target: Node, damage_data: DamageData)
signal entity_died(entity: Node, death_position: Vector2)
signal enemy_died(position: Vector2, xp_val: int)
signal boss_died(boss_name: String, death_position: Vector2)
signal xp_collected(amount: int)
signal level_up_requested(new_level: int)
signal gacha_card_selected(card: Resource)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal player_health_changed(current: float, max_health: float)
signal player_shield_changed(current: float, max_shield: float)
signal player_dashed(direction: Vector2)

# Leadership & Companion Signals (M1 & M5)
signal leadership_order_issued(order_type: int, target_pos: Vector2)
signal leadership_charges_changed(current: int, max_charges: int)
signal leadership_order_failed(reason: String)
signal companion_dialogue_emitted(speaker_name: String, text: String, color: Color)
signal companion_rescued(companion: Node)
signal ally_died(ally: Node)
signal gold_changed(new_gold: int)

func emit_boss_died(boss_name: String, pos: Vector2) -> void:
	boss_died.emit(boss_name, pos)


func emit_damage_dealt(target: Node, data: DamageData) -> void:
	damage_dealt.emit(target, data)

func emit_entity_died(entity: Node, death_position: Vector2) -> void:
	entity_died.emit(entity, death_position)

func emit_enemy_died(pos: Vector2, xp: int) -> void:
	enemy_died.emit(pos, xp)

func emit_xp_collected(amount: int) -> void:
	xp_collected.emit(amount)

func emit_level_up(new_lvl: int) -> void:
	level_up_requested.emit(new_lvl)

func emit_gacha_card_selected(card: Resource) -> void:
	gacha_card_selected.emit(card)

func emit_wave_started(wave_num: int) -> void:
	wave_started.emit(wave_num)

func emit_wave_completed(wave_num: int) -> void:
	wave_completed.emit(wave_num)

func emit_player_health_changed(current: float, max_hp: float) -> void:
	player_health_changed.emit(current, max_hp)

func emit_player_dashed(dir: Vector2) -> void:
	player_dashed.emit(dir)

func emit_leadership_order_issued(order_type: int, target_pos: Vector2) -> void:
	leadership_order_issued.emit(order_type, target_pos)

func emit_leadership_charges_changed(curr: int, max_val: int) -> void:
	leadership_charges_changed.emit(curr, max_val)

func emit_leadership_order_failed(reason: String) -> void:
	leadership_order_failed.emit(reason)

func emit_companion_dialogue(speaker: String, text: String, color: Color) -> void:
	companion_dialogue_emitted.emit(speaker, text, color)

func emit_companion_rescued(companion: Node) -> void:
	companion_rescued.emit(companion)

func emit_ally_died(ally: Node) -> void:
	ally_died.emit(ally)
