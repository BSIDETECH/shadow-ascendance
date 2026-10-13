extends RefCounted

func run_all(runner: SceneTree) -> void:
	print("\n--- [ENNEAGRAM DATA TESTS] ---")

	var data = (load("res://scripts/personality/enneagram_data.gd") as GDScript).new()

	# Test case 1: Exact match
	data.dialogue_lines = {
		"ATTACK_STRESSED_OBEY": "Exact match for attack stressed obey."
	}
	if runner.has_method("assert_eq"):
		runner.assert_eq(data.get_dialogue_line("attack", "stressed", "obey"), "Exact match for attack stressed obey.", "EnneagramData.01: Exact match works")
	else:
		print("Skipping EnneagramData.01, assert_eq not available on runner")

	# Test case 2: Fallback to HEALTHY
	data.dialogue_lines = {
		"ATTACK_HEALTHY_OBEY": "Fallback to healthy."
	}
	if runner.has_method("assert_eq"):
		runner.assert_eq(data.get_dialogue_line("attack", "stressed", "obey"), "Fallback to healthy.", "EnneagramData.02: Fallback to HEALTHY state works")

	# Test case 3: Default fallbacks (when dictionary is empty or missing keys)
	data.dialogue_lines = {}

	if runner.has_method("assert_eq"):
		runner.assert_eq(data.get_dialogue_line("attack", "stressed", "obey"), "Ordem recebida. Executando!", "EnneagramData.03: Hardcoded fallback for OBEY")
		runner.assert_eq(data.get_dialogue_line("attack", "stressed", "hesitate"), "Espere... isso é seguro?! Vou tentar...", "EnneagramData.04: Hardcoded fallback for HESITATE")
		runner.assert_eq(data.get_dialogue_line("attack", "stressed", "refuse"), "Eu recuso essa ordem!", "EnneagramData.05: Hardcoded fallback for REFUSE")
		runner.assert_eq(data.get_dialogue_line("attack", "stressed", "unknown_outcome"), "Entendido.", "EnneagramData.06: Hardcoded fallback for _ (catch-all)")

	# Test case 4: Input case variations
	data.dialogue_lines = {
		"RETREAT_COLLAPSED_REFUSE": "I refuse to retreat!"
	}
	if runner.has_method("assert_eq"):
		runner.assert_eq(data.get_dialogue_line("rEtReaT", "CoLlApSeD", "rEfUsE"), "I refuse to retreat!", "EnneagramData.07: Handles mixed-case inputs")
